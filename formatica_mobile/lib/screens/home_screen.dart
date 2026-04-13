import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../widgets/liquid_glass.dart';
import 'extract_audio_screen.dart';
// Import other screens as they are refactored

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshBackground(
        child: CustomScrollView(
          slivers: [
            // Top Bar
            SliverAppBar(
              floating: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primaryIndigo,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text(
                        'F',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'FORMATICA',
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {
                    // Toggle theme logic
                  },
                  icon: const Icon(Icons.wb_sunny_outlined),
                ),
                const SizedBox(width: 8),
              ],
            ),

            // Search & Status
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  // Search Box
                  LiquidGlassContainer(
                    blur: 16,
                    borderRadius: 16,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: const TextField(
                      decoration: InputDecoration(
                        icon: Icon(Icons.search, color: Colors.white38),
                        hintText: 'Search for tools...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status Chip
                  Row(
                    children: [
                      FadeTransition(
                        opacity: _pulseController,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ON-DEVICE MODE ACTIVE',
                        style: AppTextStyles.badge.copyWith(
                          color: Colors.greenAccent.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),

            // Document Tools
            _buildSectionHeader('DOCUMENT TOOLS', AppColors.docIndigo),
            _buildDocToolsGrid(),

            // Media Tools
            _buildSectionHeader('MEDIA TOOLS', AppColors.videoPurple),
            _buildMediaToolsGrid(),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accent) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: AppTextStyles.studioLabel.copyWith(color: accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocToolsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildListDelegate([
          _buildToolCard(
            'Word to PDF',
            Icons.description_outlined,
            AppColors.docIndigo,
            () {},
          ),
          _buildToolCard(
            'Split PDF',
            Icons.call_split_outlined,
            AppColors.splitAmber,
            () {},
          ),
          _buildToolCard(
            'Merge PDF',
            Icons.call_merge_outlined,
            AppColors.mergeTeal,
            () {},
          ),
          _buildToolCard(
            'Extract Images',
            Icons.image_outlined,
            AppColors.imageCyan,
            () {},
          ),
        ]),
      ),
    );
  }

  Widget _buildMediaToolsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        delegate: SliverChildListDelegate([
          _buildToolCard(
            'Extract Audio',
            Icons.music_note_outlined,
            AppColors.audioRose,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ExtractAudioScreen()),
              );
            },
          ),
          _buildToolCard(
            'Optimize Video',
            Icons.video_settings_outlined,
            AppColors.videoPurple,
            () {},
          ),
          _buildToolCard(
            'Format Convert',
            Icons.sync_alt_outlined,
            AppColors.primaryLight,
            () {},
          ),
          _buildToolCard(
            'Compress Img',
            Icons.compress_outlined,
            AppColors.compressOrange,
            () {},
          ),
        ]),
      ),
    );
  }

  Widget _buildToolCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return LiquidGlassContainer(
      blur: 20,
      borderRadius: 16,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
