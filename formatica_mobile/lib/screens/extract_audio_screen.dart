import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../core/theme.dart';
import '../services/audio_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/success_card.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';

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
                      'VOCALIS ENGINE',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.audioRose.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    _fileDropZone(context),
                    
                    if (_filePath != null) ...[
                      const SizedBox(height: 40),
                      Text(
                        'SONIC SPECTRUM',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _formatChips(),
                      
                      const SizedBox(height: 32),
                      Text(
                        'PRECISION BITRATE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _bitrateChips(),
                      const SizedBox(height: 12),
                      Text(
                        '128K (ECO) · 192K (STANDARD) · 320K (HI-RES)',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: Colors.white24,
                        ),
                      ),
                    ],
                    
                    if (_isExtracting) _progressSection(),
                    if (_errorMessage != null) _buildErrorCard(),
                    if (_outputPath != null && !_isExtracting) ...[
                      const SizedBox(height: 24),
                      _buildSuccessCard(),
                    ],
                    if (_filePath != null && !_isExtracting) _buildOutputLocation(context),
                    
                    const SizedBox(height: 48),
                    _extractButton(),
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
          'Vocalis',
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
                color: AppColors.audioRose.withOpacity(0.5),
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
              'LOCAL PROCESSING · NO CLOUD UPLOAD',
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
      onTap: _isExtracting ? null : _pickFile,
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
                      child: const Icon(Icons.graphic_eq, size: 32, color: Colors.white54),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SELECT SOURCE VIDEO',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        letterSpacing: 1,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MP4 · MKV · MOV · AVI',
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
                    const Icon(Icons.movie_outlined, color: AppColors.audioRose, size: 32),
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
                        color: AppColors.audioRose.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _formatChips() {
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
                blur: 10,
                color: active ? AppColors.audioRose.withOpacity(0.3) : Colors.white.withOpacity(0.05),
                specularOpacity: active ? 0.4 : 0.1,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      f.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? Colors.white : Colors.white54,
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

  Widget _bitrateChips() {
    final bitrates = ['128k', '192k', '256k', '320k'];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: bitrates.map((b) {
        final active = _selectedBitrate == b;
        return GestureDetector(
          onTap: _isExtracting ? null : () => setState(() => _selectedBitrate = b),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: active ? AppColors.audioRose.withOpacity(0.8) : Colors.white.withOpacity(0.05),
              border: Border.all(color: active ? Colors.transparent : Colors.white10),
              boxShadow: active ? [
                BoxShadow(color: AppColors.audioRose.withOpacity(0.3), blurRadius: 15, spreadRadius: 1)
              ] : [],
            ),
            child: Text(
              b,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.white : Colors.white54,
              ),
            ),
          ),
        );
      }).toList(),
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
                'ISOLATING FREQUENCIES…',
                style: GoogleFonts.outfit(fontSize: 10, letterSpacing: 1.5, color: Colors.white54),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.audioRose),
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
                  color: AppColors.audioRose,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.audioRose.withOpacity(0.5),
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
      label: 'Extraction complete.',
      onConvertAnother: _resetForm,
    );
  }

  Widget _extractButton() {
    final canExtract = _filePath != null && !_isExtracting;
    if (_isExtracting) {
      return MediaPillButton(
        label: 'HALT PROCESS',
        onTap: () {
          if (_currentTaskId != null) {
            _showCancelDialog(context, _currentTaskId!);
          }
        },
        accentColor: AppColors.audioRose.withOpacity(0.3),
      );
    }

    return Opacity(
      opacity: canExtract ? 1.0 : 0.3,
      child: MediaPillButton(
        label: 'INITIATE EXTRACTION',
        onTap: canExtract ? () => _onExtract() : () => {},
        accentColor: AppColors.audioRose,
      ),
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
      });
    }
  }

  Future<void> _onExtract() async {
    setState(() { _isExtracting = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask(
      '$_fileName → ${_selectedFormat.toUpperCase()}',
      'extractAudio',
    );

    _currentTaskId = taskId;
    try {
      final outputPath = await AudioService.extractAudio(
        inputFilePath: _filePath!,
        outputFormat: _selectedFormat,
        bitrate: _selectedBitrate,
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
        setState(() { _outputPath = outputPath; _isExtracting = false; });
      }
    } catch (e) {
      if (e.toString().contains('cancelled')) return;
      provider.failTask(taskId, e.toString());
      if (mounted) {
        setState(() { _errorMessage = e.toString(); _isExtracting = false; });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _filePath = null;
      _fileName = null;
      _fileSizeBytes = null;
      _outputPath = null;
      _errorMessage = null;
      _progress = 0.0;
    });
  }

  Widget _buildOutputLocation(BuildContext context) {
    return FutureBuilder<String>(
      future: FileService.getOutputDirectoryForCategory(OutputCategory.audio),
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
                  const Icon(Icons.folder_open, size: 18, color: AppColors.audioRose),
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
          content: Text('Abort active sonic isolation?', style: GoogleFonts.outfit(color: Colors.white70)),
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








