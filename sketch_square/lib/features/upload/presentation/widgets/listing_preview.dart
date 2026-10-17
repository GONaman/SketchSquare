import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../architects/domain/architect_summary.dart';
import '../../../drawings/domain/drawing_summary.dart';
import '../../../drawings/presentation/drawing_card.dart';
import '../upload_flow_controller.dart';
import 'sheets_step.dart';

/// "How buyers will see it": the real [DrawingCard] fed from the form, using
/// the first image sheet as its cover when one is available locally.
class ListingPreview extends ConsumerWidget {
  const ListingPreview({super.key, this.height = 280, this.width = 200});

  final double height;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final user = ref.watch(currentUserProvider);
    final f = s.form;
    final category =
        s.categories.where((e) => e.id == f.categoryId).firstOrNull;
    final unit = f.unit;
    final cover =
        s.sheets
            .where((i) => isImageSheet(i.name))
            .where((i) => i.isPreview)
            .firstOrNull ??
        s.sheets.where((i) => isImageSheet(i.name)).firstOrNull;
    final coverBytes =
        cover == null
            ? null
            : ref.watch(sheetThumbProvider(sheetThumbKey(cover))).valueOrNull;

    final drawing = DrawingSummary(
      id: 'preview',
      title: f.title.trim().isEmpty ? 'Your drawing title' : f.title.trim(),
      category: CategoryRef(
        id: category?.id ?? '',
        name: category?.name ?? 'Category',
        slug: category?.id ?? '',
      ),
      city: f.city.trim().isEmpty ? 'City' : f.city.trim(),
      plotLengthFt: f.plotLength == null ? 0 : unit.toFeet(f.plotLength!),
      plotBreadthFt: f.plotBreadth == null ? 0 : unit.toFeet(f.plotBreadth!),
      plotAreaSqft: f.plotAreaSqft ?? 0,
      floors: f.floors ?? 1,
      facing: f.facing,
      pricePaise: f.isFree ? 0 : f.pricePaise,
      isFree: f.isFree,
      architect: ArchitectSummary(
        id: user?.id ?? '',
        fullName: user?.fullName ?? 'You',
        city: user?.city ?? '',
      ),
      status: DrawingStatus.draft,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    );

    return Semantics(
      container: true,
      label:
          'Preview of your listing: ${drawing.title}, ${drawing.city}, '
          '${f.isFree ? 'free' : formatPaiseLabel(f.pricePaise)}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: IgnorePointer(
            child: DrawingCard(
              drawing: drawing,
              onTap: () {},
              preview:
                  coverBytes == null
                      ? null
                      : Image.memory(
                        coverBytes,
                        fit: BoxFit.cover,
                        cacheWidth: 480,
                        gaplessPlayback: true,
                        errorBuilder:
                            (_, __, ___) =>
                                const DrawingPreviewImage(url: null),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  static String formatPaiseLabel(int paise) => '₹${paise ~/ 100}';
}

/// A preview with a heading, centred in a tonal "stage".
class ListingPreviewStage extends StatelessWidget {
  const ListingPreviewStage({super.key, this.caption});

  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AppCard(
      style: AppCardStyle.tonal,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    'How buyers will see it',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            if (caption != null) ...[
              const SizedBox(height: 2),
              Text(
                caption!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const ListingPreview(),
          ],
        ),
      ),
    );
  }
}
