import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../core/theme.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../providers/task_provider.dart';
import '../services/file_service.dart';
import '../widgets/liquid_glass.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Consumer<TaskProvider>(
            builder: (ctx, provider, _) {
              final active = provider.activeTasks;
              final completed = provider.completedTasks;

              if (active.isEmpty && completed.isEmpty) {
                return _buildEmptyState(context, isDark);
              }

              return Column(
                children: [
                  _buildHeader(context, provider, isDark),
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (active.isNotEmpty) ...[
                          _buildSectionHeader('ACTIVE NOW', AppColors.primary),
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _ActiveJobCard(task: active[i]),
                                ),
                                childCount: active.length,
                              ),
                            ),
                          ),
                        ],

                        if (completed.isNotEmpty) ..._buildCompletedSections(completed, isDark),

                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, TaskProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACTIVITY LOG',
                style: AppTextStyles.studioLabel.copyWith(
                  letterSpacing: 1.5,
                  fontSize: 10,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'History',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 32,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (provider.completedTasks.isNotEmpty)
            GestureDetector(
              onTap: () => _confirmClear(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.error.withOpacity(0.1),
                  border: Border.all(color: AppColors.error.withOpacity(0.2)),
                ),
                child: Text(
                  'CLEAR ALL',
                  style: AppTextStyles.studioLabel.copyWith(
                    color: AppColors.error,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCompletedSections(List<Task> tasks, bool isDark) {
    final grouped = _groupTasksByDate(tasks);
    final List<Widget> slivers = [];

    grouped.forEach((dateLabel, dateTasks) {
      slivers.add(_buildSectionHeader(dateLabel, isDark ? Colors.white24 : Colors.black26));
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _HistoryItemCard(task: dateTasks[i]),
              ),
              childCount: dateTasks.length,
            ),
          ),
        ),
      );
    });

    return slivers;
  }

  Map<String, List<Task>> _groupTasksByDate(List<Task> tasks) {
    final Map<String, List<Task>> groups = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var task in tasks) {
      final taskDate = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
      String label;
      if (taskDate == today) {
        label = 'TODAY';
      } else if (taskDate == yesterday) {
        label = 'YESTERDAY';
      } else {
        label = 'OLDER';
      }

      groups.putIfAbsent(label, () => []).add(task);
    }
    return groups;
  }

  Widget _buildSectionHeader(String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 24, 16),
        child: Text(
          title,
          style: AppTextStyles.studioLabel.copyWith(
            color: color, 
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined, 
            size: 80, 
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 24),
          Text(
            'CHRONOLOGY IS EMPTY',
            style: AppTextStyles.studioLabel.copyWith(
              color: isDark ? Colors.white12 : Colors.black12,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, TaskProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28), 
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            'Clear History', 
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontSize: 18),
          ),
          content: Text(
            'This will permanently remove all finished operation logs from this view.', 
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'KEEP', 
                style: AppTextStyles.studioLabel.copyWith(color: Colors.white38),
              ),
            ),
            TextButton(
              onPressed: () { 
                provider.clearCompleted(); 
                Navigator.pop(ctx); 
              },
              child: Text(
                'CLEAR', 
                style: AppTextStyles.studioLabel.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveJobCard extends StatelessWidget {
  final Task task;
  const _ActiveJobCard({required this.task});

  String _calculateETA() {
    if (task.progress <= 0 || task.startTime == null) return "Estimating...";
    final elapsed = DateTime.now().difference(task.startTime!).inSeconds;
    if (elapsed < 1) return "Estimating...";
    final totalSec = elapsed / task.progress;
    final remaining = (totalSec - elapsed).toInt();
    if (remaining <= 0) return "Finishing...";
    return "~${remaining}s remaining";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.12),
            blurRadius: 40,
            spreadRadius: -10,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2435).withOpacity(0.8) : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            task.subtext ?? "Processing...",
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontSize: 12,
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${(task.progress * 100).toInt()}%',
                      style: AppTextStyles.displayLarge.copyWith(
                        fontSize: 24,
                        color: AppColors.videoPurple,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Custom Large Progress Bar
                Container(
                  height: 10,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Stack(
                    children: [
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: task.progress.clamp(0.01, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            gradient: const LinearGradient(
                              colors: [AppColors.audioViolet, AppColors.videoPurple],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _calculateETA(),
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 10,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.read<TaskProvider>().cancelTask(task.id),
                      child: Text(
                        'CANCEL',
                        style: AppTextStyles.studioLabel.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.error,
                        ),
                      ),
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

class _HistoryItemCard extends StatelessWidget {
  final Task task;
  const _HistoryItemCard({required this.task});

  String _getTimeAgo() {
    final diff = DateTime.now().difference(task.createdAt);
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    if (diff.inMinutes > 0) return "${diff.inMinutes}m ago";
    return "just now";
  }

  String _getFileSizeDisplay() {
    if (task.fileSize == null) return "";
    final bytes = task.fileSize!.toInt();
    if (bytes < 1024) return "${bytes}B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)}KB";
    return "${(bytes / 1024 / 1024).toStringAsFixed(1)}MB";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSuccess = task.status == TaskStatus.success;
    
    Color iconColor;
    IconData iconData;
    
    switch (task.featureType) {
      case 'extractAudio':
        iconColor = const Color(0xFF10B981); // Green
        iconData = Icons.music_note_rounded;
        break;
      case 'imagesToPdf':
      case 'mergePdf':
      case 'splitPdf':
      case 'greyscalePdf':
        iconColor = AppColors.docIndigo;
        iconData = Icons.description_rounded;
        break;
      case 'convertVideo':
      case 'compressVideo':
        iconColor = AppColors.videoPurple;
        iconData = Icons.movie_rounded;
        break;
      case 'convertImage':
        iconColor = AppColors.imageCyan;
        iconData = Icons.image_rounded;
        break;
      default:
        iconColor = AppColors.greySlate;
        iconData = Icons.insert_drive_file_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: task.status == TaskStatus.failed 
              ? AppColors.error.withOpacity(0.1) 
              : Colors.white.withOpacity(0.02)
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Circular Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${_getTimeAgo()} • ${_getFileSizeDisplay()}",
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 11,
                        color: isDark ? Colors.white24 : Colors.black38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isSuccess && task.status != TaskStatus.cancelled)
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20)
              else if (isSuccess)
                Icon(Icons.check_circle_rounded, color: Colors.white.withOpacity(0.05), size: 18),
            ],
          ),
          if (isSuccess && task.outputPath != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Open',
                    onTap: () => FileService.openFile(task.outputPath!),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _actionButton(
                    label: 'Folder',
                    onTap: () => FileService.showInFolder(task.outputPath!),
                    isDark: isDark,
                  ),
                ),
              ],
            )
          ],
          if (task.status == TaskStatus.failed) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.errorMessage ?? "Operation failed unexpectedly.",
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 11,
                  color: AppColors.error.withOpacity(0.7),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
