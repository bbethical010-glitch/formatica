import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as dart_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'file_service.dart';
import 'package:printing/printing.dart';

class PdfToolsService {
  /// Merge multiple PDFs — fully on-device via Syncfusion
  static Future<String> mergePdfs({
    required List<String> filePaths,
    required void Function(double) onProgress,
    void Function(VoidCallback)? onCancelSetup,
  }) async {
    if (filePaths.length < 2) throw Exception('Need at least 2 PDFs to merge');
    debugPrint('PdfToolsService: Merging ${filePaths.length} PDFs');
    
    bool isCancelled = false;
    onCancelSetup?.call(() => isCancelled = true);
    
    onProgress(0.10);

    final mergedDoc = PdfDocument();

    for (int i = 0; i < filePaths.length; i++) {
      if (isCancelled) throw Exception('cancelled');
      debugPrint('PdfToolsService: Processing file ${i + 1}/${filePaths.length}');
      final bytes = await File(filePaths[i]).readAsBytes();
      final srcDoc = PdfDocument(inputBytes: bytes);

      // For each source document, create a section with matching page settings
      for (int j = 0; j < srcDoc.pages.count; j++) {
        final srcPage = srcDoc.pages[j];
        final pageSize = srcPage.getClientSize();
        final template = srcPage.createTemplate();
        
        // Create a new section with the exact page size
        final section = mergedDoc.sections!.add();
        section.pageSettings.size = Size(pageSize.width, pageSize.height);
        section.pageSettings.margins.all = 0;
        
        // Add page to this section
        final page = section.pages.add();
        page.graphics.drawPdfTemplate(template, Offset.zero);
        
        debugPrint('PdfToolsService: Merged page ${j + 1} from file ${i + 1} (${pageSize.width}x${pageSize.height})');
      }

      srcDoc.dispose();
      onProgress(0.10 + (i / filePaths.length) * 0.70);
    }

    final outDir = await FileService.getOutputDirectoryForCategory(OutputCategory.pdfs);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '$outDir/merged_$ts.pdf';
    debugPrint('PdfToolsService: Saving to $outPath');
    final outBytes = Uint8List.fromList(await mergedDoc.save());
    mergedDoc.dispose();

    await File(outPath).writeAsBytes(outBytes);
    await FileService.scanMediaFile(outPath);
    debugPrint('PdfToolsService: Merge complete');
    onProgress(1.0);
    return outPath;
  }

  /// Split PDF — extract page range — fully on-device via Syncfusion
  static Future<String> splitPdf({
    required String inputFilePath,
    required int startPage,
    required int endPage,
    required void Function(double) onProgress,
    void Function(VoidCallback)? onCancelSetup,
  }) async {
    debugPrint('PdfToolsService: Splitting PDF pages $startPage-$endPage');
    
    bool isCancelled = false;
    onCancelSetup?.call(() => isCancelled = true);
    
    onProgress(0.10);

    final bytes = await File(inputFilePath).readAsBytes();
    final srcDoc = PdfDocument(inputBytes: bytes);

    // Create new document with only selected pages
    final newDoc = PdfDocument();
    final totalPages = endPage - startPage + 1;

    // Copy only the selected pages, each in its own section with matching size
    for (int i = startPage - 1; i < endPage && i < srcDoc.pages.count; i++) {
      if (isCancelled) throw Exception('cancelled');
      final srcPage = srcDoc.pages[i];
      final pageSize = srcPage.getClientSize();
      final template = srcPage.createTemplate();
      
      // Create a new section with the exact page size
      final section = newDoc.sections!.add();
      section.pageSettings.size = Size(pageSize.width, pageSize.height);
      section.pageSettings.margins.all = 0;
      
      // Add page to this section
      final page = section.pages.add();
      page.graphics.drawPdfTemplate(template, Offset.zero);
      
      debugPrint('PdfToolsService: Extracted page ${i + 1} (${pageSize.width}x${pageSize.height})');
      onProgress(0.10 + ((i - startPage + 1) / totalPages) * 0.70);
    }

    srcDoc.dispose();

    final outDir = await FileService.getOutputDirectoryForCategory(OutputCategory.pdfs);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '$outDir/split_pages_${startPage}_to_${endPage}_$ts.pdf';
    debugPrint('PdfToolsService: Saving to $outPath');
    final outBytes = Uint8List.fromList(await newDoc.save());
    newDoc.dispose();

    await File(outPath).writeAsBytes(outBytes);
    await FileService.scanMediaFile(outPath);
    debugPrint('PdfToolsService: Split complete');
    onProgress(1.0);
    return outPath;
  }

