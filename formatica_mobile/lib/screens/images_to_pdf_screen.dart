import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/success_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';

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
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildHeader(context),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _privacyBadge(context),
                    const SizedBox(height: 32),
                    
                    Text(
                      'PRISM CAPTURE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryIndigo.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _imageGrid(context),
                    
                    if (_isLoading) _progressSection(),
                    if (_errorMessage != null) _buildErrorCard(),
                    if (_outputPath != null && !_isLoading) ...[
                      const SizedBox(height: 24),
                      _buildSuccessCard(),
                    ],
                    
                    const SizedBox(height: 48),
                    _createButton(),
                    const SizedBox(height: 100), // Navigation Buffer
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 64, bottom: 16),
        title: Text(
          'Capture',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w300,
            fontSize: 28,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        background: Stack(
          children: [
            Positioned(
              left: 64,
              bottom: 45,
              child: Container(
                width: 40,
                height: 1,
                color: AppColors.primaryIndigo.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyBadge(BuildContext context) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      blur: 10,
      color: Colors.white.withOpacity(0.03),
      child: Row(
        children: [
          const Icon(Icons.security_outlined, size: 16, color: AppColors.imageCyan),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'LOCAL FUSION · NO DATA TRANSMISSION',
              style: GoogleFonts.outfit(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageGrid(BuildContext context) {
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
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_photo_alternate_outlined, color: Colors.white30, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'ADD',
                    style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 1, color: Colors.white30),
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
            style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 1.5, color: Colors.white54),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            backgroundColor: Colors.white.withOpacity(0.05),
            color: AppColors.primaryIndigo,
            minHeight: 2,
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
                style: GoogleFonts.outfit(color: AppColors.audioRose, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return SuccessCard(
      outputPath: _outputPath!,
      label: 'Capture complete.',
      onConvertAnother: _resetForm,
    );
  }

  Widget _createButton() {
    final canCreate = _selectedImagePaths.isNotEmpty && !_isLoading;
    return Opacity(
      opacity: canCreate ? 1.0 : 0.3,
      child: MediaPillButton(
        label: _isLoading ? 'PROCESSING...' : 'INITIATE CAPTURE',
        onTap: canCreate ? () => _onCreatePdf() : () => {},
        accentColor: AppColors.primaryIndigo,
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
    final taskId = provider.addTask('${_selectedImagePaths.length} images → PDF', 'imagesToPdf');
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
      provider.completeTask(taskId, outPath);

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








