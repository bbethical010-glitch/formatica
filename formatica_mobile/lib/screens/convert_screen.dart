import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/task_provider.dart';
import '../services/convert_service.dart';
import '../services/file_service.dart';
import '../widgets/success_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';

class ConvertScreen extends StatefulWidget {
  const ConvertScreen({super.key});

  @override
  State<ConvertScreen> createState() => _ConvertScreenState();
}

class _ConvertScreenState extends State<ConvertScreen> {
  String? _filePath;
  String? _fileName;
  int? _fileSizeBytes;
  String? _selectedFormat;
  bool _isConverting = false;
  double _progress = 0.0;
  String? _errorMessage;
  String? _outputPath;
  String? _currentTaskId; // Tracks the running task for cancellation
  String _progressLabel = 'Preparing document...';

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
                      'LEXICON ENGINE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryIndigo.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _fileDropZone(context),
                    
                    if (_filePath != null) ...[
                      const SizedBox(height: 40),
                      Text(
                        'EXPORT DIMENSIONS',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formatGrid(),
                    ],
                    
                    if (_isConverting) _progressSection(),
                    if (_errorMessage != null) _buildErrorCard(),
                    if (_outputPath != null && !_isConverting) ...[
                      const SizedBox(height: 24),
                      _buildSuccessCard(),
                    ],
                    if (_filePath != null && !_isConverting) _buildOutputLocation(context),
                    
                    const SizedBox(height: 48),
                    _convertButton(),
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
          'Transcript',
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

  Widget _buildOutputLocation(BuildContext context) {
    return FutureBuilder<String>(
      future: FileService.getOutputDirectoryForCategory(_selectedOutputCategory()),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'VAULT PATH',
              style: GoogleFonts.outfit(
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 12),
            LiquidGlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              blur: 15,
              child: Row(
                children: [
                  const Icon(Icons.folder_open, size: 18, color: AppColors.primaryIndigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      FileService.getDisplayPath(snap.data!),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _privacyBadge(BuildContext context) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      blur: 10,
      color: Colors.white.withOpacity(0.03),
      child: Row(
        children: [
          const Icon(Icons.cloud_queue, size: 16, color: AppColors.primaryIndigo),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'PROFESSIONAL SERVER · SECURE ENCRYPTION',
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

  Widget _fileDropZone(BuildContext context) {
    return GestureDetector(
      onTap: _isConverting ? null : _pickFile,
      child: LiquidGlassContainer(
        height: 160,
        blur: 35,
        child: _filePath == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.05),
                      ),
                      child: const Icon(Icons.auto_stories_outlined, size: 32, color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SELECT SOURCE DOCUMENT',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        letterSpacing: 1,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'DOCX · PPTX · XLSX · PDF · MD',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        letterSpacing: 1.5,
                        color: Colors.white30,
                      ),
                    ),
                  ],
                ),
              )
            : Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.description, color: AppColors.primaryIndigo, size: 32),
                    const SizedBox(height: 16),
                    Text(
                      _fileName!,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FileService.formatFileSize(_fileSizeBytes!),
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.white30,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TAP TO SWAP',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        letterSpacing: 1,
                        color: AppColors.primaryIndigo.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _formatGrid() {
    List<String> formats = const [
      'pdf',
      'docx',
      'odt',
      'html',
      'txt',
      'rtf',
      'epub',
      'md'
    ];
    if (_filePath != null) {
      final ext = _normalizedInputExtension(_filePath!);
      final allowed = AppConstants.documentOutputFormats[ext];
      if (allowed != null) {
        formats = allowed;
      }
    }
    
    // Ensure PDF is always an option if the input isn't already a PDF
    if (_filePath != null && _normalizedInputExtension(_filePath!) != 'pdf') {
      if (!formats.contains('pdf')) {
        formats = ['pdf', ...formats];
      }
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: formats.length,
      itemBuilder: (context, index) {
        final format = formats[index];
        final isSelected = _selectedFormat == format;
        return GestureDetector(
          onTap: _isConverting
              ? null
              : () => setState(() => _selectedFormat = format),
          child: LiquidGlassContainer(
            blur: 10,
            color: isSelected ? AppColors.primaryIndigo.withOpacity(0.3) : Colors.white.withOpacity(0.05),
            specularOpacity: isSelected ? 0.4 : 0.1,
            child: Center(
              child: Text(
                format.toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: 1,
                  color: isSelected ? Colors.white : Colors.white54,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _progressSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _progressLabel.toUpperCase(),
                  style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 1.5, color: Colors.white54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryIndigo),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 4,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primaryIndigo,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryIndigo.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
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
        color: Colors.red.withOpacity(0.1),
        blur: 10,
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 13),
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
      label: 'Transcription complete.',
      onConvertAnother: _resetForm,
    );
  }

  Widget _convertButton() {
    final canConvert = _filePath != null && _selectedFormat != null && !_isConverting;

    if (_isConverting) {
      return MediaPillButton(
        label: 'HALT PROCESS',
        onTap: () {
          if (_currentTaskId != null) {
            _showCancelDialog(context, _currentTaskId!);
          }
        },
        accentColor: Colors.redAccent.withOpacity(0.3),
      );
    }

    return Opacity(
      opacity: canConvert ? 1.0 : 0.3,
      child: MediaPillButton(
        label: 'ENGAGE ANALYSIS',
        onTap: canConvert ? () => _onConvert() : () => {},
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Text('Termination', style: GoogleFonts.outfit(color: Colors.white)),
          content: Text('Abort active server-side analysis?', style: GoogleFonts.outfit(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('REMAIN', style: GoogleFonts.outfit(color: Colors.white30)),
            ),
            TextButton(
              onPressed: () {
                final provider = Provider.of<TaskProvider>(context, listen: false);
                provider.cancelTask(taskId);
                Navigator.pop(ctx);
                _resetForm(); // Locally reset when cancelling
              },
              child: Text('ABORT', style: GoogleFonts.outfit(color: Colors.redAccent)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: AppConstants.documentInputFormats,
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final extension = _normalizedInputExtension(path);
      if (!AppConstants.documentOutputFormats.containsKey(extension)) {
        setState(() {
          _errorMessage =
              'This document format is not supported yet.';
        });
        return;
      }

      setState(() {
        _filePath = path;
        _fileName = result.files.single.name;
        _fileSizeBytes = result.files.single.size;
        _selectedFormat = null;
        _errorMessage = null;
        _outputPath = null;
      });
    }
  }

  Future<void> _onConvert() async {
    setState(() {
      _isConverting = true;
      _errorMessage = null;
      _progress = 0.02;
      _progressLabel = 'Connecting to server...';
    });

    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask(
        '$_fileName → ${_selectedFormat!.toUpperCase()}', 'convert');
    _currentTaskId = taskId;

    try {
      final outputPath = await ConvertService.convertDocument(
        inputFilePath: _filePath!,
        outputFormat: _selectedFormat!,
        context: context,
        onCancelSetup: (hook) {
          provider.setCancelHook(taskId, hook);
        },
        onProgress: (progress) {
          if (!mounted) {
            return;
          }
          // Update progress label based on progress percentage
          String stage;
          if (progress < 0.1) {
            stage = 'Connecting to server...';
          } else if (progress < 0.2) {
            stage = 'Preparing upload...';
          } else if (progress < 0.9) {
            stage = 'Converting on server...';
          } else if (progress < 0.97) {
            stage = 'Downloading results...';
          } else {
            stage = 'Finalizing...';
          }
          setState(() {
            _progress = progress;
            _progressLabel = stage;
          });
          provider.updateProgress(taskId, progress);
        },
      );

      provider.completeTask(taskId, outputPath);
      if (mounted) {
        setState(() {
          _outputPath = outputPath;
          _isConverting = false;
          _progressLabel = 'Done';
        });
      }
    } catch (error) {
      if (error.toString().contains('cancelled')) return; // handled by _resetForm
      provider.failTask(taskId, error.toString());
      if (mounted) {
        setState(() {
          _errorMessage = error.toString().replaceFirst('Exception: ', '');
          _isConverting = false;
          _progressLabel = 'Analysis failed';
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _filePath = null;
      _fileName = null;
      _fileSizeBytes = null;
      _selectedFormat = null;
      _outputPath = null;
      _errorMessage = null;
      _progress = 0.0;
      _progressLabel = 'Preparing document...';
    });
  }

  String _normalizedInputExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'htm') {
      return 'html';
    }
    return ext;
  }

  OutputCategory _selectedOutputCategory() {
    return _selectedFormat == 'pdf'
        ? OutputCategory.pdfs
        : OutputCategory.documents;
  }
}








