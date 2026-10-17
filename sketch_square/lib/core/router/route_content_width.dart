import '../layout/content_frame.dart';
import 'routes.dart';

/// Content width for the screen at [path]: forms get a narrow column, row lists
/// a medium one, everything else (feeds, grids, drawing detail) the full
/// browse width. Used by the app shell and by `appRouter`'s frame for
/// top-level routes so individual screens need no width code.
ContentWidth contentWidthForPath(String path) {
  bool under(String base) => path == base || path.startsWith('$base/');

  if (under(AppRoutes.favorites)) return ContentWidth.browse;
  if (under(AppRoutes.upload) ||
      under(AppRoutes.basketCheckout) ||
      under(AppRoutes.basketOrderResult) ||
      under(AppRoutes.profileEdit) ||
      under(AppRoutes.settings) ||
      under(AppRoutes.wallet) ||
      under(AppRoutes.terms) ||
      under(AppRoutes.privacy)) {
    return ContentWidth.form;
  }
  if (under(AppRoutes.basket) ||
      under(AppRoutes.profile) ||
      under(AppRoutes.manageDrawings) ||
      under(AppRoutes.admin)) {
    return ContentWidth.list;
  }
  return ContentWidth.browse;
}
