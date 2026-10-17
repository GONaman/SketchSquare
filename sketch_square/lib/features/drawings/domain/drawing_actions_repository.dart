/// The two buyer actions the detail screen triggers. Cart and favorites are
/// owned by the commerce/Phase 8 work; this is the minimal surface discovery
/// needs, backed by `POST /cart` and `PUT|DELETE /drawings/:id/favorite`.
abstract interface class DrawingActionsRepository {
  Future<void> addToCart(String drawingId);

  Future<void> setFavorite(String drawingId, {required bool favorite});
}
