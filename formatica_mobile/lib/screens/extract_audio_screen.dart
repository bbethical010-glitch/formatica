import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/audio_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/glass_chip.dart';
import '../widgets/success_card.dart';

class ExtractAudioScreen extends StatefulWidget {
  const ExtractAudioScreen({super.key});

  @override
  State<ExtractAudioScreen> createState() => _ExtractAudioScreenState();
}

class _ExtractAudioScreenState extends State<ExtractAudioScreen> {
  String? _filePath;
  String? _fileName;
  int? _fileSizeBytes;
  String _selectedFormat = 'MP3';
  String _selectedQuality = 'HIGH';

  bool _isLoading = false;
  double _progress = 0.0;
  String? _errorMessage;
  String? _outputPath;

  @override
  Widget build(BuildContext context) {
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, size: 12, color: Colors.greenAccent),
                  const SizedBox(width: 4),
                  Text('On-Device', style: AppTextStyles.badge.copyWith(color: Colors.greenAccent, fontSize: 8)),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Capture', style: AppTextStyles.displayLarge.copyWith(fontSize: 32)),
                    Text(
                      'VOCALIS AUDIO ENGINE',
                      style: AppTextStyles.studioLabel.copyWith(color: AppColors.audioRose),
                    ),
                    const SizedBox(height: 32),

                    // Preview Zone
                    GestureDetector(
                      onTap: _isLoading ? null : _pickFile,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: LiquidGlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: 24,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/video_hero.png',
                                fit: BoxFit.cover,
                              ),
                              Container(color: Colors.black.withOpacity(0.4)),
                              if (_fileName != null)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
                                      const SizedBox(height: 12),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: Text(
                                          _fileName!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_circle_outline, size: 48, color: Colors.white54),
                                      SizedBox(height: 12),
                                      Text('SELECT SOURCE VIDEO', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    _buildSectionTitle('OUTPUT FORMAT'),
                    const SizedBox(height: 16),
                    Row(
                      children: ['MP3', 'WAV', 'AAC', 'FLAC'].map((f) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GlassChip(
                            label: f,
                            isSelected: _selectedFormat == f,
                            onTap: () => setState(() => _selectedFormat = f),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),
                    _buildSectionTitle('FIDELITY CONTROL'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        QualityPill(
                          label: 'STUDIO (320kbps)',
                          isSelected: _selectedQuality == 'HIGH',
                          onTap: () => setState(() => _selectedQuality = 'HIGH'),
                        ),
                        const SizedBox(width: 8),
                        QualityPill(
                          label: 'BALANCED',
                          isSelected: _selectedQuality == 'MEDIUM',
                          onTap: () => setState(() => _selectedQuality = 'MEDIUM'),
                        ),
                      ],
                    ),

                    if (_errorMessage != null)
                      _buildErrorCard(),
                    
                    if (_outputPath != null && !_isLoading)
                      SuccessCard(
                        outputPath: _outputPath!,
                        label: 'Extraction complete.',
                        onConvertAnother: _resetForm,
                      ),
                    
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            
            // Sticky Bar
            _buildStickyBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.badge.copyWith(
        color: Colors.white.withOpacity(0.4),
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildStickyBar() {
    final canExtract = _filePath != null && !_isLoading;
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      child: LiquidGlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.all(12),
        color: AppColors.darkSurfaceHigh,
        child: _isLoading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('EXTRACTING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.audioRose)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: AppColors.audioRose,
                    minHeight: 4,
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: canExtract ? _onExtract : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.audioRose,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('INITIATE EXTRACTION', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return LiquidGlassContainer(
      padding: const EdgeInsets.all(16),
      color: AppColors.audioRose.withOpacity(0.1),
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.audioRose, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.audioRose, fontSize: 13))),
        ],
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
    setState(() { _isLoading = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask('Extract from $_fileName', 'extract');

    try {
      final outputPath = await AudioService.extractAudio(
        inputFilePath: _filePath!,
        outputFormat: _selectedFormat.toLowerCase(),
        bitrate: _selectedQuality == 'HIGH' ? '320k' : '128k',
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      provider.completeTask(taskId, outputPath);
      if (mounted) setState(() { _outputPath = outputPath; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  void _resetForm() {
    setState(() {
      _filePath = null;
      _fileName = null;
      _outputPath = null;
      _errorMessage = null;
      _progress = 0.0;
      _isLoading = false;
    });
  }
}
