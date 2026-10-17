import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/upload/domain/contribution_status.dart';
import 'package:sketch_square/features/upload/domain/draft_store.dart';
import 'package:sketch_square/features/upload/domain/drawing_form.dart';
import 'package:sketch_square/features/upload/domain/drawing_record.dart';
import 'package:sketch_square/features/upload/domain/sheet_upload_target.dart';
import 'package:sketch_square/features/upload/domain/upload_repository.dart';

const houses = CategoryRef(id: 'cat-1', name: 'Houses', slug: 'houses');

DrawingForm validForm({bool isFree = true}) => DrawingForm(
  title: 'Modern 30x40 duplex',
  description: 'A two floor duplex with a central courtyard and parking.',
  categoryId: houses.id,
  city: 'Bengaluru',
  plotLength: 40,
  plotBreadth: 30,
  floors: 2,
  isFree: isFree,
  pricePaise: isFree ? 0 : 49900,
);

PickedSheetFile file(String name, {int size = 1000}) => PickedSheetFile(
  name: name,
  sizeBytes: size,
  openRead: () => Stream.value(List.filled(size, 0)),
);

ApiException apiError(String code, [String message = 'boom']) =>
    ApiException(code: code, message: message, statusCode: 400);

class FakeUploadRepository implements UploadRepository {
  final calls = <String>[];
  final Map<String, DrawingRecord> drawings = {};
  final Map<String, List<Sheet>> sheets = {};
  int _seq = 0;

  /// Errors to throw for the next call of a method (consumed in order).
  final Map<String, List<ApiException>> failures = {};

  /// Statuses returned by successive `getDrawing` calls after publishing.
  final List<DrawingStatus> pollStatuses = [];
  String? failureReason;
  DrawingStatus publishStatus = DrawingStatus.processing;

  void failNext(String method, ApiException e, {int times = 1}) =>
      failures.putIfAbsent(method, () => []).addAll(List.filled(times, e));

  void _maybeFail(String method) {
    calls.add(method);
    final q = failures[method];
    if (q != null && q.isNotEmpty) throw q.removeAt(0);
  }

  int count(String method) => calls.where((c) => c == method).length;

  DrawingRecord _record(String id, DrawingForm f, DrawingStatus status) =>
      DrawingRecord(
        id: id,
        title: f.title,
        description: f.description,
        category: houses,
        city: f.city,
        plotLengthFt: f.unit.toFeet(f.plotLength ?? 0),
        plotBreadthFt: f.unit.toFeet(f.plotBreadth ?? 0),
        floors: f.floors ?? 1,
        isFree: f.isFree,
        pricePaise: f.pricePaise,
        status: status,
        failureReason: failureReason,
        sheets: sheets[id] ?? const [],
      );

  @override
  Future<List<CategoryRef>> fetchCategories() async {
    _maybeFail('fetchCategories');
    return const [houses];
  }

  @override
  Future<DrawingRecord> createDraft(DrawingForm form) async {
    _maybeFail('createDraft');
    final id = 'd${++_seq}';
    return drawings[id] = _record(id, form, DrawingStatus.draft);
  }

  @override
  Future<DrawingRecord> updateDraft(String id, DrawingForm form) async {
    _maybeFail('updateDraft');
    return drawings[id] = _record(id, form, drawings[id]!.status);
  }

  @override
  Future<DrawingRecord> getDrawing(String id) async {
    _maybeFail('getDrawing');
    final current = drawings[id];
    if (current == null) throw apiError(ApiErrorCodes.notFound, 'not found');
    if (pollStatuses.isNotEmpty) {
      final next = pollStatuses.removeAt(0);
      drawings[id] = current.copyWith(
        status: next,
        failureReason: next == DrawingStatus.failed ? failureReason : null,
        sheets: sheets[id] ?? const [],
      );
    }
    return drawings[id]!.copyWith(sheets: sheets[id] ?? const []);
  }

  @override
  Future<SheetUploadTarget> requestSheetUpload(
    String drawingId, {
    required String fileName,
    required String contentType,
    required int sizeBytes,
  }) async {
    _maybeFail('requestSheetUpload');
    return SheetUploadTarget(
      uploadUrl: 'http://storage/$fileName',
      objectKey: 'key/$fileName',
      headers: {'Content-Type': contentType},
    );
  }

  @override
  Future<Sheet> registerSheet(
    String drawingId, {
    required SheetType type,
    required String objectKey,
    required bool isPreview,
    required String fileName,
    required int sizeBytes,
  }) async {
    _maybeFail('registerSheet');
    final sheet = Sheet(
      id: 's${++_seq}',
      type: type,
      isPreview: isPreview,
      originalMime: 'application/pdf',
      fileName: fileName,
      sizeBytes: sizeBytes,
    );
    sheets.putIfAbsent(drawingId, () => []).add(sheet);
    return sheet;
  }

  @override
  Future<Sheet> updateSheet(
    String drawingId,
    String sheetId, {
    SheetType? type,
    bool? isPreview,
  }) async {
    _maybeFail('updateSheet');
    final list = sheets[drawingId]!;
    final i = list.indexWhere((s) => s.id == sheetId);
    return list[i] = list[i].copyWith(
      type: type ?? list[i].type,
      isPreview: isPreview ?? list[i].isPreview,
    );
  }

  @override
  Future<void> deleteSheet(String drawingId, String sheetId) async {
    _maybeFail('deleteSheet');
    sheets[drawingId]!.removeWhere((s) => s.id == sheetId);
  }

  ContributionStatus contribution = const ContributionStatus();

  @override
  Future<ContributionStatus> fetchContributionStatus() async {
    _maybeFail('fetchContributionStatus');
    return contribution;
  }

  @override
  Future<DrawingStatus> publish(String drawingId) async {
    _maybeFail('publish');
    drawings[drawingId] = drawings[drawingId]!.copyWith(status: publishStatus);
    return publishStatus;
  }
}

class FakeSheetUploader implements SheetUploader {
  final uploaded = <String>[];
  final headersSeen = <Map<String, String>>[];
  final failures = <ApiException>[];

  /// When set, uploads pause after reporting 50% until it completes.
  Completer<void>? hold;

  @override
  Future<void> upload(
    SheetUploadTarget target,
    PickedSheetFile file, {
    required void Function(int sent, int total) onProgress,
    CancelToken? cancelToken,
  }) async {
    if (failures.isNotEmpty) throw failures.removeAt(0);
    headersSeen.add(target.headers);
    onProgress(file.sizeBytes ~/ 2, file.sizeBytes);
    if (hold != null) await hold!.future;
    if (cancelToken?.isCancelled ?? false) {
      throw apiError(ApiErrorCodes.cancelled, 'cancelled');
    }
    onProgress(file.sizeBytes, file.sizeBytes);
    uploaded.add(file.name);
  }
}

class FakeSheetPicker implements SheetPicker {
  List<PickedSheetFile> next = [];

  @override
  Future<List<PickedSheetFile>> pickSheets() async => next;
}

class InMemoryDraftStore implements DraftStore {
  StoredDraft? stored;

  @override
  Future<StoredDraft?> load() async => stored;

  @override
  Future<void> save(StoredDraft draft) async => stored = draft;

  @override
  Future<void> clear() async => stored = null;
}
