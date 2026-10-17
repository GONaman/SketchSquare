import 'package:shared_preferences/shared_preferences.dart';

import '../domain/payment_gateway.dart';

class PrefsPendingCheckoutStore implements PendingCheckoutStore {
  PrefsPendingCheckoutStore(this._prefs);

  static const _key = 'pending_checkout_order_id';
  final SharedPreferences _prefs;

  @override
  Future<String?> read() async => _prefs.getString(_key);

  @override
  Future<void> write(String orderId) async {
    await _prefs.setString(_key, orderId);
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }
}

class InMemoryPendingCheckoutStore implements PendingCheckoutStore {
  String? _orderId;

  @override
  Future<String?> read() async => _orderId;

  @override
  Future<void> write(String orderId) async => _orderId = orderId;

  @override
  Future<void> clear() async => _orderId = null;
}
