import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/sheet_file_rules.dart';
import '../../domain/sheet_upload_target.dart';
import '../upload_flow_controller.dart';
import '../upload_flow_state.dart';
import 'form_widgets.dart';

class SheetsStep extends ConsumerWidget {
  const SheetsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Upload the drawing sheets (PDF, PNG, JPG, DWG or DXF, up to 50 MB '
          'each). Mark 1–${SheetFileRules.maxPreviewSheets} sheets as previews: '
          'buyers see these with a watermark before purchasing. CAD files '
          'cannot be previews.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (final n in s.notices)
          MessageBanner(message: n, onDismiss: c.dismissNotices),
        OutlinedButton.icon(
          key: const ValueKey('pick-sheets'),
          onPressed: c.pickSheets,
          icon: const Icon(Icons.attach_file),
          label: const Text('Add sheets'),
        ),
        const SizedBox(height: 12),
        if (s.sheets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No sheets yet', style: theme.textTheme.bodyMedium),
            ),
          ),
        for (final item in s.sheets)
          SheetTile(key: ValueKey('sheet-${item.localId}'), item: item),
        if (s.showErrors && s.sheetsError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              s.sheetsError!,
              key: const ValueKey('sheets-error'),
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class SheetTile extends ConsumerWidget {
  const SheetTile({super.key, required this.item});

  final SheetItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.read(uploadFlowProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (statusText, statusColor) = switch (item.status) {
      SheetUploadStatus.queued => ('Waiting…', scheme.onSurfaceVariant),
      SheetUploadStatus.uploading => (
        'Uploading ${(item.progress * 100).round()}%',
        scheme.primary,
      ),
      SheetUploadStatus.registering => ('Finishing…', scheme.primary),
      SheetUploadStatus.done => ('Uploaded', scheme.primary),
      SheetUploadStatus.failed => (item.error ?? 'Upload failed', scheme.error),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  item.canBePreview ? Icons.picture_as_pdf : Icons.architecture,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${formatBytes(item.sizeBytes)} · $statusText',
                        key: ValueKey('sheet-status-${item.name}'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.isFailed)
                  TextButton(
                    key: ValueKey('retry-sheet-${item.name}'),
                    onPressed: () => c.retrySheet(item.localId),
                    child: const Text('Retry'),
                  ),
                IconButton(
                  key: ValueKey('remove-sheet-${item.name}'),
                  tooltip: 'Remove ${item.name}',
                  onPressed:
                      item.status == SheetUploadStatus.registering
                          ? null
                          : () => c.removeSheet(item.localId),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (item.status == SheetUploadStatus.uploading ||
                item.status == SheetUploadStatus.registering)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  key: ValueKey('sheet-progress-${item.name}'),
                  value:
                      item.status == SheetUploadStatus.uploading
                          ? item.progress
                          : null,
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButton<SheetType>(
                    key: ValueKey('sheet-type-${item.name}'),
                    value: item.type,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [
                      for (final t in SheetType.values)
                        DropdownMenuItem(value: t, child: Text(t.label)),
                    ],
                    onChanged:
                        item.isDone
                            ? (t) {
                              if (t != null) c.setSheetType(item.localId, t);
                            }
                            : null,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Preview'),
                Switch(
                  key: ValueKey('sheet-preview-${item.name}'),
                  value: item.isPreview,
                  onChanged:
                      item.isDone && item.canBePreview
                          ? (_) => c.togglePreview(item.localId)
                          : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
