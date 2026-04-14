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
import '../widgets/media_pill_button.dart';
import '../widgets/top_bar.dart';
import '../widgets/labels.dart';

class ImagesToPdfScreen extends StatefulWidget {
  const ImagesToPdfScreen({super.key});

  @override
  State<ImagesToPdfScreen> createState() => _ImagesToPdfScreenState();
}

class _ImagesToPdfScreenState extends State<ImagesToPdfScreen> {
  final List<String> _selectedImagePaths = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentTaskId;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudioTopBar(
          title: 'Capture',
          onBack: () => Navigator.pop(context),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const OnDeviceBadge(),
                const SizedBox(height: 32),
                
                Text(
                  'PRISM CAPTURE',
                  style: AppTextStyles.studioLabel.copyWith(
                    color: AppColors.docIndigo.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                
                _imageGrid(context, isDark),
                
                if (_isLoading) _progressSection(),
                if (_errorMessage != null) _buildErrorCard(),
                if (_outputPath != null && !_isLoading) ...[
                  const SizedBox(height: 24),
                  _buildSuccessModule(),
                ],
                
                const SizedBox(height: 48),
                _createButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageGrid(BuildContext context, bool isDark) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ..._selectedImagePaths.asMap().entries.map((entry) {
          final index = entry.key;
          final imgPath = entry.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              LiquidGlassContainer(
                width: 100,
                height: 100,
                padding: EdgeInsets.zero,
                blur: 15,
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.file(File(imgPath), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () => setState(() => _selectedImagePaths.removeAt(index)),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white10),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white70),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: AppTextStyles.studioLabel.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        GestureDetector(
          onTap: _isLoading ? null : _addImages,
          child: LiquidGlassContainer(
            width: 100,
            height: 100,
            blur: 25,
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: isDark ? Colors.white38 : Colors.black26,
                    size: 24,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ADD',
                    style: AppTextStyles.studioLabel.copyWith(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYNCHRONIZING PRISMS...',
            style: AppTextStyles.studioLabel.copyWith(
              fontSize: 10,
              color: AppColors.docIndigo.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2),
            ),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: AppColors.docIndigo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(16),
        color: AppColors.audioRose.withOpacity(0.1),
        blur: 10,
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.audioRose, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.audioRose,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessModule() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(24),
      color: AppColors.docIndigo.withOpacity(0.05),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.imageCyan, size: 44),
          const SizedBox(height: 16),
          Text(
            'CAPTURE COMPLETE',
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'The document has been securely stored in your vault.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: AppColors.onSurfaceVar),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: MediaPillButton(
                  label: 'OPEN FILE',
                  onTap: () => FileService.openFile(_outputPath!),
                  accentColor: AppColors.imageCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MediaPillButton(
                  label: 'ANOTHER',
                  onTap: _resetForm,
                  accentColor: AppColors.docIndigo.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _createButton() {
    final canCreate = _selectedImagePaths.isNotEmpty && !_isLoading;
    return Opacity(
      opacity: canCreate ? 1.0 : 0.3,
      child: MediaPillButton(
        label: _isLoading ? 'PROCESSING...' : 'INITIATE CAPTURE',
        onTap: canCreate ? () => _onCreatePdf() : () => {},
        accentColor: AppColors.docIndigo,
      ),
    );
  }

  Future<void> _addImages() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: true);
    if (result != null) {
      setState(() {
        for (var imgPath in result.paths) {
          if (imgPath != null && !_selectedImagePaths.contains(imgPath)) {
            _selectedImagePaths.add(imgPath);
          }
        }
        _errorMessage = null;
        _outputPath = null;
      });
    }
  }

  Future<void> _onCreatePdf() async {
    if (_selectedImagePaths.isEmpty) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _outputPath = null;
    });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask(
      'Formatica Capture',
      'imagesToPdf',
      subtext: 'Encapsulating ${_selectedImagePaths.length} visual prisms',
    );
    _currentTaskId = taskId;
    provider.updateProgress(taskId, 0.1);

    try {
      final List<Uint8List> imageBytesList = [];
      for (final imgPath in _selectedImagePaths) {
        final bytes = await File(imgPath).readAsBytes();
        imageBytesList.add(bytes);
      }
      provider.updateProgress(taskId, 0.3);

      final pdfBytes = await compute(_buildPdf, imageBytesList);
      provider.updateProgress(taskId, 0.9);

      final filename = "formatica_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final outPath = await FileService.saveToCategory(
        pdfBytes, filename, OutputCategory.pdfs);
      await provider.completeTask(taskId, outPath);

      if (mounted) {
        setState(() {
          _outputPath = outPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      provider.failTask(taskId, e.toString());
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
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
  void _showCancelDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          title: Text(
            'TERMINATION',
            style: AppTextStyles.studioLabel.copyWith(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          content: Text(
            'ABORT ACTIVE CAPTURE SEQUENCE?',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white60,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'REMAIN',
                style: AppTextStyles.studioLabel.copyWith(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final provider = Provider.of<TaskProvider>(context, listen: false);
                provider.cancelTask(taskId);
                Navigator.pop(ctx);
                _resetForm();
              },
              child: Text(
                'ABORT',
                style: AppTextStyles.studioLabel.copyWith(
                  color: AppColors.audioRose,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<Uint8List> _buildPdf(List<Uint8List> imageBytesList) async {
  final doc = pw.Document();
  for (final bytes in imageBytesList) {
    final image = pw.MemoryImage(bytes);
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Center(
        child: pw.Image(image, fit: pw.BoxFit.contain),
      ),
    ));
  }
  return await doc.save();
}







