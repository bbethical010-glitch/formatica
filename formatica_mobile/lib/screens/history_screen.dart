import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
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
    return MeshBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Consumer<TaskProvider>(
            builder: (ctx, provider, _) {
              final active = provider.activeTasks;
              final completed = provider.completedTasks;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(context, provider, completed.isNotEmpty),
                  
                  if (active.isEmpty && completed.isEmpty)
                    _buildEmptyState(context),

                  if (active.isNotEmpty) ...[
                    _buildSectionHeader('SEQUENCES IN FLIGHT', AppColors.primaryIndigo),
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
                    _buildSectionHeader('ARCHIVED LOGS', Colors.white.withOpacity(0.4)),
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

  Widget _buildHeader(BuildContext context, TaskProvider provider, bool hasCompleted) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chronology',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w300,
                    fontSize: 32,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'SYSTEM ACTIVITY LOGS',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (hasCompleted)
              _headerActionButton(
                label: 'PURGE',
                onTap: () => _confirmClear(context, provider),
                color: AppColors.audioRose,
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerActionButton({required String label, required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          color: color.withOpacity(0.05),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 48, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 24),
            Text(
              'EMPTY VOID',
              style: GoogleFonts.outfit(
                color: Colors.white.withOpacity(0.2),
                letterSpacing: 3,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Text('Data Purge', style: GoogleFonts.outfit(color: Colors.white)),
          content: Text('Permanently remove all archived operation logs?', style: GoogleFonts.outfit(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('RETAIN', style: GoogleFonts.outfit(color: Colors.white30))),
            TextButton(
              onPressed: () { provider.clearCompleted(); Navigator.pop(ctx); },
              child: Text('PURGE', style: GoogleFonts.outfit(color: AppColors.audioRose)),
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
    final isRunning = task.status == TaskStatus.running;
    final statusColor = isRunning ? AppColors.primaryIndigo : AppColors.compressOrange;

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(20),
      blur: 20,
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
                Icon(Icons.schedule, size: 14, color: statusColor),
              ],
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isRunning ? '${(task.progress * 100).toInt()}%' : 'QUEUED',
                style: GoogleFonts.outfit(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (isRunning) ...[
            const SizedBox(height: 16),
            Container(
              height: 2,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: task.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(1),
                    boxShadow: [
                      BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: _taskAction(
              label: 'TERMINATE',
              icon: Icons.stop_rounded,
              color: AppColors.audioRose,
              onTap: () => _confirmCancel(context, task.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: color,
              ),
            ),
          ],
        ),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white.withOpacity(0.1))),
          title: Text('Sequence Break', style: GoogleFonts.outfit(color: Colors.white)),
          content: Text('Abort this active processing sequence?', style: GoogleFonts.outfit(color: Colors.white70)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('REMAIN', style: GoogleFonts.outfit(color: Colors.white30))),
            TextButton(
              onPressed: () {
                final provider = Provider.of<TaskProvider>(context, listen: false);
                provider.cancelTask(taskId);
                Navigator.pop(ctx);
              },
              child: Text('ABORT', style: GoogleFonts.outfit(color: AppColors.audioRose)),
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
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (task.status) {
      case TaskStatus.success:
        statusColor = AppColors.imageCyan;
        statusIcon = Icons.check_circle_outline_rounded;
        statusLabel = 'RESOLVED';
        break;
      case TaskStatus.failed:
        statusColor = AppColors.audioRose;
        statusIcon = Icons.error_outline_rounded;
        statusLabel = 'FAILED';
        break;
      default:
        statusColor = Colors.white24;
        statusIcon = Icons.cancel_outlined;
        statusLabel = 'VOID';
    }

    return LiquidGlassContainer(
      padding: const EdgeInsets.all(18),
      blur: 10,
      color: Colors.white.withOpacity(0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.label.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                statusLabel,
                style: GoogleFonts.outfit(
                  color: statusColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          if (task.status == TaskStatus.failed && task.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              task.errorMessage!,
              style: GoogleFonts.outfit(color: AppColors.audioRose.withOpacity(0.7), fontSize: 11),
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
                const SizedBox(width: 12),
                _miniAction(
                  label: 'PATH',
                  icon: Icons.folder_open_rounded,
                  color: AppColors.primaryIndigo,
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
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: color.withOpacity(0.8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}








