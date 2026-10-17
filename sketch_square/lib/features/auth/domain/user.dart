import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@JsonEnum(alwaysCreate: true)
enum UserRole {
  @JsonValue('ARCHITECT')
  architect,
  @JsonValue('ADMIN')
  admin,
}

@JsonEnum(alwaysCreate: true)
enum VerificationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('APPROVED')
  approved,
  @JsonValue('REJECTED')
  rejected,
}

/// `User` from docs/API_CONTRACT.md.
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String fullName,
    required String address,
    required String phone,
    String? avatarUrl,
    required String city,
    required UserRole role,
    required VerificationStatus verificationStatus,
    @Default(0) double architectRating,
    @Default(0) int freeDownloadsUsed,
    @Default(20) int freeDownloadLimit,
    required DateTime createdAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}

/// `Tokens` from docs/API_CONTRACT.md.
@freezed
abstract class Tokens with _$Tokens {
  const factory Tokens({
    required String accessToken,
    required String refreshToken,
    @Default(900) int expiresIn,
  }) = _Tokens;

  factory Tokens.fromJson(Map<String, dynamic> json) => _$TokensFromJson(json);
}
