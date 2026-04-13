import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../core/theme.dart';
import '../services/pdf_tools_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/success_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';

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
                      'PRISM FUSION',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryIndigo.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _addFilesButton(),
                    
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SEQUENCE ARCHIVE',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          Text(
                            'DRAG TO REORDER',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              letterSpacing: 1,
                              color: Colors.white24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _reorderableList(),
                    ],
                    
                    if (_isConverting) _progressSection(),
                    if (_errorMessage != null) _buildErrorCard(),
                    if (_outputPath != null && !_isConverting) ...[
                      const SizedBox(height: 24),
                      _buildSuccessCard(),
                    ],
                    
                    if (_selectedFiles.length >= 2 && !_isConverting) _buildOutputLocation(context),
                    
                    const SizedBox(height: 48),
                    _mergeButton(),
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
          'Merge',
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
              'VAULT SECURITY · ON-DEVICE PROCESSING',
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

  Widget _addFilesButton() {
    return GestureDetector(
      onTap: _isConverting ? null : _pickFiles,
      child: LiquidGlassContainer(
        height: 120,
        blur: 35,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
                child: const Icon(Icons.add_rounded, size: 24, color: Colors.white54),
              ),
              const SizedBox(height: 12),
              Text(
                'INSERT PDF CHANNELS',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  letterSpacing: 1,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reorderableList() {
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
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: AppColors.primaryIndigo, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        FileService.formatFileSize(file.size),
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: Colors.white30,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _isConverting ? null : () => setState(() => _selectedFiles.removeAt(index)),
                  child: const Icon(Icons.close_rounded, size: 18, color: Colors.white24),
                ),
                const SizedBox(width: 8),
                const ReorderableDragStartListener(
                  index: 0, // Not used in builder but required for internal check
                  child: Icon(Icons.drag_indicator_rounded, size: 20, color: Colors.white10),
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
                style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 1.5, color: Colors.white54),
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
      label: 'Fusion complete.',
      onConvertAnother: _resetForm,
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
        accentColor: AppColors.primaryIndigo,
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
    final taskId = provider.addTask('Merge ${_selectedFiles.length} PDFs', 'mergePdf');
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
      _selectedFiles.clear();
      _outputPath = null;
      _errorMessage = null;
      _progress = 0.0;
    });
  }

  Widget _buildOutputLocation(BuildContext context) {
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

  void _showCancelDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Text('Termination', style: GoogleFonts.outfit(color: Colors.white)),
          content: Text('Abort active fusion sequence?', style: GoogleFonts.outfit(color: Colors.white70)),
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
                _resetForm();
              },
              child: Text('ABORT', style: GoogleFonts.outfit(color: AppColors.audioRose)),
            ),
          ],
        ),
      ),
    );
  }
}








