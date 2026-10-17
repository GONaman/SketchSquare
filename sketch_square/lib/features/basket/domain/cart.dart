import 'package:freezed_annotation/freezed_annotation.dart';

import '../../drawings/domain/drawing_summary.dart';

part 'cart.freezed.dart';
part 'cart.g.dart';

/// `GET /cart` response: `{ items: [DrawingSummary], totalPaise }`.
@freezed
abstract class Cart with _$Cart {
  const Cart._();

  const factory Cart({
    @Default([]) List<DrawingSummary> items,
    @Default(0) int totalPaise,
  }) = _Cart;

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);

  static const empty = Cart();

  bool get isEmpty => items.isEmpty;
  int get itemCount => items.length;

  /// Sum of the item prices; should always equal [totalPaise] from the server.
  int get computedTotalPaise =>
      items.fold(0, (sum, item) => sum + item.pricePaise);

  bool contains(String drawingId) => items.any((d) => d.id == drawingId);
}
