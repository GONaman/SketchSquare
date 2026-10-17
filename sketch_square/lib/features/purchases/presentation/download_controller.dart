import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../auth/presentation/current_user_provider.dart';
import '../data/purchases_providers.dart';

part 'download_controller.g.dart';

enum DownloadStatus { downloading, done, failed }

class DownloadState {
  const DownloadState.downloading([this.progress])
    : status = DownloadStatus.downloading,
      path = null,
      message = null,
      quotaReached = false;

  const DownloadState.done(this.path)
    : status = DownloadStatus.done,
      progress = 1,
      message = null,
      quotaReached = false;

  const DownloadState.failed(this.message, {this.quotaReached = false})
    : status = DownloadStatus.failed,
      progress = null,
      path = null;

  final DownloadStatus status;
  final double? progress;
  final String? path;
  final String? message;

  /// 403 `FREE_LIMIT_REACHED`: the monthly/lifetime free quota is used up.
  final bool quotaReached;

  bool get isBusy => status == DownloadStatus.downloading;
}

/// Download state per sheet id. A sheet downloaded in this session is served
/// from the local file (no second presigned URL, no second quota hit).
@Riverpod(keepAlive: true)
class DownloadController extends _$DownloadController {
  @override
  Map<String, DownloadState> build() {
    ref.watch(currentUserIdProvider);
    return const {};
  }

  void _set(String sheetId, DownloadState s) => state = {...state, sheetId: s};

  /// Requests the link, downloads the file. [isFreePurchase] refreshes the
  /// user afterwards so the free-quota indicator is current.
  Future<void> download({
    required String drawingId,
    required String sheetId,
    bool isFreePurchase = false,
  }) async {
    if (state[sheetId]?.isBusy ?? false) return;
    _set(sheetId, const DownloadState.downloading());
    try {
      final link = await ref
          .read(purchasesRepositoryProvider)
          .downloadLink(drawingId, sheetId);
      final path = await ref
          .read(fileDownloaderProvider)
          .download(
            link,
            onProgress: (p) => _set(sheetId, DownloadState.downloading(p)),
          );
      _set(sheetId, DownloadState.done(path));
      if (isFreePurchase) {
        try {
          await ref.read(authControllerProvider.notifier).refreshUser();
        } catch (_) {}
      }
    } catch (e) {
      final error = toApiException(e);
      final quota = error.code == ApiErrorCodes.freeLimitReached;
      _set(
        sheetId,
        DownloadState.failed(
          quota
              ? 'Free download limit reached. Buy drawings to keep downloading.'
              : error.message,
          quotaReached: quota,
        ),
      );
    }
  }

  Future<void> open(String sheetId) async {
    final path = state[sheetId]?.path;
    if (path != null) await ref.read(fileHandlerProvider).open(path);
  }

  Future<void> share(String sheetId) async {
    final path = state[sheetId]?.path;
    if (path != null) await ref.read(fileHandlerProvider).share(path);
  }
}
