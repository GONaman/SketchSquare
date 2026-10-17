import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../data/dio_verification_repository.dart';
import '../domain/verification_repository.dart';
import '../domain/verification_request.dart';

part 'verification_providers.g.dart';

@Riverpod(keepAlive: true)
VerificationRepository verificationRepository(Ref ref) =>
    DioVerificationRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
DocumentPicker documentPicker(Ref ref) => const FilePickerDocumentPicker();

/// The signed-in user's latest verification submission (`GET /verification/me`).
@riverpod
Future<VerificationRequest?> myVerification(Ref ref) =>
    ref.watch(verificationRepositoryProvider).mine();
