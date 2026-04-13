import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/theme_face_toggle.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FORMATICA',
                    style: AppTextStyles.studioLabel.copyWith(
                      color: isDark ? AppColors.white : AppColors.lightText,
                      letterSpacing: 4.0,
                    ),
                  ),
                  ThemeFaceToggle(
                    isDark: isDark,
                    onToggle: () {
                      // Note: Theme toggle logic would ideally be in a Provider
                    },
                  ),
                ],
              ),
            ),

            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // On-Device Status & Search
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _OnDeviceBadge(),
                          const SizedBox(height: 20),
                          _buildSearchBar(isDark),
                        ],
                      ),
                    ),
                  ),

                  // Header "Convert Document" Card (Staggered)
                  SliverToBoxAdapter(
                    child: _buildHeaderCard(context, isDark),
                  ),

                  // Tool Grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildToolCard(context, index, isDark),
                        childCount: _tools.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDark ? Colors.white : AppColors.lightText),
        decoration: InputDecoration(
          hintText: 'SEARCH STUDIO TOOLS...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, bool isDark) {
    const startDelay = 0.1;
    return FadeTransition(
      opacity: CurvedAnimation(parent: _staggerController, curve: const Interval(startDelay, startDelay + 0.3)),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _staggerController, curve: const Interval(startDelay, startDelay + 0.4, curve: Curves.easeOutCubic)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/convert'),
            child: LiquidGlassContainer(
              padding: const EdgeInsets.all(28),
              borderRadius: 28,
              color: isDark ? Colors.white.withOpacity(0.09) : Colors.white.withOpacity(0.9),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withOpacity(isDark ? 0.3 : 0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONVERT DOCUMENT',
                          style: AppTextStyles.headlineSmall.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DOCX, ODT, HTML TO ANY',
                          style: AppTextStyles.bodyMedium.copyWith(fontSize: 14, color: AppColors.onSurfaceVar),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.onSurfaceVar),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolCard(BuildContext context, int index, bool isDark) {
    final tool = _tools[index];
    final double startDelay = 0.2 + (index * 0.05);

    return FadeTransition(
      opacity: CurvedAnimation(parent: _staggerController, curve: Interval(startDelay.clamp(0.0, 0.9), (startDelay + 0.3).clamp(0.0, 1.0))),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(parent: _staggerController, curve: Interval(startDelay.clamp(0.0, 0.9), (startDelay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic)),
        ),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(context, tool.route),
          child: LiquidGlassContainer(
            padding: const EdgeInsets.all(20),
            borderRadius: 28,
            color: isDark ? Colors.white.withOpacity(0.07) : Colors.white.withOpacity(0.85),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tool.color.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(tool.icon, color: tool.color, size: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tool.title.toUpperCase(),
                      style: AppTextStyles.headlineSmall.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tool.subtitle.toUpperCase(),
                      style: AppTextStyles.bodyMedium.copyWith(fontSize: 12, color: AppColors.onSurfaceVar),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnDeviceBadge extends StatefulWidget {
  const _OnDeviceBadge();

  @override
  State<_OnDeviceBadge> createState() => _OnDeviceBadgeState();
}

class _OnDeviceBadgeState extends State<_OnDeviceBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.2).animate(
              CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
            ),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0xFF10B981), blurRadius: 4, spreadRadius: 1),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ON-DEVICE MODE',
            style: AppTextStyles.studioLabel.copyWith(
              fontSize: 10,
              color: isDark ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final Color color;

  const _ToolData(this.title, this.subtitle, this.icon, this.route, this.color);
}

final List<_ToolData> _tools = [
  _ToolData('Extract Audio', 'MP3, AAC, WAV', Icons.music_note_outlined, '/extractAudio', AppColors.audioRose),
  _ToolData('Convert Video', 'MP4, MKV, GIF', Icons.video_file_outlined, '/convertVideo', AppColors.videoPurple),
  _ToolData('Compress Video', 'Reduce footprint', Icons.compress_outlined, '/compressVideo', AppColors.compressOrange),
  _ToolData('Merge PDF', 'Combine files', Icons.picture_as_pdf_outlined, '/mergePdf', AppColors.mergeTeal),
  _ToolData('Split PDF', 'Extract pages', Icons.splitscreen_outlined, '/splitPdf', AppColors.splitAmber),
  _ToolData('Images to PDF', 'Combine assets', Icons.photo_library_outlined, '/imagesToPdf', AppColors.docIndigo),
  _ToolData('Convert Image', 'JPG, PNG, WEBP', Icons.image_outlined, '/convertImage', AppColors.tertiary),
  _ToolData('Greyscale PDF', 'Eco-optimization', Icons.format_color_reset_outlined, '/greyscalePdf', AppColors.greySlate),
];
