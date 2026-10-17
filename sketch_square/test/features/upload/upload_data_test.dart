import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/upload/data/dio_sheet_uploader.dart';
import 'package:sketch_square/features/upload/data/dio_upload_repository.dart';
import 'package:sketch_square/features/upload/domain/drawing_form.dart';
import 'package:sketch_square/features/upload/domain/sheet_upload_target.dart';
import 'package:sketch_square/features/upload/domain/upload_repository.dart';

const drawingJson = {
  'id': 'd1',
  'title': 'Modern duplex',
  'description': 'desc',
  'category': {'id': 'c1', 'name': 'Houses', 'slug': 'houses'},
  'city': 'Bengaluru',
  'plotLengthFt': 40.0,
  'plotBreadthFt': 30,
  'plotAreaSqft': 1200,
  'floors': 2,
  'pricePaise': 0,
  'isFree': true,
  'status': 'DRAFT',
  'failureReason': null,
  'sheets': [
    {
      'id': 's1',
      'type': 'STRUCTURAL',
      'isPreview': true,
      'previewUrl': null,
      'originalMime': 'application/pdf',
      'fileName': 'plan.pdf',
      'sizeBytes': 1000,
    },
  ],
};

void main() {
  late Dio dio;
  late DioAdapter adapter;
  late DioUploadRepository repo;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = DioAdapter(dio: dio);
    repo = DioUploadRepository(dio);
  });

  group('DioUploadRepository', () {
    test('fetchCategories parses the list', () async {
      adapter.onGet(
        '/categories',
        (s) => s.reply(200, [
          {'id': 'c1', 'name': 'Houses', 'slug': 'houses'},
        ]),
      );
      final cats = await repo.fetchCategories();
      expect(cats.single.name, 'Houses');
    });

    test('fetchContributionStatus parses the contract shape', () async {
      adapter.onGet(
        '/me/contribution-status',
        (s) => s.reply(200, {
          'freePublished': 0,
          'paidPublished': 1,
          'paidPending': 0,
          'freePerPaid': 1,
          'freeNeeded': 1,
          'canPublishPaid': false,
          'guidance': 'Publish a free drawing first.',
        }),
      );
      final status = await repo.fetchContributionStatus();
      expect(status.canPublishPaid, isFalse);
      expect(status.freeNeeded, 1);
      expect(status.ruleActive, isTrue);
      expect(status.explanation, 'Publish a free drawing first.');
    });

    test('createDraft posts the form and parses DrawingDetail', () async {
      const form = DrawingForm(
        title: 'Modern duplex',
        description: 'desc',
        categoryId: 'c1',
        city: 'Bengaluru',
        plotLength: 40,
        plotBreadth: 30,
        floors: 2,
        isFree: true,
      );
      adapter.onPost(
        '/drawings',
        (s) => s.reply(201, drawingJson),
        data: form.toRequestJson(),
      );
      final rec = await repo.createDraft(form);
      expect(rec.id, 'd1');
      expect(rec.status, DrawingStatus.draft);
      expect(rec.sheets.single.type, SheetType.structural);
      expect(rec.plotBreadthFt, 30);
    });

    test('updateDraft patches the drawing', () async {
      adapter.onPatch(
        '/drawings/d1',
        (s) => s.reply(200, drawingJson),
        data: const DrawingForm().toRequestJson(),
      );
      final rec = await repo.updateDraft('d1', const DrawingForm());
      expect(rec.title, 'Modern duplex');
    });

    test('requestSheetUpload sends file metadata and parses headers', () async {
      adapter.onPost(
        '/drawings/d1/sheets/upload-url',
        (s) => s.reply(200, {
          'uploadUrl': 'http://minio/put',
          'objectKey': 'k1',
          'headers': {'Content-Type': 'application/pdf'},
        }),
        data: {
          'fileName': 'plan.pdf',
          'contentType': 'application/pdf',
          'sizeBytes': 1000,
        },
      );
      final t = await repo.requestSheetUpload(
        'd1',
        fileName: 'plan.pdf',
        contentType: 'application/pdf',
        sizeBytes: 1000,
      );
      expect(t.objectKey, 'k1');
      expect(t.headers['Content-Type'], 'application/pdf');
    });

    test('registerSheet / updateSheet / deleteSheet', () async {
      final sheet = (drawingJson['sheets']! as List).first;
      adapter
        ..onPost(
          '/drawings/d1/sheets',
          (s) => s.reply(201, sheet),
          data: {
            'type': 'STRUCTURAL',
            'objectKey': 'k1',
            'isPreview': true,
            'fileName': 'plan.pdf',
            'sizeBytes': 1000,
          },
        )
        ..onPatch(
          '/drawings/d1/sheets/s1',
          (s) => s.reply(200, sheet),
          data: {'isPreview': true},
        )
        ..onDelete('/drawings/d1/sheets/s1', (s) => s.reply(204, null));

      final created = await repo.registerSheet(
        'd1',
        type: SheetType.structural,
        objectKey: 'k1',
        isPreview: true,
        fileName: 'plan.pdf',
        sizeBytes: 1000,
      );
      expect(created.id, 's1');
      await repo.updateSheet('d1', 's1', isPreview: true);
      await repo.deleteSheet('d1', 's1');
    });

    test('publish returns the status from the 202 body', () async {
      adapter.onPost(
        '/drawings/d1/publish',
        (s) => s.reply(202, {'status': 'PROCESSING'}),
      );
      expect(await repo.publish('d1'), DrawingStatus.processing);
    });

    test('errors surface as ApiException with the server code', () async {
      adapter.onPost(
        '/drawings/d1/publish',
        (s) => s.reply(400, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'Need 1-2 preview sheets',
          },
        }),
      );
      await expectLater(
        repo.publish('d1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', ApiErrorCodes.validation)
              .having((e) => e.message, 'message', contains('preview')),
        ),
      );
    });
  });

  group('DioSheetUploader', () {
    test(
      'PUTs the bytes with the presigned headers and reports progress',
      () async {
        final fake = _RecordingAdapter();
        final uploader = DioSheetUploader(Dio()..httpClientAdapter = fake);
        final progress = <int>[];
        await uploader.upload(
          const SheetUploadTarget(
            uploadUrl: 'http://minio/put?sig=1',
            objectKey: 'k',
            headers: {'Content-Type': 'application/pdf', 'x-amz-foo': 'bar'},
          ),
          PickedSheetFile(
            name: 'plan.pdf',
            sizeBytes: 6,
            openRead:
                () => Stream.fromIterable([
                  [1, 2, 3],
                  [4, 5, 6],
                ]),
          ),
          onProgress: (sent, total) => progress.add(sent),
        );
        expect(fake.method, 'PUT');
        expect(fake.url, 'http://minio/put?sig=1');
        expect(fake.headers['x-amz-foo'], 'bar');
        expect(fake.headers['Authorization'], isNull);
        expect(fake.received, 6);
        expect(progress.last, 6);
      },
    );

    test('storage failure becomes an ApiException', () async {
      final uploader = DioSheetUploader(
        Dio()..httpClientAdapter = _RecordingAdapter(status: 403),
      );
      await expectLater(
        uploader.upload(
          const SheetUploadTarget(
            uploadUrl: 'http://minio/put',
            objectKey: 'k',
          ),
          PickedSheetFile(
            name: 'a.pdf',
            sizeBytes: 1,
            openRead: () => Stream.value([1]),
          ),
          onProgress: (_, __) {},
        ),
        throwsA(isA<ApiException>()),
      );
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter({this.status = 200});
  final int status;
  String? method;
  String? url;
  Map<String, dynamic> headers = {};
  int received = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    method = options.method;
    url = options.uri.toString();
    headers = options.headers;
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        received += chunk.length;
        options.onSendProgress?.call(
          received,
          options.headers['content-length'] as int? ?? -1,
        );
      }
    }
    return ResponseBody.fromString('', status);
  }

  @override
  void close({bool force = false}) {}
}
