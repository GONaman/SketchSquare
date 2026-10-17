import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/sheet_file_rules.dart';
import '../../domain/sheet_upload_target.dart';
import '../upload_flow_controller.dart';
import '../upload_flow_state.dart';
import 'form_widgets.dart';

const _maxThumbBytes = 8 * 1024 * 1024;

/// Bytes of a locally picked image sheet, for its thumbnail. Null for PDFs,
/// CAD files, restored drafts or files too large to decode cheaply.
final sheetThumbProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  key,
) async {
  final localId = key.split('|').first;
  final item =
      ref
          .read(uploadFlowProvider)
          .sheets
          .where((s) => s.localId == localId)
          .firstOrNull;
  final file = item?.file;
  if (item == null || file == null || !isImageSheet(item.name)) return null;
  if (item.sizeBytes > _maxThumbBytes) return null;
  try {
    final chunks = await file.openRead().toList();
    return Uint8List.fromList([for (final c in chunks) ...c]);
  } catch (_) {
    return null;
  }
});

bool isImageSheet(String name) =>
    const {'png', 'jpg', 'jpeg'}.contains(SheetFileRules.extensionOf(name));

String sheetThumbKey(SheetItem i) => '${i.localId}|${i.name}|${i.sizeBytes}';

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
        StepIntro(
          kicker: 'STEP 2 OF 4',
          title: 'Add your sheets',
          subtitle:
              'Plans, elevations, structural and services drawings. Buyers '
              'get every sheet after purchase.',
        ),
        for (final n in s.notices)
          MessageBanner(message: n, onDismiss: c.dismissNotices),
        _DropZone(compact: s.sheets.isNotEmpty, onTap: c.pickSheets),
        if (s.sheets.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _PreviewMeter(count: s.previewCount),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final item in s.sheets)
          SheetTile(key: ValueKey('sheet-${item.localId}'), item: item),
        if (s.showErrors && s.sheetsError != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    s.sheetsError!,
                    key: const ValueKey('sheets-error'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Large dashed target to add files (drag-and-drop styled; tap opens the picker).
class _DropZone extends StatelessWidget {
  const _DropZone({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final icon = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.lg),
        child: Icon(
          compact ? Icons.add : Icons.upload_file_outlined,
          size: compact ? 20 : 30,
          color: scheme.onPrimaryContainer,
        ),
      ),
    );
    return Semantics(
      button: true,
      label: 'Add sheets',
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: scheme.primary.withValues(alpha: 0.55),
          radius: AppRadius.lg,
        ),
        child: Material(
          key: const ValueKey('pick-sheets'),
          color: scheme.primaryContainer.withValues(alpha: 0.28),
          borderRadius: AppRadius.cardRadius,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.cardRadius,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: compact ? AppSpacing.md : AppSpacing.xl,
              ),
              child:
                  compact
                      ? Row(
                        children: [
                          icon,
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Add more sheets',
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ],
                      )
                      : SizedBox(
                        width: double.infinity,
                        child: Column(
                          children: [
                            icon,
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No sheets yet',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Tap to choose files',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'PDF, PNG, JPG, DWG or DXF · up to 50 MB each',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()..addRRect(
          RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
        );
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

/// "1 of 2 previews chosen" with the reason previews matter.
class _PreviewMeter extends StatelessWidget {
  const _PreviewMeter({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = SheetFileRules.maxPreviewSheets;
    final ok = count >= 1 && count <= max;
    return Semantics(
      container: true,
      label: '$count of $max preview sheets chosen',
      child: AppCard(
        style: AppCardStyle.tonal,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ExcludeSemantics(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                ok ? Icons.visibility : Icons.visibility_outlined,
                size: 20,
                color: ok ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Previews  $count of $max',
                      style: theme.textTheme.titleSmall?.tabular,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose 1–$max sheets buyers can see, watermarked, '
                      'before they buy. CAD files cannot be previews.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SheetThumb(item: item),
                const SizedBox(width: AppSpacing.md),
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
                      const SizedBox(height: 2),
                      Text(
                        '${formatBytes(item.sizeBytes)} · $statusText',
                        key: ValueKey('sheet-status-${item.name}'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                        ),
                      ),
                      if (item.isFailed)
                        TextButton(
                          key: ValueKey('retry-sheet-${item.name}'),
                          onPressed: () => c.retrySheet(item.localId),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
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
            const SizedBox(height: AppSpacing.md),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButton<SheetType>(
                        key: ValueKey('sheet-type-${item.name}'),
                        value: item.type,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        items: [
                          for (final t in SheetType.values)
                            DropdownMenuItem(value: t, child: Text(t.label)),
                        ],
                        onChanged:
                            item.isDone
                                ? (t) {
                                  if (t != null) {
                                    c.setSheetType(item.localId, t);
                                  }
                                }
                                : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Preview', style: theme.textTheme.labelLarge),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square thumbnail: the image itself for PNG/JPG, a typed tile otherwise,
/// with a progress ring while it uploads and a status badge afterwards.
class SheetThumb extends ConsumerWidget {
  const SheetThumb({super.key, required this.item});

  final SheetItem item;

  static const size = 64.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final ext = SheetFileRules.extensionOf(item.name).toUpperCase();
    final bytes =
        isImageSheet(item.name)
            ? ref.watch(sheetThumbProvider(sheetThumbKey(item))).valueOrNull
            : null;

    final base =
        bytes != null
            ? Image.memory(
              bytes,
              fit: BoxFit.cover,
              cacheWidth: 192,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => _TypeTile(ext: ext, item: item),
            )
            : _TypeTile(ext: ext, item: item);

    final busy =
        item.status == SheetUploadStatus.uploading ||
        item.status == SheetUploadStatus.registering ||
        item.status == SheetUploadStatus.queued;

    return ExcludeSemantics(
      excluding: !busy,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: base,
              ),
            ),
            if (busy)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: ColoredBox(
                  color: scheme.scrim.withValues(alpha: 0.45),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 38,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            key: ValueKey('sheet-progress-${item.name}'),
                            value:
                                item.status == SheetUploadStatus.uploading
                                    ? item.progress
                                    : (item.status == SheetUploadStatus.queued
                                        ? 0
                                        : null),
                            strokeWidth: 3.5,
                            strokeCap: StrokeCap.round,
                            color: Colors.white,
                            backgroundColor: Colors.white24,
                            semanticsLabel: 'Uploading ${item.name}',
                          ),
                          if (item.status == SheetUploadStatus.uploading)
                            Text(
                              '${(item.progress * 100).round()}',
                              style:
                                  Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(color: Colors.white)
                                      .tabular,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (item.isDone || item.isFailed)
              Positioned(
                right: -4,
                bottom: -4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: item.isDone ? scheme.primary : scheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.surfaceContainerLowest,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Icon(
                      item.isDone ? Icons.check : Icons.priority_high,
                      size: 12,
                      color: item.isDone ? scheme.onPrimary : scheme.onError,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.ext, required this.item});

  final String ext;
  final SheetItem item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final icon = switch (ext) {
      'PDF' => Icons.picture_as_pdf_outlined,
      'DWG' || 'DXF' => Icons.architecture,
      _ => Icons.image_outlined,
    };
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: scheme.onPrimaryContainer),
          const SizedBox(height: 2),
          Text(
            ext,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
