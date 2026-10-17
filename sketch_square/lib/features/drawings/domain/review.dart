import 'package:freezed_annotation/freezed_annotation.dart';

part 'review.freezed.dart';
part 'review.g.dart';

@freezed
abstract class ReviewerRef with _$ReviewerRef {
  const factory ReviewerRef({required String id, required String fullName}) =
      _ReviewerRef;

  factory ReviewerRef.fromJson(Map<String, dynamic> json) =>
      _$ReviewerRefFromJson(json);
}

/// `Review` from docs/API_CONTRACT.md (`rating` is 1..5).
@freezed
abstract class Review with _$Review {
  const factory Review({
    required String id,
    required int rating,
    String? comment,
    required ReviewerRef reviewer,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}
