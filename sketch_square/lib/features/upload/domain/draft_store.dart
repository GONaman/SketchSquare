import 'drawing_form.dart';

/// What survives an app restart: the id of the server-side draft (if one was
/// created), the form fields and the step the seller was on.
class StoredDraft {
  const StoredDraft({this.draftId, required this.form, this.stepIndex = 0});

  final String? draftId;
  final DrawingForm form;
  final int stepIndex;

  Map<String, dynamic> toJson() => {
    'draftId': draftId,
    'form': form.toJson(),
    'stepIndex': stepIndex,
  };

  factory StoredDraft.fromJson(Map<String, dynamic> json) => StoredDraft(
    draftId: json['draftId'] as String?,
    form: DrawingForm.fromJson(json['form'] as Map<String, dynamic>),
    stepIndex: json['stepIndex'] as int? ?? 0,
  );
}

abstract interface class DraftStore {
  Future<StoredDraft?> load();
  Future<void> save(StoredDraft draft);
  Future<void> clear();
}
