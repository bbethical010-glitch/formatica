import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/video_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/success_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';

class CompressVideoScreen extends StatefulWidget {
  const CompressVideoScreen({super.key});

  @override
  State<CompressVideoScreen> createState() => _CompressVideoScreenState();
}

class _CompressVideoScreenState extends State<CompressVideoScreen> {
  String? _filePath;
  String? _fileName;
  int? _fileSizeBytes;
  
  double _crf = 28;
  String _preset = 'medium';
  String _resolution = 'Original';
  
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
          title: Text('COMPRESSION LAB', style: AppTextStyles.studioLabel.copyWith(color: Colors.white)),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editorial Title
                Text('Shrink', style: AppTextStyles.studioLabel),
                const SizedBox(height: 8),
                Text(
                  'Media Voids',
                  style: AppTextStyles.displayLarge.copyWith(
                    color: AppColors.darkTextPrimary,
                    fontSize: 42,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'High-efficiency bitrate reduction.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextSecondary),
                ),

                const SizedBox(height: 32),

                // File Selection Zone
                GestureDetector(
                  onTap: _isConverting ? null : _pickFile,
                  child: LiquidGlassContainer(
                    height: 160,
                    width: double.infinity,
                    color: _filePath == null ? Colors.white.withOpacity(0.03) : AppColors.videoPurple.withOpacity(0.1),
                    child: Center(
                      child: _filePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.compress_rounded, size: 40, color: AppColors.darkTextSecondary.withOpacity(0.5)),
                                const SizedBox(height: 12),
                                Text('TAP TO IMPORT MEDIA', style: AppTextStyles.studioLabel.copyWith(color: AppColors.darkTextSecondary)),
                              ],
                            )
                          : Padding(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  const Icon(Icons.layers_rounded, color: AppColors.videoPurple, size: 32),
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

                if (_filePath != null && !_isConverting) ...[
                  const SizedBox(height: 32),
                  Text('BITRATE INTENSITY (CRF)', style: AppTextStyles.studioLabel),
                  const SizedBox(height: 16),
                  _crfSlider(),
                  
                  const SizedBox(height: 32),
                  Text('EFFICIENCY PRESET', style: AppTextStyles.studioLabel),
                  const SizedBox(height: 16),
                  _presetSelector(),
                  
                  const SizedBox(height: 32),
                  Text('RESOLUTION SCALING', style: AppTextStyles.studioLabel),
                  const SizedBox(height: 16),
                  _resolutionGrid(),
                ],

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
                        label: 'Execute Compression',
                        accentColor: AppColors.videoPurple,
                        onTap: _filePath != null ? () => _onConvert() : () => {},
                        icon: Icons.auto_awesome_motion_rounded,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _crfSlider() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('QUALITY', style: AppTextStyles.studioLabel.copyWith(fontSize: 10, color: AppColors.darkTextSecondary)),
              Text('${_crf.toInt()}', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.videoPurple, fontSize: 18)),
              Text('SIZE', style: AppTextStyles.studioLabel.copyWith(fontSize: 10, color: AppColors.darkTextSecondary)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.videoPurple,
              inactiveTrackColor: Colors.white.withOpacity(0.05),
              thumbColor: Colors.white,
              overlayColor: AppColors.videoPurple.withOpacity(0.2),
              trackHeight: 2,
            ),
            child: Slider(
              value: _crf,
              min: 18,
              max: 51,
              divisions: 33,
              onChanged: _isConverting ? null : (val) => setState(() => _crf = val),
            ),
          ),
          Text(
            _crf < 23 ? 'Visually Lossless' : (_crf > 32 ? 'Hyper Compressed' : 'Balanced Engine'),
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _presetSelector() {
    final presets = ['fast', 'medium', 'slow'];
    return Row(
      children: presets.map((p) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: GestureDetector(
            onTap: _isConverting ? null : () => setState(() => _preset = p),
            child: LiquidGlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 12),
              blur: _preset == p ? 15 : 5,
              color: _preset == p ? AppColors.videoPurple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              borderColor: _preset == p ? AppColors.videoPurple.withOpacity(0.5) : Colors.white.withOpacity(0.1),
              child: Center(
                child: Text(
                  p.toUpperCase(),
                  style: AppTextStyles.studioLabel.copyWith(
                    color: _preset == p ? Colors.white : AppColors.darkTextSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _resolutionGrid() {
    final resolutions = ['Original', '1080p', '720p', '480p'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final res = resolutions[index];
        final isSelected = _resolution == res;
        return GestureDetector(
          onTap: _isConverting ? null : () => setState(() => _resolution = res),
          child: LiquidGlassContainer(
            blur: isSelected ? 15 : 5,
            color: isSelected ? AppColors.videoPurple.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderColor: isSelected ? AppColors.videoPurple.withOpacity(0.5) : Colors.white.withOpacity(0.1),
            child: Center(
              child: Text(
                res.toUpperCase(),
                style: AppTextStyles.studioLabel.copyWith(
                  color: isSelected ? Colors.white : AppColors.darkTextSecondary,
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
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('COMPRESSING STREAMS...', style: AppTextStyles.studioLabel),
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
                    colors: [AppColors.videoPurple, AppColors.audioRose],
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
        label: 'Video compressed successfully',
        onConvertAnother: _resetForm,
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp4', 'mkv', 'avi', 'mov', 'webm'],
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
    setState(() { _isConverting = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask('Compress $_fileName', 'compressVideo');
    _currentTaskId = taskId;
    setState(() { _progress = 0.02; });

    String apiRes;
    switch (_resolution) {
      case '1080p': apiRes = '1920:-2'; break;
      case '720p': apiRes = '1280:-2'; break;
      case '480p': apiRes = '854:-2'; break;
      default: apiRes = 'original';
    }

    try {
      final outputPath = await VideoService.compressVideo(
        inputFilePath: _filePath!,
        crf: _crf.toInt(),
        preset: _preset,
        resolution: apiRes,
        onCancelSetup: (hook) => provider.setCancelHook(taskId, hook),
        onProgress: (p) {
          if (mounted) {
            setState(() => _progress = p);
            provider.updateProgress(taskId, p);
          }
        },
      );
      provider.completeTask(taskId, outputPath);
      if (mounted) {
        setState(() { _outputPath = outputPath; _isConverting = false; });
      }
    } catch (e) {
      if (e.toString().contains('cancelled')) return;
      provider.failTask(taskId, e.toString());
      if (mounted) {
        setState(() { _errorMessage = e.toString(); _isConverting = false; });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _filePath = null;
      _fileName = null;
      _outputPath = null;
      _crf = 28;
      _preset = 'medium';
      _resolution = 'Original';
    });
  }

  void _showCancelDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('CANCEL OPERATION', style: AppTextStyles.studioLabel),
        content: Text('Abort the high-efficiency compression?', style: AppTextStyles.bodyMedium),
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