  /// Greyscale PDF — convert all colors to black & white — on-device
  /// Uses Printing to rasterize pages to high-res images, then applies dart:image grayscale filter
  static Future<String> greyScalePdf({
    required String inputFilePath,
    required void Function(double) onProgress,
    void Function(VoidCallback)? onCancelSetup,
  }) async {
    onProgress(0.05);

    bool isCancelled = false;
    onCancelSetup?.call(() => isCancelled = true);
    final bytes = await File(inputFilePath).readAsBytes();
    final sourceDoc = PdfDocument(inputBytes: bytes);
    final totalPages = sourceDoc.pages.count;
    sourceDoc.dispose();
    onProgress(0.10);

    final outDir = await FileService.getOutputDirectoryForCategory(OutputCategory.pdfs);
    final base = p.basenameWithoutExtension(inputFilePath);
    final ts = DateTime.now().millisecondsSinceEpoch;
    final outPath = '$outDir/${base}_greyscale_$ts.pdf';

    // ROOT FIX: Use Native Kotlin Engine on Android for hardware-perfect grayscale
    if (Platform.isAndroid) {
      try {
        debugPrint('PdfToolsService: Using Native Android Greyscale Engine');
        const channel = MethodChannel('com.formatica/platform');
        
        final result = await channel.invokeMethod<String>('nativeGreyScalePdf', {
          'inputPath': inputFilePath,
          'outputPath': outPath,
        });

        if (result != null) {
          await FileService.scanMediaFile(outPath);
          onProgress(1.0);
          return outPath;
        }
      } catch (e) {
        debugPrint('PdfToolsService: Native Greyscale failed, falling back to Dart: $e');
        // Fallback to existing Dart logic if native fails
      }
    }

    // Fallback/Non-Android Logic (Dart Isolate)
    final greyDoc = pw.Document();

    // Step 2: Rasterize pages to 200 DPI for professional-grade sharpness
    int pageNum = 0;
    try {
      // 200 DPI is the standard for high-quality document scanning
      await for (final pageImage in Printing.raster(bytes, dpi: 200)) {
        if (isCancelled) {
          debugPrint('PdfToolsService: Greyscale process aborted by user');
          throw Exception('cancelled');
        }
        // Pass raw RGBA pixels directly to avoid slow PNG encoding/decoding
        final rasterData = {
          'width': pageImage.width,
          'height': pageImage.height,
          'pixels': pageImage.pixels,
        };
        
        // Offload heavy pixel manipulation and encoding to Isolate
        final jpegBytes = await compute(_fastGreyscaleAndEncode, rasterData);

        // Render onto PDF page
        final pdfImage = pw.MemoryImage(jpegBytes);

        greyDoc.addPage(
          pw.Page(
            pageFormat: dart_pdf.PdfPageFormat(
              pageImage.width.toDouble() * 72.0 / 180.0,
              pageImage.height.toDouble() * 72.0 / 180.0,
            ),
            build: (pw.Context context) {
              return pw.FullPage(
                ignoreMargins: true,
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
        pageNum++;
        final progressBase = totalPages <= 0 ? 0.85 : pageNum / totalPages;
        onProgress(0.15 + (progressBase * 0.75));
      }
    } catch (e) {
      debugPrint('Greyscale error: $e');
      throw Exception('Failed to rasterize PDF for greyscale: $e');
    }

    if (isCancelled) throw Exception('cancelled');
    onProgress(0.95);

    // Save greyscale PDF
    final outBytes = await greyDoc.save();
    if (isCancelled) throw Exception('cancelled');

    await File(outPath).writeAsBytes(outBytes);
    await FileService.scanMediaFile(outPath);
    onProgress(1.0);

    return outPath;
  }
}

/// Top-level function for isolate computation.
/// Takes raw RGBA pixels, applies fast integer grayscale, and encodes directly to JPEG.
Future<Uint8List> _fastGreyscaleAndEncode(Map<String, dynamic> data) async {
  final int width = data['width'];
  final int height = data['height'];
  final Uint8List pixels = data['pixels'];
  // 3-channel RGB image (Luminance) — universally compatible with all PDF viewers.
  // We use 3 channels to prevent the "All Red" issue caused by single-channel JPEGs.
  final image = img.Image(
    width: width,
    height: height,
    numChannels: 3,
    format: img.Format.uint8,
  );

  // Stride detection for Android memory alignment
  final int bytesPerRow = pixels.length ~/ height;
  
  // ROOT FIX: Adaptive Alpha-Channel Discovery.
  // Standard opaque PDF pages have Alpha = 255.
  // We identify which byte index (0 or 3) is Alpha so we can "shield" it.
  int alphaOffset = 3; // Default to RGBA
  if (pixels.length >= 8) {
    bool byte0Is255 = pixels[0] == 255 && pixels[4] == 255;
    bool byte3Is255 = pixels[3] == 255 && pixels[7] == 255;
    if (byte0Is255 && !byte3Is255) alphaOffset = 0; // Likely ARGB
  }

  for (int y = 0; y < height; y++) {
    final int rowOffset = y * bytesPerRow;
    for (int x = 0; x < width; x++) {
      final int pxOffset = rowOffset + (x * 4);
      if (pxOffset + 3 >= pixels.length) break;
      
      int r, g, b;
      if (alphaOffset == 0) {
        // Source is ARGB/ABGR: Byte 0 is Alpha (skip it)
        r = pixels[pxOffset + 1];
        g = pixels[pxOffset + 2];
        b = pixels[pxOffset + 3];
      } else {
        // Source is RGBA/BGRA: Byte 3 is Alpha (skip it)
        r = pixels[pxOffset];
        g = pixels[pxOffset + 1];
        b = pixels[pxOffset + 2];
      }

      // High-precision Luminance extraction
      // Use the standard CCIR 601 weights for natural grayscale perception.
      final int gray = (r * 306 + g * 601 + b * 117) >> 10;
      
      // Force R=G=B to ensure absolute zero color saturation.
      image.setPixelRgb(x, y, gray, gray, gray);
    }
  }

  // Professional Contrast & Gamma Tuning
  img.contrast(image, contrast: 1.5);
  img.gamma(image, gamma: 0.8);

  // Standard RGB JPEG encoding for maximum compatibility
  return Uint8List.fromList(img.encodeJpg(image, quality: 85));
}








