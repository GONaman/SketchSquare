import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/upload_repository.dart';
import 'dio_sheet_uploader.dart';
import 'dio_upload_repository.dart';

part 'upload_providers.g.dart';

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
