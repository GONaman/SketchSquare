import 'package:freezed_annotation/freezed_annotation.dart';

part 'city_count.freezed.dart';
part 'city_count.g.dart';

/// `GET /cities` item.
@freezed
abstract class CityCount with _$CityCount {
  const factory CityCount({required String city, @Default(0) int count}) =
      _CityCount;

  factory CityCount.fromJson(Map<String, dynamic> json) =>
      _$CityCountFromJson(json);
}
