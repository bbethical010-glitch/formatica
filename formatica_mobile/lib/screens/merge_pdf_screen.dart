import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../core/theme.dart';
import '../services/pdf_tools_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';
import '../widgets/top_bar.dart';
import '../widgets/labels.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<PlatformFile> _selectedFiles = [];
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
          title: 'Fusion',
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
                  'PRISM FUSION',
                  style: AppTextStyles.studioLabel.copyWith(
                    color: AppColors.docIndigo.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 16),
                
                _addFilesButton(isDark),
                
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SEQUENCE ARCHIVE',
                        style: AppTextStyles.studioLabel.copyWith(
                          fontSize: 10,
                          color: isDark ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        'DRAG TO REORDER',
                        style: AppTextStyles.studioLabel.copyWith(
                          fontSize: 10,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _reorderableList(isDark),
                ],
                
                if (_isConverting) _progressSection(),
                if (_errorMessage != null) _buildErrorCard(),
                if (_outputPath != null && !_isConverting) ...[
                  const SizedBox(height: 24),
                  _buildSuccessModule(),
                ],
                
                if (_selectedFiles.length >= 2 && !_isConverting) _buildOutputLocation(context, isDark),
                
                const SizedBox(height: 48),
                _mergeButton(),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _addFilesButton(bool isDark) {
    return GestureDetector(
      onTap: _isConverting ? null : _pickFiles,
      child: LiquidGlassContainer(
        height: 120,
        blur: 35,
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        child: Center(
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
                  Icons.add_rounded, 
                  size: 24, 
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'INSERT PDF CHANNELS',
                style: AppTextStyles.studioLabel.copyWith(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reorderableList(bool isDark) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedFiles.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;
          final item = _selectedFiles.removeAt(oldIndex);
          _selectedFiles.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final file = _selectedFiles[index];
        return Padding(
          key: ValueKey(file.path),
          padding: const EdgeInsets.only(bottom: 12),
          child: LiquidGlassContainer(
            padding: const EdgeInsets.all(16),
            blur: 15,
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.7),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: AppColors.docIndigo, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        FileService.formatFileSize(file.size),
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isConverting ? null : () => setState(() => _selectedFiles.removeAt(index)),
                  child: Icon(
                    Icons.close_rounded, 
                    size: 18, 
                    color: isDark ? Colors.white24 : Colors.black26,
                  ),
                ),
                const SizedBox(width: 8),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_indicator_rounded, 
                    size: 20, 
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
              ],
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
                'SYNTHESIZING DOCUMENT...',
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
            'FUSION COMPLETE',
            style: AppTextStyles.headlineSmall.copyWith(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'The sequence has been perfectly merged into a single archive.',
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

  Widget _mergeButton() {
    final canConvert = _selectedFiles.length >= 2 && !_isConverting;
    if (_isConverting) {
      return MediaPillButton(
        label: 'ABORT FUSION',
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
        label: 'INITIATE FUSION',
        onTap: canConvert ? () => _onConvert() : () => {},
        accentColor: AppColors.docIndigo,
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (!_selectedFiles.any((f) => f.path == file.path)) {
            _selectedFiles.add(file);
          }
        }
        _errorMessage = null;
        _outputPath = null;
      });
    }
  }

  Future<void> _onConvert() async {
    setState(() { _isConverting = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask(
      'Formatica Fusion',
      'mergePdf',
      subtext: 'Synthesizing ${_selectedFiles.length} PDF channels',
    );
    _currentTaskId = taskId;
    
    try {
      final filePaths = _selectedFiles.map((f) => f.path!).toList();
      final outputPath = await PdfToolsService.mergePdfs(
        filePaths: filePaths,
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
      _selectedFiles.clear();
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
              'FUSION VAULT',
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
            'ABORT THE ACTIVE FUSION SEQUENCE?',
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








