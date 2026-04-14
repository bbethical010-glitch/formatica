import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/pdf_tools_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';
import '../widgets/top_bar.dart';
import '../widgets/labels.dart';

class GreyscalePdfScreen extends StatefulWidget {
  const GreyscalePdfScreen({super.key});

  @override
  State<GreyscalePdfScreen> createState() => _GreyscalePdfScreenState();
}

class _GreyscalePdfScreenState extends State<GreyscalePdfScreen> {
  String? _filePath;
  String? _fileName;
  int? _fileSizeBytes;

  bool _isConverting = false;
  double _progress = 0.0;
  String? _currentTaskId;
  String? _errorMessage;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudioTopBar(
          title: 'Greyscale',
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
                  'ENGINE: MONOCHROME',
                  style: AppTextStyles.studioLabel.copyWith(
                    color: AppColors.docIndigo.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                
                _fileDropZone(context, isDark),
                
                if (_isConverting) _progressSection(),
                if (_errorMessage != null) _buildErrorCard(),
                if (_outputPath != null && !_isConverting) ...[
                  const SizedBox(height: 24),
                  _buildSuccessModule(),
                ],
                if (_filePath != null && !_isConverting) _buildOutputLocation(context, isDark),
                
                const SizedBox(height: 48),
                _actionButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fileDropZone(BuildContext context, bool isDark) {
    return GestureDetector(
      onTap: _isConverting ? null : _pickFile,
      child: LiquidGlassContainer(
        height: 160,
        blur: 35,
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        child: _filePath == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined, 
                        size: 24, 
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'IMPORT SOURCE DOCUMENT',
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black54,
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
                    const Icon(Icons.picture_as_pdf_outlined, color: AppColors.docIndigo, size: 32),
                    const SizedBox(height: 16),
                    Text(
                      _fileName!,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FileService.formatFileSize(_fileSizeBytes!),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'TAP TO CHANGE',
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 9, 
                        color: AppColors.docIndigo,
                      ),
                    ),
                  ],
                ),
              ),
      ),
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
              Text(
                'ISOLATING LUMA...',
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 10,
                  color: AppColors.docIndigo.withOpacity(0.6),
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.docIndigo,
                ),
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
                  color: AppColors.docIndigo,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.docIndigo.withOpacity(0.3),
                      blurRadius: 10,
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
        color: AppColors.audioRose.withOpacity(0.1),
        blur: 10,
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.audioRose, size: 20),
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
            'TRANSFORMATION COMPLETE',
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'The document has been successfully converted to monochrome.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: AppColors.onSurfaceVar),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: MediaPillButton(
                  label: 'OPEN DOCUMENT',
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

  Widget _actionButton() {
    final canConvert = _filePath != null && !_isConverting;
    if (_isConverting) {
      return MediaPillButton(
        label: 'HALT SEQUENCE',
        onTap: () {
          if (_currentTaskId != null) {
            _showCancelDialog(context, _currentTaskId!);
          }
        },
        accentColor: AppColors.audioRose.withOpacity(0.3),
      );
    }

    return Opacity(
      opacity: canConvert ? 1.0 : 0.3,
      child: MediaPillButton(
        label: 'INITIATE EXTRACTION',
        onTap: canConvert ? () => _onConvert() : () => {},
        accentColor: AppColors.docIndigo,
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        _fileSizeBytes = result.files.single.size;
        _errorMessage = null;
        _outputPath = null;
      });
    }
  }

  Future<void> _onConvert() async {
    setState(() {
      _isConverting = true;
      _errorMessage = null;
    });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask(
      _fileName!,
      'convert',
      subtext: 'Isolating luma for monochrome output',
    );
    _currentTaskId = taskId;
    
    try {
      final outputPath = await PdfToolsService.greyScalePdf(
        inputFilePath: _filePath!,
        onCancelSetup: (hook) => provider.setCancelHook(taskId, () async => hook()),
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
            provider.updateProgress(taskId, p);
          }
        },
      );
      await provider.completeTask(taskId, outputPath);
      if (mounted) {
        setState(() {
          _outputPath = outputPath;
          _isConverting = false;
        });
      }
    } catch (e) {
      if (e.toString().contains('cancelled')) return;
      provider.failTask(taskId, e.toString());
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isConverting = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _filePath = null;
      _fileName = null;
      _outputPath = null;
      _errorMessage = null;
      _progress = 0.0;
    });
  }

  Widget _buildOutputLocation(BuildContext context, bool isDark) {
    return FutureBuilder<String>(
      future: FileService.getOutputDirectoryForCategory(OutputCategory.pdfs),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'VAULT PATH',
              style: AppTextStyles.studioLabel.copyWith(
                fontSize: 10,
                color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 12),
            LiquidGlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              blur: 15,
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.01),
              child: Row(
                children: [
                  const Icon(Icons.folder_open, size: 18, color: AppColors.docIndigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      FileService.getDisplayPath(snap.data!),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black87,
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
            'ABORT THE HARDWARE-LEVEL MONOCHROME EXTRACTION?',
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

