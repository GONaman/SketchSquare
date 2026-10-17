import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/error_retry.dart';
import '../../upload/domain/drawing_form_validators.dart';
import '../../upload/domain/money.dart';
import '../../upload/domain/drawing_record.dart';
import '../../upload/presentation/widgets/form_widgets.dart';
import '../domain/manage_drawings_repository.dart';

typedef SavePublished =
    Future<void> Function(String title, String description, int pricePaise);

/// Bottom sheet to edit what the contract allows on a published drawing:
/// title, description and (for paid drawings) the price.
class EditPublishedSheet extends StatefulWidget {
  const EditPublishedSheet({
    super.key,
    required this.drawingId,
    required this.repository,
    required this.onSave,
  });

  final String drawingId;
  final ManageDrawingsRepository repository;
  final SavePublished onSave;

  @override
  State<EditPublishedSheet> createState() => _EditPublishedSheetState();
}

class _EditPublishedSheetState extends State<EditPublishedSheet> {
  DrawingRecord? _record;
  String? _loadError;
  String? _saveError;
  bool _saving = false;
  bool _showErrors = false;
  String _title = '';
  String _description = '';
  int _pricePaise = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loadError = null);
    try {
      final r = await widget.repository.fetch(widget.drawingId);
      if (!mounted) return;
      setState(() {
        _record = r;
        _title = r.title;
        _description = r.description;
        _pricePaise = r.pricePaise;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = toApiException(e).message);
    }
  }

  Map<String, String> get _errors => {
    if (DrawingFormValidators.title(_title) case final e?) 'title': e,
    if (DrawingFormValidators.description(_description) case final e?)
      'description': e,
    if (_record?.isFree == false)
      if (DrawingFormValidators.price(false, _pricePaise) case final e?)
        'price': e,
  };

  Future<void> _save() async {
    if (_errors.isNotEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      await widget.onSave(_title, _description, _pricePaise);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = toApiException(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _record;
    final errors = _showErrors ? _errors : const <String, String>{};
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit drawing', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_loadError != null)
              ErrorRetry(message: _loadError!, onRetry: _load)
            else if (record == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              FormTextField(
                key: const ValueKey('edit-title'),
                label: 'Title',
                initialText: record.title,
                errorText: errors['title'],
                maxLength: DrawingFormValidators.titleMax,
                onChanged: (v) => setState(() => _title = v),
              ),
              const SizedBox(height: 12),
              FormTextField(
                key: const ValueKey('edit-description'),
                label: 'Description',
                initialText: record.description,
                errorText: errors['description'],
                maxLines: 4,
                maxLength: DrawingFormValidators.descriptionMax,
                keyboardType: TextInputType.multiline,
                onChanged: (v) => setState(() => _description = v),
              ),
              const SizedBox(height: 12),
              if (record.isFree)
                const Text('This drawing is free; its price cannot be changed.')
              else ...[
                FormTextField(
                  key: const ValueKey('edit-price'),
                  label: 'Price',
                  prefixText: '₹ ',
                  initialText: paiseToInput(record.pricePaise),
                  errorText: errors['price'],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [decimalFormatter],
                  onChanged:
                      (v) => setState(
                        () => _pricePaise = parseRupeesToPaise(v) ?? 0,
                      ),
                ),
                if (_pricePaise >= 100)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'You receive ${formatPaise(sellerNetPaise(_pricePaise))} '
                      'after the platform fee.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                MessageBanner(message: _saveError!),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('edit-save'),
                    onPressed: _saving ? null : _save,
                    child:
                        _saving
                            ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Save'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
