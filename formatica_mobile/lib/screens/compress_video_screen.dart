import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/video_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';
import '../widgets/top_bar.dart';
import '../widgets/labels.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudioTopBar(
          title: 'Compress',
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
                  'COMPRESSION: QUANTUM',
                  style: AppTextStyles.studioLabel.copyWith(
                    color: AppColors.videoPurple.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),

                _fileDropZone(context, isDark),

                if (_filePath != null && !_isConverting) ...[
                  const SizedBox(height: 32),
                  Text(
                    'BITRATE INTENSITY (CRF)',
                    style: AppTextStyles.studioLabel.copyWith(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _crfSlider(isDark),
                  
                  const SizedBox(height: 32),
                  Text(
                    'EFFICIENCY PRESET',
                    style: AppTextStyles.studioLabel.copyWith(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _presetSelector(isDark),
                  
                  const SizedBox(height: 32),
                  Text(
                    'RESOLUTION SCALING',
                    style: AppTextStyles.studioLabel.copyWith(
                      fontSize: 10,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _resolutionGrid(isDark),
                ],

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
        height: 140,
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
                        Icons.compress_rounded, 
                        size: 24, 
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'IMPORT SOURCE MEDIA',
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
                child: Row(
                  children: [
                    const Icon(Icons.layers_rounded, color: AppColors.videoPurple, size: 32),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _fileName!,
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
                        ],
                      ),
                    ),
                    Icon(
                      Icons.refresh_rounded, 
                      color: isDark ? Colors.white24 : Colors.black26, 
                      size: 18,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _crfSlider(bool isDark) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.01),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'MAX QUALITY', 
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 9, 
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              Text(
                'CRF ${_crf.toInt()}', 
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.videoPurple, 
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'MAX SMALL', 
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 9, 
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.videoPurple,
              inactiveTrackColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              thumbColor: Colors.white,
              overlayColor: AppColors.videoPurple.withOpacity(0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
            _crf < 23 ? 'REDUNDANCY ELIMINATED' : (_crf > 32 ? 'AGGRESSIVE SHRINK' : 'BALANCED PRECISION'),
            style: AppTextStyles.studioLabel.copyWith(
              color: AppColors.videoPurple.withOpacity(0.6), 
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetSelector(bool isDark) {
    final presets = ['fast', 'medium', 'slow'];
    return Row(
      children: presets.map((p) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: GestureDetector(
            onTap: _isConverting ? null : () => setState(() => _preset = p),
            child: LiquidGlassContainer(
              padding: const EdgeInsets.symmetric(vertical: 12),
              blur: _preset == p ? 20 : 5,
              color: _preset == p 
                ? AppColors.videoPurple.withOpacity(0.15) 
                : isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
              borderColor: _preset == p 
                ? AppColors.videoPurple.withOpacity(0.4) 
                : Colors.white.withOpacity(0.05),
              child: Center(
                child: Text(
                  p.toUpperCase(),
                  style: AppTextStyles.studioLabel.copyWith(
                    fontSize: 11,
                    fontWeight: _preset == p ? FontWeight.bold : FontWeight.w500,
                    color: _preset == p 
                      ? (isDark ? Colors.white : AppColors.videoPurple) 
                      : (isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ),
            ),
          ),
        ),
      )).toList(),
    );
  }

  Widget _resolutionGrid(bool isDark) {
    final resolutions = ['Original', '1080p', '720p', '480p'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3.8,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        final res = resolutions[index];
        final isSelected = _resolution == res;
        return GestureDetector(
          onTap: _isConverting ? null : () => setState(() => _resolution = res),
          child: LiquidGlassContainer(
            blur: isSelected ? 20 : 5,
            padding: EdgeInsets.zero,
            color: isSelected 
              ? AppColors.videoPurple.withOpacity(0.15) 
              : isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
            borderColor: isSelected 
              ? AppColors.videoPurple.withOpacity(0.4) 
              : Colors.white.withOpacity(0.05),
            child: Center(
              child: Text(
                res.toUpperCase(),
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected 
                    ? (isDark ? Colors.white : AppColors.videoPurple) 
                    : (isDark ? Colors.white38 : Colors.black38),
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
              Text(
                'CRUSHING VOIDS...',
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 10,
                  color: AppColors.videoPurple.withOpacity(0.6),
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.videoPurple,
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
                  color: AppColors.videoPurple,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.videoPurple.withOpacity(0.3),
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
      color: AppColors.videoPurple.withOpacity(0.05),
      child: Column(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.imageCyan, size: 44),
          const SizedBox(height: 16),
          Text(
            'SHRINK COMPLETE',
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'The media file has been successfully optimized without perceptable quality loss.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: AppColors.onSurfaceVar),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: MediaPillButton(
                  label: 'PREVIEW',
                  onTap: () => FileService.openFile(_outputPath!),
                  accentColor: AppColors.imageCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MediaPillButton(
                  label: 'ANOTHER',
                  onTap: _resetForm,
                  accentColor: AppColors.videoPurple.withOpacity(0.5),
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
        label: 'STOP PROCESSING',
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
        label: 'EXECUTE COMPRESSION',
        onTap: canConvert ? () => _onConvert() : () => {},
        accentColor: AppColors.videoPurple,
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
    final taskId = provider.addTask(
      _fileName!,
      'compressVideo',
      subtext: 'Optimal: ${_preset.toUpperCase()} @ ${_resolution}',
    );
    _currentTaskId = taskId;
    
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
      await provider.completeTask(taskId, outputPath);
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
      _errorMessage = null;
      _progress = 0.0;
    });
  }

  Widget _buildOutputLocation(BuildContext context, bool isDark) {
    return FutureBuilder<String>(
      future: FileService.getOutputDirectoryForCategory(OutputCategory.video),
      builder: (ctx, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            Text(
              'OUTPUT VAULT',
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
                  const Icon(Icons.folder_open, size: 18, color: AppColors.videoPurple),
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
            side: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          title: Text(
            'TERMINATION',
            style: AppTextStyles.studioLabel.copyWith(
              color: Colors.white,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'ABORT THE ACTIVE HIGH-EFFICIENCY COMPRESSION PROCESS?',
            style: AppTextStyles.studioLabel.copyWith(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'RESUME', 
                style: AppTextStyles.studioLabel.copyWith(color: Colors.white38),
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
                style: AppTextStyles.studioLabel.copyWith(color: AppColors.audioRose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

