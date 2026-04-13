import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/pdf_tools_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/success_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';

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
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('GREYSCALE PDF', style: AppTextStyles.studioLabel.copyWith(color: Colors.white)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editorial Title
                Text('Optimize', style: AppTextStyles.studioLabel),
                const SizedBox(height: 8),
                Text(
                  'Monochrome',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontSize: 42,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hardware-level B&W extraction.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
                ),
                
                const SizedBox(height: 32),
                
                // File Selection Zone
                GestureDetector(
                  onTap: _isConverting ? null : _pickFile,
                  child: LiquidGlassContainer(
                    height: 160,
                    width: double.infinity,
                    color: _filePath == null ? Colors.white.withOpacity(0.03) : AppColors.primaryIndigo.withOpacity(0.1),
                    child: Center(
                      child: _filePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.darkTextSecondary.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text('DRAG OR TAP TO IMPORT', style: AppTextStyles.studioLabel.copyWith(color: AppColors.darkTextSecondary)),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  const Icon(Icons.picture_as_pdf_rounded, color: AppColors.audioRose, size: 32),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_fileName!, style: AppTextStyles.headlineSmall.copyWith(fontSize: 16), overflow: TextOverflow.ellipsis),
                                        Text(FileService.formatFileSize(_fileSizeBytes!), style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextSecondary)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.refresh_rounded, color: AppColors.darkTextSecondary.withOpacity(0.5), size: 20),
                                ],
                              ),
                            ),
                    ),
                  ),
                ),

                if (_isConverting) _progressSection(),
                if (_errorMessage != null) _buildErrorCard(),
                if (_outputPath != null && !_isConverting) _buildSuccessCard(),
                
                const SizedBox(height: 48),
                
                // Action Area
                Center(
                  child: _isConverting
                    ? MediaPillButton(
                        label: 'Cancel Operation',
                        accentColor: AppColors.audioRose,
                        onTap: () {
                          if (_currentTaskId != null) {
                            _showCancelDialog(context, _currentTaskId!);
                          }
                        },
                      )
                    : MediaPillButton(
                        label: 'Execute Conversion',
                        accentColor: AppColors.primaryIndigo,
                        onTap: _filePath != null ? () => _onConvert() : () => {},
                        icon: Icons.auto_fix_high_rounded,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EXTRACTING LUMA...', style: AppTextStyles.studioLabel),
              Text('${(_progress * 100).toInt()}%', style: AppTextStyles.studioLabel),
            ],
          ),
          const SizedBox(height: 12),
          LiquidGlassContainer(
            height: 12,
            borderRadius: 6,
            blur: 0,
            color: Colors.white.withOpacity(0.05),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryIndigo, AppColors.videoPurple],
                  ),
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
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.audioRose, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_errorMessage!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.audioRose)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SuccessCard(
        outputPath: _outputPath!,
        label: 'Converted to greyscale successfully',
        onConvertAnother: _resetForm,
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
    final taskId = provider.addTask('Greyscale $_fileName', 'convert');
    _currentTaskId = taskId;
    
    setState(() => _progress = 0.02);

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
      provider.completeTask(taskId, outputPath);
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
    });
  }

  void _showCancelDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('CANCEL OPERATION', style: AppTextStyles.studioLabel),
        content: Text('Abort the hardware-level monochrome extraction?', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('KEEP GOING')),
          TextButton(
            onPressed: () {
              final provider = Provider.of<TaskProvider>(context, listen: false);
              provider.cancelTask(taskId);
              Navigator.pop(ctx);
              _resetForm();
            },
            child: const Text('ABORT', style: TextStyle(color: AppColors.audioRose)),
          ),
        ],
      ),
    );
  }
}








