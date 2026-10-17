import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/draft_store.dart';
import '../domain/upload_repository.dart';
import 'dio_sheet_uploader.dart';
import 'dio_upload_repository.dart';
import 'shared_prefs_draft_store.dart';

part 'upload_providers.g.dart';

@Riverpod(keepAlive: true)
DraftStore draftStore(Ref ref) => SharedPrefsDraftStore();

/// Delay used between processing-status polls; tests override it to run instantly.
@Riverpod(keepAlive: true)
Future<void> Function(Duration) uploadDelay(Ref ref) => Future<void>.delayed;

/// Screens depend on the interface providers so tests can override them.
@Riverpod(keepAlive: true)
UploadRepository uploadRepository(Ref ref) => DioUploadRepository(
  ref.watch(dioProvider),
  sendExtendedMetadata: UploadConfig.sendExtendedMetadata,
);

@Riverpod(keepAlive: true)
SheetUploader sheetUploader(Ref ref) => DioSheetUploader();

@Riverpod(keepAlive: true)
SheetPicker sheetPicker(Ref ref) => const FilePickerSheetPicker();
