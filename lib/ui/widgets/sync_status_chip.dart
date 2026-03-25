import 'package:flutter/material.dart';
import '../../providers/sync_provider.dart';
import '../theme/app_theme.dart';

/// Small status chip shown in the app bar indicating sync status.
class SyncStatusChip extends StatelessWidget {
  final SyncState syncState;

  const SyncStatusChip({super.key, required this.syncState});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _config(syncState.status);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(syncState.status),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (syncState.status == SyncStatus.syncing)
              SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
            Text(
              syncState.pendingCommands > 0
                  ? '$label (${syncState.pendingCommands})'
                  : label,
              style: AppTheme.label.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }

  static (IconData, String, Color) _config(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return (Icons.cloud_done_rounded, 'Synced', AppTheme.priorityLow);
      case SyncStatus.syncing:
        return (Icons.sync_rounded, 'Syncing', AppTheme.priorityMedium);
      case SyncStatus.offline:
        return (Icons.cloud_off_rounded, 'Offline', const Color(0xFF9090B0));
      case SyncStatus.error:
        return (Icons.error_outline_rounded, 'Error', AppTheme.priorityHigh);
    }
  }
}
