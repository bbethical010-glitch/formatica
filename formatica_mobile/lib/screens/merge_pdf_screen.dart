import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/pdf_tools_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/success_card.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<PlatformFile> _selectedFiles = [];
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
                    Text('Merge', style: AppTextStyles.displayLarge.copyWith(fontSize: 32)),
                    Text(
                      'PRISM FUSION ENGINE',
                      style: AppTextStyles.studioLabel.copyWith(color: AppColors.mergeTeal),
                    ),
                    const SizedBox(height: 32),

                    // Preview Zone
                    GestureDetector(
                      onTap: _isLoading ? null : _pickFiles,
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: LiquidGlassContainer(
                          padding: EdgeInsets.zero,
                          borderRadius: 24,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                'assets/images/pdf_hero.png',
                                fit: BoxFit.cover,
                              ),
                              Container(color: Colors.black.withOpacity(0.4)),
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_circle_outline, size: 48, color: Colors.white54),
                                    SizedBox(height: 12),
                                    Text('ADD PDF CHANNELS', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 40),
                      _buildSectionTitle('SEQUENCE ARCHIVE'),
                      const SizedBox(height: 16),
                      _buildReorderableList(),
                    ],
                    
                    if (_errorMessage != null)
                      _buildErrorCard(),
                    
                    if (_outputPath != null && !_isLoading)
                      SuccessCard(
                        outputPath: _outputPath!,
                        label: 'Fusion complete.',
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

  Widget _buildReorderableList() {
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
          padding: const EdgeInsets.only(bottom: 8),
          child: LiquidGlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            borderRadius: 16,
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf, color: AppColors.mergeTeal, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.white24),
                  onPressed: () => setState(() => _selectedFiles.removeAt(index)),
                ),
                const Icon(Icons.drag_indicator, size: 20, color: Colors.white10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStickyBar() {
    final canMerge = _selectedFiles.length >= 2 && !_isLoading;
    
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
                      const Text('SYNTHESIZING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.mergeTeal)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: AppColors.mergeTeal,
                    minHeight: 4,
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: canMerge ? _onConvert : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.mergeTeal,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('INITIATE FUSION', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf'], allowMultiple: true);
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
    setState(() { _isLoading = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask('Merge ${_selectedFiles.length} PDFs', 'mergePdf');

    try {
      final filePaths = _selectedFiles.map((f) => f.path!).toList();
      final outputPath = await PdfToolsService.mergePdfs(
        filePaths: filePaths,
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
      _selectedFiles.clear();
      _outputPath = null;
      _errorMessage = null;
      _progress = 0.0;
    });
  }
}
