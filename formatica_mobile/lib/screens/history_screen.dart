import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../core/theme.dart';
import '../models/task.dart';
import '../models/task_status.dart';
import '../providers/task_provider.dart';
import '../services/file_service.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/top_bar.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: StudioTopBar(
          title: 'Chronology',
          trailing: Consumer<TaskProvider>(
            builder: (context, provider, _) {
              if (provider.completedTasks.isEmpty) return const SizedBox.shrink();
              return GestureDetector(
                onTap: () => _confirmClear(context, provider),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.audioRose.withOpacity(0.1),
                  ),
                  child: Text(
                    'PURGE',
                    style: AppTextStyles.studioLabel.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.audioRose,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        body: SafeArea(
          child: Consumer<TaskProvider>(
            builder: (ctx, provider, _) {
              final active = provider.activeTasks;
              final completed = provider.completedTasks;

              if (active.isEmpty && completed.isEmpty) {
                return _buildEmptyState(context, isDark);
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  if (active.isNotEmpty) ...[
                    _buildSectionHeader('SEQUENCES IN FLIGHT', AppColors.docIndigo),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ActiveTaskCard(task: active[i]),
                          ),
                          childCount: active.length,
                        ),
                      ),
                    ),
                  ],

                  if (completed.isNotEmpty) ...[
                    _buildSectionHeader('ARCHIVED LOGS', isDark ? Colors.white24 : Colors.black26),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CompletedTaskCard(task: completed[i]),
                          ),
                          childCount: completed.length,
                        ),
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              );
            },
          ),
        ),
      ),
    );
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
            fontWeight: FontWeight.bold,
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
            size: 64, 
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
          const SizedBox(height: 24),
          Text(
            'CHRONOLOGY IS EMPTY',
            style: AppTextStyles.studioLabel.copyWith(
              color: isDark ? Colors.white12 : Colors.black12,
              letterSpacing: 3,
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), 
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            'Data Purge', 
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontSize: 18),
          ),
          content: Text(
            'Permanently remove all archived operation logs?', 
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'RETAIN', 
                style: AppTextStyles.studioLabel.copyWith(color: Colors.white30),
              ),
            ),
            TextButton(
              onPressed: () { 
                provider.clearCompleted(); 
                Navigator.pop(ctx); 
              },
              child: Text(
                'PURGE', 
                style: AppTextStyles.studioLabel.copyWith(color: AppColors.audioRose),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTaskCard extends StatelessWidget {
  final Task task;
  const _ActiveTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRunning = task.status == TaskStatus.running;
    final statusColor = isRunning ? AppColors.docIndigo : AppColors.compressOrange;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 24,
      color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isRunning) ...[
                SizedBox(
                  width: 14, height: 14,
                  child: CircularProgressIndicator(
                    value: task.progress,
                    strokeWidth: 2,
                    color: statusColor,
                    backgroundColor: statusColor.withOpacity(0.1),
                  ),
                ),
              ] else ...[
                Icon(Icons.schedule_rounded, size: 14, color: statusColor),
              ],
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  task.label.toUpperCase(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isRunning ? '${(task.progress * 100).toInt()}%' : 'QUEUED',
                style: AppTextStyles.studioLabel.copyWith(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (isRunning) ...[
            const SizedBox(height: 16),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: task.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 6),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => _confirmCancel(context, task.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.audioRose.withOpacity(0.1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stop_rounded, size: 12, color: AppColors.audioRose),
                    const SizedBox(width: 4),
                    Text(
                      'TERMINATE',
                      style: AppTextStyles.studioLabel.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.audioRose,
                      ),
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

  void _confirmCancel(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), 
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: Text(
            'Sequence Break', 
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, fontSize: 18),
          ),
          content: Text(
            'Abort this active processing sequence?', 
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'REMAIN', 
                style: AppTextStyles.studioLabel.copyWith(color: Colors.white30),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<TaskProvider>().cancelTask(taskId);
                Navigator.pop(ctx);
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

class _CompletedTaskCard extends StatelessWidget {
  final Task task;
  const _CompletedTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.success:
        statusColor = AppColors.imageCyan;
        statusIcon = Icons.check_circle_rounded;
        statusLabel = 'RESOLVED';
        break;
      case TaskStatus.failed:
        statusColor = AppColors.audioRose;
        statusIcon = Icons.error_rounded;
        statusLabel = 'FAILED';
        break;
      default:
        statusColor = isDark ? Colors.white24 : Colors.black26;
        statusIcon = Icons.cancel_rounded;
        statusLabel = 'VOID';
    }

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(18),
      blur: 16,
      color: isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.label.toUpperCase(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.85) : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                statusLabel,
                style: AppTextStyles.studioLabel.copyWith(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (task.status == TaskStatus.failed && task.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              task.errorMessage!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.audioRose.withOpacity(0.7), 
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (task.status == TaskStatus.success && task.outputPath != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _miniAction(
                  label: 'OPEN',
                  icon: Icons.open_in_new_rounded,
                  color: AppColors.imageCyan,
                  onTap: () => FileService.openFile(task.outputPath!),
                ),
                const SizedBox(width: 10),
                _miniAction(
                  label: 'VAULT',
                  icon: Icons.folder_open_rounded,
                  color: AppColors.docIndigo,
                  onTap: () => FileService.showInFolder(task.outputPath!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.studioLabel.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
