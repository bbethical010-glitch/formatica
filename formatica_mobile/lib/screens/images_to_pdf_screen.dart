import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'dart:ui';
import '../core/theme.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/success_card.dart';

class ImagesToPdfScreen extends StatefulWidget {
  const ImagesToPdfScreen({super.key});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  final List<String> _selectedImagePaths = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 12, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text('On-Device', style: AppTextStyles.badge.copyWith(color: Colors.greenAccent, fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capture', style: AppTextStyles.displayLarge.copyWith(fontSize: 32)),
                    Text(
                      'IMAGE TO PDF ENGINE',
                      style: AppTextStyles.studioLabel.copyWith(color: AppColors.docIndigo),
                    ),
                    const SizedBox(height: 32),

                    // Preview Zone
                    GestureDetector(
                      onTap: _isLoading ? null : _addImages,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: LiquidGlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: 24,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/doc_hero.png',
                                fit: BoxFit.cover,
                              ),
                              Container(color: Colors.black.withOpacity(0.4)),
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: Colors.white54),
                                    SizedBox(height: 12),
                                    Text('ADD IMAGES TO FUSE', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    _buildSectionTitle('SELECTED ASSETS'),
                    const SizedBox(height: 16),
                    _buildImageGrid(),
                    
                    if (_errorMessage != null)
                      _buildErrorCard(),
                    
                    if (_outputPath != null && !_isLoading)
                      SuccessCard(
                        outputPath: _outputPath!,
                        label: 'Fusion complete.',
                        onConvertAnother: _resetForm,
                      ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Sticky Bar
            _buildStickyBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.badge.copyWith(
        color: Colors.white.withOpacity(0.4),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildImageGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _selectedImagePaths.asMap().entries.map((entry) {
        final index = entry.key;
        final path = entry.value;
        return Stack(
          children: [
            LiquidGlassContainer(
              width: 80,
              height: 80,
              padding: EdgeInsets.zero,
              borderRadius: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => setState(() => _selectedImagePaths.removeAt(index)),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStickyBar() {
    final canCreate = _selectedImagePaths.isNotEmpty && !_isLoading;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: LiquidGlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(12),
        color: AppColors.darkSurfaceHigh,
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('FUSING PAGES...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('RUNNING', style: TextStyle(fontSize: 10, color: AppColors.docIndigo)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: AppColors.docIndigo,
                    minHeight: 4,
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: canCreate ? _onCreatePdf : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.docIndigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('GENERATE PDF', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      color: AppColors.audioRose.withOpacity(0.1),
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.audioRose, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.audioRose, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _addImages() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (result != null) {
      setState(() {
        for (var path in result.paths) {
          if (path != null && !_selectedImagePaths.contains(path)) {
            _selectedImagePaths.add(path);
          }
        }
        _errorMessage = null;
        _outputPath = null;
      });
    }
  }

  Future<void> _onCreatePdf() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask('${_selectedImagePaths.length} images → PDF', 'imagesToPdf');

    try {
      final List<Uint8List> imageBytesList = [];
      for (final path in _selectedImagePaths) {
        imageBytesList.add(await File(path).readAsBytes());
      }
      final pdfBytes = await compute(_buildPdf, imageBytesList);
      final filename = "formatica_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final outPath = await FileService.saveToCategory(pdfBytes, filename, OutputCategory.pdfs);
      provider.completeTask(taskId, outPath);
      if (mounted) setState(() { _outputPath = outPath; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  void _resetForm() {
    setState(() {
      _selectedImagePaths.clear();
      _outputPath = null;
      _errorMessage = null;
      _isLoading = false;
    });
  }
}

Future<Uint8List> _buildPdf(List<Uint8List> imageBytesList) async {
  final doc = pw.Document();
  for (final bytes in imageBytesList) {
    final image = pw.MemoryImage(bytes);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
    ));
  }
  return await doc.save();
}
