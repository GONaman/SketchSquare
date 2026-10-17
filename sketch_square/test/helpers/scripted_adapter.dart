import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

typedef AdapterHandler = FutureOr<ResponseBody> Function(RequestOptions o);

/// Minimal scriptable [HttpClientAdapter]: every request goes to [handler] and
/// is recorded in [requests]. Handy where `http_mock_adapter` cannot express
/// "401 first, 200 afterwards".
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handler);

  final AdapterHandler handler;
  final requests = <RequestOptions>[];

  int count(String path) => requests.where((r) => r.path == path).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, [int status = 200]) =>
    ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody errorResponse(int status, String code, [String message = 'err']) =>
    jsonResponse({
      'error': {'code': code, 'message': message},
    }, status);
