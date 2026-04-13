import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/pdf_tools_service.dart';
import '../services/file_service.dart';
import '../providers/task_provider.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/success_card.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _filePath;
  String? _fileName;
  int? _fileSizeBytes;
  
  final _startPageController = TextEditingController(text: '1');
  final _endPageController = TextEditingController(text: '0');

  bool _isLoading = false;
  double _progress = 0.0;
  String? _errorMessage;
  String? _outputPath;

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    super.dispose();
  }

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
                    Text('Split', style: AppTextStyles.displayLarge.copyWith(fontSize: 32)),
                    Text(
                      'LEXICON FRAGMENTATION ENGINE',
                      style: AppTextStyles.studioLabel.copyWith(color: AppColors.splitAmber),
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
                                'assets/images/pdf_hero.png',
                                fit: BoxFit.cover,
                              ),
                              Container(color: Colors.black.withOpacity(0.4)),
                              if (_fileName != null)
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.picture_as_pdf, size: 64, color: Colors.white),
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
                                      Icon(Icons.file_open_outlined, size: 48, color: Colors.white54),
                                      SizedBox(height: 12),
                                      Text('SELECT SOURCE PDF', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_filePath != null) ...[
                      const SizedBox(height: 40),
                      _buildSectionTitle('FRAGMENT PARAMETERS'),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildPageInput('START PAGE', _startPageController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPageInput('END PAGE', _endPageController)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'SET END PAGE TO 0 TO SPLIT TO EOF',
                        style: TextStyle(fontSize: 10, color: Colors.white24, letterSpacing: 0.5),
                      ),
                    ],
                    
                    if (_errorMessage != null)
                      _buildErrorCard(),
                    
                    if (_outputPath != null && !_isLoading)
                      SuccessCard(
                        outputPath: _outputPath!,
                        label: 'Splitting complete.',
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

  Widget _buildPageInput(String label, TextEditingController controller) {
    return LiquidGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 16,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 10, color: Colors.white38),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildStickyBar() {
    final canSplit = _filePath != null && !_isLoading;
    
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
                      const Text('FRAGMENTING...', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.splitAmber)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    color: AppColors.splitAmber,
                    minHeight: 4,
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: canSplit ? _onConvert : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.splitAmber,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('INITIATE SPLIT', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
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
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
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
    final st = int.tryParse(_startPageController.text);
    final ed = int.tryParse(_endPageController.text);
    if (st == null || ed == null) return;

    setState(() { _isLoading = true; _errorMessage = null; });
    final provider = context.read<TaskProvider>();
    final taskId = provider.addTask('Split $_fileName', 'split');

    try {
      final outputPath = await PdfToolsService.splitPdf(
        inputFilePath: _filePath!,
        startPage: st,
        endPage: ed,
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
      _startPageController.text = '1';
      _endPageController.text = '0';
    });
  }
}
