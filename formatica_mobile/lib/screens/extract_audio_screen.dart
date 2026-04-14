import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/audio_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';
import '../widgets/top_bar.dart';
import '../widgets/labels.dart';

class ExtractAudioScreen extends StatefulWidget {
  const ExtractAudioScreen({super.key});

  @override
  State<ExtractAudioScreen> createState() => _ExtractAudioScreenState();
}

class _ExtractAudioScreenState extends State<ExtractAudioScreen> {
  String? _filePath;
  String? _fileName;
  int? _fileSizeBytes;
  String _selectedFormat = 'mp3';
  String _selectedBitrate = '192k';
  bool _isExtracting = false;
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
          title: 'Extract Audio',
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
                
                Text('SONIC ENGINE', 
                  style: AppTextStyles.studioLabel.copyWith(
                    color: AppColors.audioRose.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFilePicker(isDark),
                
                if (_filePath != null) ...[
                  const SizedBox(height: 32),
                  _buildPulseSpectrum(),
                  const SizedBox(height: 32),
                  
                  Text('OUTPUT QUALITY', style: AppTextStyles.studioLabel),
                  const SizedBox(height: 12),
                  _buildFormatSelection(isDark),
                  const SizedBox(height: 16),
                  _buildBitrateSelection(isDark),
                  
                  const SizedBox(height: 32),
                  Text('TARGET DIRECTORY', style: AppTextStyles.studioLabel),
                  const SizedBox(height: 12),
                  _buildVaultPath(isDark),
                ],
                
                if (_isExtracting) _buildProgressSection(),
                if (_errorMessage != null) _buildErrorCard(),
                if (_outputPath != null && !_isExtracting) _buildSuccessModule(),
                
                const SizedBox(height: 48),
                _buildActionButtons(isDark),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(bool isDark) {
    return GestureDetector(
      onTap: _isExtracting ? null : _pickFile,
      child: LiquidGlassContainer(
        height: 180,
        blur: 35,
        color: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.85),
        child: _filePath == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.audioRose.withOpacity(0.1),
                      ),
                      child: const Icon(Icons.music_note_rounded, size: 36, color: AppColors.audioRose),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SELECT SOURCE VIDEO',
                      style: AppTextStyles.studioLabel.copyWith(
                        color: isDark ? Colors.white : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MP4 · MKV · MOV · AVI',
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38,
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
                    const Icon(Icons.movie_filter_rounded, color: AppColors.audioRose, size: 40),
                    const SizedBox(height: 16),
                    Text(
                      _fileName!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineSmall.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      FileService.formatFileSize(_fileSizeBytes!),
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.onSurfaceVar, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'TAP TO SWAP',
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 10,
                        color: AppColors.audioRose.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPulseSpectrum() {
    return LiquidGlassContainer(
      height: 80,
      blur: 20,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(24, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 10 + (index % 5) * 10,
              width: 3,
              decoration: BoxDecoration(
                color: AppColors.audioRose.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildFormatSelection(bool isDark) {
    final formats = ['mp3', 'wav', 'aac'];
    return Row(
      children: formats.map((f) {
        final active = _selectedFormat == f;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: _isExtracting ? null : () => setState(() => _selectedFormat = f),
              child: LiquidGlassContainer(
                borderRadius: 16,
                color: active 
                    ? AppColors.audioRose.withOpacity(isDark ? 0.3 : 0.15) 
                    : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      f.toUpperCase(),
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 12,
                        color: active 
                            ? (isDark ? Colors.white : AppColors.audioRose) 
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBitrateSelection(bool isDark) {
    final bitrates = ['128k', '192k', '256k', '320k'];
    return Row(
      children: bitrates.map((b) {
        final active = _selectedBitrate == b;
        return Expanded(
          child: GestureDetector(
            onTap: _isExtracting ? null : () => setState(() => _selectedBitrate = b),
            child: Container(
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? AppColors.audioRose.withOpacity(0.5) : Colors.transparent,
                ),
                color: active ? AppColors.audioRose.withOpacity(0.1) : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  b,
                  style: AppTextStyles.studioLabel.copyWith(
                    fontSize: 10,
                    color: active ? AppColors.audioRose : (isDark ? Colors.white24 : Colors.black26),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVaultPath(bool isDark) {
    return FutureBuilder<String>(
      future: FileService.getOutputDirectoryForCategory(OutputCategory.audio),
      builder: (ctx, snap) {
        return LiquidGlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          blur: 15,
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
          child: Row(
            children: [
              const Icon(Icons.folder_copy_rounded, size: 18, color: AppColors.audioRose),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  snap.hasData ? FileService.getDisplayPath(snap.data!) : 'Loading...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppColors.lightText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ISOLATING FREQUENCIES...',
                style: AppTextStyles.studioLabel.copyWith(color: AppColors.audioRose),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: AppTextStyles.studioLabel.copyWith(fontSize: 12, color: AppColors.audioRose),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: _progress,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.audioRose, AppColors.audioViolet]),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(color: AppColors.audioRose.withOpacity(0.35), blurRadius: 12),
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
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.audioRose, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessModule() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: LiquidGlassContainer(
        padding: const EdgeInsets.all(20),
        color: AppColors.audioRose.withOpacity(0.05),
        child: Column(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.audioRose, size: 40),
            const SizedBox(height: 16),
            Text(
              'EXTRACTION COMPLETE',
              style: AppTextStyles.studioLabel.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              'The audio file has been saved to your vault.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(fontSize: 13, color: AppColors.onSurfaceVar, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => FileService.openFile(_outputPath!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.audioRose,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'OPEN FILE',
                  style: AppTextStyles.studioLabel.copyWith(color: Colors.white, fontSize: 13),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final canEngage = _filePath != null && !_isExtracting;
    
    return MediaPillButton(
      label: _isExtracting ? 'ABORT EXTRACTION' : 'ENGAGE EXTRACTION',
      onTap: canEngage ? _onExtract : (_isExtracting ? () => _showCancelDialog(context, _currentTaskId!) : () => {}),
      accentColor: _isExtracting ? AppColors.audioRose.withOpacity(0.3) : AppColors.audioRose,
      isLoading: false, // We handle progress separately in this screen
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null) {
      setState(() {
        _filePath = result.files.single.path;
        _fileName = result.files.single.name;
        _fileSizeBytes = result.files.single.size;
        _errorMessage = null;
        _outputPath = null;
        _progress = 0.0;
      });
    }
  }

  Future<void> _onExtract() async {
    setState(() { _isExtracting = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask(
      _fileName!,
      'extractAudio',
      subtext: 'Extracting ${_selectedFormat.toUpperCase()} at ${_selectedBitrate}',
    );
    _currentTaskId = taskId;

    try {
      final outputPath = await AudioService.extractAudio(
        inputFilePath: _filePath!,
        outputFormat: _selectedFormat,
        bitrate: _selectedBitrate,
        onCancelSetup: (hook) => provider.setCancelHook(taskId, hook),
        onProgress: (p) => setState(() { _progress = p; provider.updateProgress(taskId, p); }),
      );
      await provider.completeTask(taskId, outputPath);
      setState(() { _outputPath = outputPath; _isExtracting = false; });
    } catch (e) {
      if (e.toString().contains('cancelled')) return;
      provider.failTask(taskId, e.toString());
      setState(() { _errorMessage = e.toString(); _isExtracting = false; });
    }
  }

  void _showCancelDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
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
            'ABORT THE ACTIVE SONIC EXTRACTION PROCESS?',
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
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                context.read<TaskProvider>().cancelTask(taskId);
                Navigator.pop(ctx);
                setState(() => _isExtracting = false);
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
