import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/media_pill_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Asymmetric Editorial Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CORE', style: AppTextStyles.studioLabel),
                    const SizedBox(height: 8),
                    Text(
                      'Studio',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.darkTextPrimary,
                        height: 0.9,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Professional on-device media lab.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.darkTextSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Storage Dashboard Module
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: LiquidGlassContainer(
                   padding: const EdgeInsets.all(24),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text('INTERNAL STORAGE', style: AppTextStyles.studioLabel.copyWith(color: AppColors.imageCyan)),
                               const SizedBox(height: 4),
                               Text('84.2 GB Used', style: AppTextStyles.headlineSmall.copyWith(fontSize: 18)),
                             ],
                           ),
                           Icon(Icons.pie_chart_outline_rounded, color: AppColors.imageCyan, size: 32),
                         ],
                       ),
                       const SizedBox(height: 16),
                       // Progress bar
                       Container(
                         height: 6,
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(3),
                           color: Colors.white.withOpacity(0.05),
                         ),
                         child: FractionallySizedBox(
                           alignment: Alignment.centerLeft,
                           widthFactor: 0.65,
                           child: Container(
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(3),
                               gradient: const LinearGradient(
                                 colors: [AppColors.imageCyan, AppColors.primaryIndigo],
                               ),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                ),
              ),
            ),

            // 3. Tool Sections (Staggered/Categorized)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 16),
                child: Text('MEDIA PROCESSING', style: AppTextStyles.studioLabel),
              ),
            ),

            // Video Tools
            _buildToolSection(
              context,
              title: 'VIDEO STEWARD',
              color: AppColors.videoPurple,
              tools: [
                _ToolData('Convert Video', 'MP4, MKV, GIF', Icons.video_file_outlined, '/convertVideo'),
                _ToolData('Compress Video', 'Reduce footprint', Icons.compress_outlined, '/compressVideo'),
                _ToolData('Extract Audio', 'MP3, AAC, WAV', Icons.music_note_outlined, '/extractAudio'),
              ],
            ),

            // Image & PDF Tools
            _buildToolSection(
              context,
              title: 'IMAGE & DOCUMENT',
              color: AppColors.imageCyan,
              tools: [
                _ToolData('Images to PDF', 'Combine assets', Icons.photo_library_outlined, '/imagesToPdf'),
                _ToolData('Convert Image', 'JPG, PNG, WEBP', Icons.image_outlined, '/convertImage'),
                _ToolData('Convert Document', 'DOCX, ODT, HTML', Icons.description_outlined, '/convert'),
              ],
            ),

            // PDF Utilities
            _buildToolSection(
              context,
              title: 'PDF UTILITIES',
              color: AppColors.audioRose,
              tools: [
                _ToolData('Merge PDF', 'Combine files', Icons.picture_as_pdf_outlined, '/mergePdf'),
                _ToolData('Split PDF', 'Extract pages', Icons.splitscreen_outlined, '/splitPdf'),
                _ToolData('Greyscale PDF', 'B&W Optimization', Icons.format_color_reset_outlined, '/greyscalePdf'),
              ],
            ),

            // Bottom Spacing for Dock
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildToolSection(BuildContext context, {required String title, required Color color, required List<_ToolData> tools}) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tool = tools[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LiquidGlassContainer(
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, tool.route),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.15),
                          ),
                          child: Icon(tool.icon, color: color, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tool.title, style: AppTextStyles.headlineSmall.copyWith(fontSize: 16)),
                              const SizedBox(height: 2),
                              Text(tool.subtitle, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.darkTextSecondary, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: AppColors.darkTextSecondary.withOpacity(0.5), size: 14),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: tools.length,
        ),
      ),
    );
  }
}

class _ToolData {
  final String title, subtitle, route;
  final IconData icon;
  _ToolData(this.title, this.subtitle, this.icon, this.route);
}








