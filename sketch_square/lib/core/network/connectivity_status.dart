import 'dart:async';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers.dart';
import 'api_exception.dart';

part 'connectivity_status.g.dart';

/// Whether the API is reachable (`true` = online).
///
/// Driven by the HTTP layer instead of a platform plugin: a connection failure
/// flips it offline, any server response flips it back. While offline it polls
/// `GET /health` so the banner clears by itself once the network returns.
@Riverpod(keepAlive: true)
class ConnectivityStatus extends _$ConnectivityStatus {
  static const probeInterval = Duration(seconds: 5);

  Timer? _probeTimer;

  @override
  bool build() {
    ref.onDispose(() => _probeTimer?.cancel());
    return true;
  }

  void reportOnline() {
    _probeTimer?.cancel();
    _probeTimer = null;
    if (!state) state = true;
  }

  void reportOffline() {
    if (state) state = false;
    _probeTimer ??= Timer.periodic(probeInterval, (_) => probe());
  }

  /// Pings the API; any HTTP response (even an error status) counts as online.
  Future<void> probe() async {
    try {
      await ref.read(dioProvider).get<Object?>('/health');
      reportOnline();
    } on DioException catch (e) {
      if (e.response != null) reportOnline();
    }
  }
}

/// Reports reachability changes from every request to [onChanged].
class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor(this.onChanged);

  final void Function(bool online) onChanged;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    onChanged(true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final error = err.error;
    if ((error is ApiException && error.code == ApiErrorCodes.network) ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      onChanged(false);
    } else if (err.response != null) {
      onChanged(true);
    }
    handler.next(err);
  }
}
