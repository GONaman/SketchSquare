import 'package:freezed_annotation/freezed_annotation.dart';

import 'user.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

/// `{ user, tokens }` returned by signup and login.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({required User user, required Tokens tokens}) =
      _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}
