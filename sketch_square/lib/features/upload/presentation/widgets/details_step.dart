import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/drawing_form.dart';
import '../../domain/drawing_form_validators.dart';
import '../upload_flow_controller.dart';
import 'form_widgets.dart';

class DetailsStep extends ConsumerWidget {
  const DetailsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(uploadFlowProvider);
    final c = ref.read(uploadFlowProvider.notifier);
    final f = s.form;
    final errors = s.showErrors ? s.detailErrors : const <String, String>{};
    final area = f.plotAreaSqft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        FormTextField(
          key: const ValueKey('field-title'),
          label: 'Title',
          initialText: f.title,
          errorText: errors['title'],
          maxLength: DrawingFormValidators.titleMax,
          textInputAction: TextInputAction.next,
          onChanged: (v) => c.updateForm((f) => f.copyWith(title: v)),
        ),
        const SizedBox(height: 12),
        FormTextField(
          key: const ValueKey('field-description'),
          label: 'Description',
          initialText: f.description,
          errorText: errors['description'],
          maxLines: 5,
          maxLength: DrawingFormValidators.descriptionMax,
          keyboardType: TextInputType.multiline,
          onChanged: (v) => c.updateForm((f) => f.copyWith(description: v)),
        ),
        const SizedBox(height: 12),
        _CategoryField(errorText: errors['category']),
        const SectionTitle('Plot size'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormTextField(
                key: const ValueKey('field-plot-length'),
                label: 'Length',
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
              padding: EdgeInsets.only(top: 16, left: 8, right: 8),
              child: Text('×'),
            ),
            Expanded(
              child: FormTextField(
                key: const ValueKey('field-plot-breadth'),
                label: 'Width',
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
        const SizedBox(height: 8),
        Row(
          children: [
            SegmentedButton<PlotUnit>(
              key: const ValueKey('plot-unit'),
              segments: [
                for (final u in PlotUnit.values)
                  ButtonSegment(value: u, label: Text(u.label)),
              ],
              selected: {f.unit},
              onSelectionChanged:
                  (v) => c.updateForm((f) => f.copyWith(unit: v.first)),
            ),
            const SizedBox(width: 12),
            if (area != null)
              Text(
                '≈ ${area.round()} sq ft',
                key: const ValueKey('plot-area'),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ),
        const SectionTitle('Layout'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: FormTextField(
                key: const ValueKey('field-floors'),
                label: 'Floors',
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
            const SizedBox(width: 12),
            Expanded(
              child: FormTextField(
                key: const ValueKey('field-bedrooms'),
                label: 'Bedrooms (optional)',
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
        const SizedBox(height: 12),
        DropdownButtonFormField<String?>(
          key: const ValueKey('field-facing'),
          value: f.facing,
          decoration: const InputDecoration(
            labelText: 'Facing (optional)',
            border: OutlineInputBorder(),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Not specified')),
            for (final d in facingOptions)
              DropdownMenuItem(value: d, child: Text(d)),
          ],
          onChanged: (v) => c.updateForm((f) => f.copyWith(facing: v)),
        ),
        const SizedBox(height: 12),
        FormTextField(
          key: const ValueKey('field-city'),
          label: 'City',
          initialText: f.city,
          errorText: errors['city'],
          textInputAction: TextInputAction.next,
          onChanged: (v) => c.updateForm((f) => f.copyWith(city: v)),
        ),
        const SectionTitle('Tags'),
        _TagsEditor(
          tags: f.tags,
          errorText: errors['tags'],
          onChanged: (tags) => c.updateForm((f) => f.copyWith(tags: tags)),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  static String _num(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
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
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final cat in s.categories)
          DropdownMenuItem(value: cat.id, child: Text(cat.name)),
      ],
      onChanged: (v) => c.updateForm((f) => f.copyWith(categoryId: v)),
    );
  }
}

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

  void _add() {
    final raw = _controller.text.trim();
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
      _controller.clear();
      setState(() => _error = null);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  labelText: 'Add a tag (e.g. vastu, duplex)',
                  errorText: _error ?? widget.errorText,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: IconButton.filledTonal(
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
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
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
      ],
    );
  }
}
