import '../../../core/network/cursor_page.dart';
import 'plagiarism_flag.dart';

/// ADMIN plagiarism review queue (Phase 8.4).
abstract interface class PlagiarismRepository {
  /// Oldest first; [status] defaults to pending on the server.
  Future<CursorPage<PlagiarismFlag>> flags({
    PlagiarismFlagStatus status = PlagiarismFlagStatus.pending,
    String? cursor,
    int limit = CursorPage.defaultLimit,
  });

  /// Publishes the held drawing. 409 `CONFLICT` if already decided.
  Future<void> approve(String id);

  /// Removes the drawing; [reason] (1–500 chars) is emailed to the uploader.
  Future<void> reject(String id, {required String reason});
}
