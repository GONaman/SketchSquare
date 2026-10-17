import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/status_pill.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../domain/drawing_form.dart';
import '../../domain/drawing_form_validators.dart';
import '../upload_flow_controller.dart';
import 'form_widgets.dart';
import 'plot_sketch.dart';

class DetailsStep extends ConsumerWidget {
  const DetailsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final f = s.form;
    final errors = s.showErrors ? s.detailErrors : const <String, String>{};
    final left = s.detailErrors.length;
    final area = f.plotAreaSqft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StepIntro(
          kicker: 'STEP 1 OF 4',
          title: 'Describe your drawing',
          subtitle:
              'Specific listings get found. Buyers search by plot size, '
              'city and category.',
          trailing:
              left == 0
                  ? const StatusPill(
                    label: 'All set',
                    tone: StatusTone.success,
                    icon: Icons.check,
                  )
                  : StatusPill(label: '$left to go', tone: StatusTone.neutral),
        ),
        FormSection(
          title: 'The basics',
          icon: Icons.edit_note,
          child: Column(
            children: [
              FormTextField(
                key: const ValueKey('field-title'),
                label: 'Title',
                hintText: 'e.g. 30×40 East-facing duplex',
                initialText: f.title,
                errorText: errors['title'],
                maxLength: DrawingFormValidators.titleMax,
                textInputAction: TextInputAction.next,
                onChanged: (v) => c.updateForm((f) => f.copyWith(title: v)),
              ),
              const SizedBox(height: AppSpacing.md),
              FormTextField(
                key: const ValueKey('field-description'),
                label: 'Description',
                hintText: 'Rooms, vastu, structure, what is included…',
                initialText: f.description,
                errorText: errors['description'],
                maxLines: 5,
                maxLength: DrawingFormValidators.descriptionMax,
                keyboardType: TextInputType.multiline,
                onChanged:
                    (v) => c.updateForm((f) => f.copyWith(description: v)),
              ),
              const SizedBox(height: AppSpacing.md),
              _CategoryField(errorText: errors['category']),
            ],
          ),
        ),
        FormSection(
          title: 'Plot size',
          subtitle: 'The number buyers search by',
          icon: Icons.straighten,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormTextField(
                      key: const ValueKey('field-plot-length'),
                      label: 'Length',
                      tabularFigures: true,
                      initialText: _num(f.plotLength),
                      errorText: errors['plotLength'],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [decimalFormatter],
                      onChanged:
                          (v) => c.updateForm(
                            (f) => f.copyWith(plotLength: double.tryParse(v)),
                          ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(
                      top: AppSpacing.lg,
                      left: AppSpacing.sm,
                      right: AppSpacing.sm,
                    ),
                    child: Text('×'),
                  ),
                  Expanded(
                    child: FormTextField(
                      key: const ValueKey('field-plot-breadth'),
                      label: 'Width',
                      tabularFigures: true,
                      initialText: _num(f.plotBreadth),
                      errorText: errors['plotBreadth'],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [decimalFormatter],
                      onChanged:
                          (v) => c.updateForm(
                            (f) => f.copyWith(plotBreadth: double.tryParse(v)),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SegmentedButton<PlotUnit>(
                    key: const ValueKey('plot-unit'),
                    showSelectedIcon: false,
                    segments: [
                      for (final u in PlotUnit.values)
                        ButtonSegment(value: u, label: Text(u.label)),
                    ],
                    selected: {f.unit},
                    onSelectionChanged:
                        (v) => c.updateForm((f) => f.copyWith(unit: v.first)),
                  ),
                  if (area != null)
                    Text(
                      '≈ ${area.round()} sq ft',
                      key: const ValueKey('plot-area'),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PlotSketch(
                length: f.plotLength,
                breadth: f.plotBreadth,
                unitLabel: f.unit.label,
              ),
            ],
          ),
        ),
        FormSection(
          title: 'Layout',
          icon: Icons.home_work_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: FormTextField(
                      key: const ValueKey('field-floors'),
                      label: 'Floors',
                      tabularFigures: true,
                      initialText: f.floors?.toString() ?? '',
                      errorText: errors['floors'],
                      keyboardType: TextInputType.number,
                      inputFormatters: [digitsFormatter],
                      onChanged:
                          (v) => c.updateForm(
                            (f) => f.copyWith(floors: int.tryParse(v)),
                          ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FormTextField(
                      key: const ValueKey('field-bedrooms'),
                      label: 'Bedrooms (optional)',
                      tabularFigures: true,
                      initialText: f.bedrooms?.toString() ?? '',
                      errorText: errors['bedrooms'],
                      keyboardType: TextInputType.number,
                      inputFormatters: [digitsFormatter],
                      onChanged:
                          (v) => c.updateForm(
                            (f) => f.copyWith(bedrooms: int.tryParse(v)),
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _FacingPicker(
                selected: f.facing,
                onChanged: (v) => c.updateForm((f) => f.copyWith(facing: v)),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormTextField(
                key: const ValueKey('field-city'),
                label: 'City',
                prefixIcon: Icons.place_outlined,
                initialText: f.city,
                errorText: errors['city'],
                textInputAction: TextInputAction.next,
                onChanged: (v) => c.updateForm((f) => f.copyWith(city: v)),
              ),
            ],
          ),
        ),
        FormSection(
          title: 'Tags',
          subtitle: 'Optional · up to ${DrawingFormValidators.maxTags}',
          icon: Icons.sell_outlined,
          child: _TagsEditor(
            tags: f.tags,
            errorText: errors['tags'],
            onChanged: (tags) => c.updateForm((f) => f.copyWith(tags: tags)),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  static String _num(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }
}

class _FacingPicker extends StatelessWidget {
  const _FacingPicker({required this.selected, required this.onChanged});

  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Facing', style: theme.textTheme.labelLarge),
        const SizedBox(height: 2),
        Text(
          'Optional · tap again to clear',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        LayoutBuilder(
          builder: (context, box) {
            const gap = AppSpacing.sm;
            final eight = (box.maxWidth - 7 * gap) / 8;
            final chipW = eight >= 52 ? eight : (box.maxWidth - 3 * gap) / 4;
            return Wrap(
              key: const ValueKey('field-facing'),
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final d in facingOptions)
                  SizedBox(
                    width: chipW.floorToDouble(),
                    child: ChoiceChip(
                      label: SizedBox(
                        width: double.infinity,
                        child: Text(d, textAlign: TextAlign.center),
                      ),
                      selected: selected == d,
                      showCheckmark: false,
                      onSelected: (_) => onChanged(selected == d ? null : d),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CategoryField extends ConsumerWidget {
  const _CategoryField({this.errorText});
  final String? errorText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    if (s.categories.isEmpty && s.categoriesError != null) {
      return Row(
        children: [
          Expanded(child: Text(s.categoriesError!)),
          TextButton(
            key: const ValueKey('retry-categories'),
            onPressed: c.loadCategories,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    final selected =
        s.categories.any((e) => e.id == s.form.categoryId)
            ? s.form.categoryId
            : null;
    return DropdownButtonFormField<String>(
      key: const ValueKey('field-category'),
      value: selected,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: s.categories.isEmpty ? 'Loading categories…' : 'Category',
        errorText: errorText,
      ),
      items: [
        for (final cat in s.categories)
          DropdownMenuItem(value: cat.id, child: Text(cat.name)),
      ],
      onChanged: (v) => c.updateForm((f) => f.copyWith(categoryId: v)),
    );
  }
}

const _suggestedTags = ['vastu', 'duplex', 'east-facing', 'parking', 'modern'];

class _TagsEditor extends StatefulWidget {
  const _TagsEditor({
    required this.tags,
    required this.onChanged,
    this.errorText,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final String? errorText;

  @override
  State<_TagsEditor> createState() => _TagsEditorState();
}

class _TagsEditorState extends State<_TagsEditor> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add([String? preset]) {
    final raw = (preset ?? _controller.text).trim();
    if (raw.isEmpty) return;
    final problem = DrawingFormValidators.tag(raw);
    final duplicate = widget.tags.any(
      (t) => t.toLowerCase() == raw.toLowerCase(),
    );
    if (problem != null) {
      setState(() => _error = problem);
    } else if (widget.tags.length >= DrawingFormValidators.maxTags) {
      setState(() => _error = 'At most ${DrawingFormValidators.maxTags} tags');
    } else if (duplicate) {
      setState(() => _error = 'Tag already added');
    } else {
      widget.onChanged([...widget.tags, raw]);
      if (preset == null) _controller.clear();
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      for (final t in _suggestedTags)
        if (!widget.tags.any((x) => x.toLowerCase() == t)) t,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('field-tag'),
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: InputDecoration(
                  labelText: 'Add a tag',
                  hintText: 'e.g. vastu, duplex',
                  errorText: _error ?? widget.errorText,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: IconButton.filledTonal(
                style: IconButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                key: const ValueKey('add-tag'),
                tooltip: 'Add tag',
                onPressed: _add,
                icon: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        if (widget.tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in widget.tags)
                  InputChip(
                    label: Text(t),
                    onDeleted:
                        () => widget.onChanged([
                          for (final x in widget.tags)
                            if (x != t) x,
                        ]),
                  ),
              ],
            ),
          ),
        if (suggestions.isNotEmpty &&
            widget.tags.length < DrawingFormValidators.maxTags)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Suggested',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                for (final t in suggestions)
                  ActionChip(
                    key: ValueKey('suggest-$t'),
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text(t),
                    onPressed: () => _add(t),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
