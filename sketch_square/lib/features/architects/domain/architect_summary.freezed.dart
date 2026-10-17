// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'architect_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ArchitectSummary {

 String get id; String get fullName; String get city; double get architectRating; int get ratingCount; String? get avatarUrl;
/// Create a copy of ArchitectSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchitectSummaryCopyWith<ArchitectSummary> get copyWith => _$ArchitectSummaryCopyWithImpl<ArchitectSummary>(this as ArchitectSummary, _$identity);

  /// Serializes this ArchitectSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchitectSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.city, city) || other.city == city)&&(identical(other.architectRating, architectRating) || other.architectRating == architectRating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,city,architectRating,ratingCount,avatarUrl);

@override
String toString() {
  return 'ArchitectSummary(id: $id, fullName: $fullName, city: $city, architectRating: $architectRating, ratingCount: $ratingCount, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class $ArchitectSummaryCopyWith<$Res>  {
  factory $ArchitectSummaryCopyWith(ArchitectSummary value, $Res Function(ArchitectSummary) _then) = _$ArchitectSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String city, double architectRating, int ratingCount, String? avatarUrl
});




}
/// @nodoc
class _$ArchitectSummaryCopyWithImpl<$Res>
    implements $ArchitectSummaryCopyWith<$Res> {
  _$ArchitectSummaryCopyWithImpl(this._self, this._then);

  final ArchitectSummary _self;
  final $Res Function(ArchitectSummary) _then;

/// Create a copy of ArchitectSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? city = null,Object? architectRating = null,Object? ratingCount = null,Object? avatarUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,architectRating: null == architectRating ? _self.architectRating : architectRating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ArchitectSummary].
extension ArchitectSummaryPatterns on ArchitectSummary {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArchitectSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArchitectSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArchitectSummary value)  $default,){
final _that = this;
switch (_that) {
case _ArchitectSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArchitectSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ArchitectSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String city,  double architectRating,  int ratingCount,  String? avatarUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArchitectSummary() when $default != null:
return $default(_that.id,_that.fullName,_that.city,_that.architectRating,_that.ratingCount,_that.avatarUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String city,  double architectRating,  int ratingCount,  String? avatarUrl)  $default,) {final _that = this;
switch (_that) {
case _ArchitectSummary():
return $default(_that.id,_that.fullName,_that.city,_that.architectRating,_that.ratingCount,_that.avatarUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String city,  double architectRating,  int ratingCount,  String? avatarUrl)?  $default,) {final _that = this;
switch (_that) {
case _ArchitectSummary() when $default != null:
return $default(_that.id,_that.fullName,_that.city,_that.architectRating,_that.ratingCount,_that.avatarUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ArchitectSummary implements ArchitectSummary {
  const _ArchitectSummary({required this.id, required this.fullName, required this.city, this.architectRating = 0, this.ratingCount = 0, this.avatarUrl});
  factory _ArchitectSummary.fromJson(Map<String, dynamic> json) => _$ArchitectSummaryFromJson(json);

@override final  String id;
@override final  String fullName;
@override final  String city;
@override@JsonKey() final  double architectRating;
@override@JsonKey() final  int ratingCount;
@override final  String? avatarUrl;

/// Create a copy of ArchitectSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArchitectSummaryCopyWith<_ArchitectSummary> get copyWith => __$ArchitectSummaryCopyWithImpl<_ArchitectSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ArchitectSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArchitectSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.city, city) || other.city == city)&&(identical(other.architectRating, architectRating) || other.architectRating == architectRating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.avatarUrl, avatarUrl) || other.avatarUrl == avatarUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,city,architectRating,ratingCount,avatarUrl);

@override
String toString() {
  return 'ArchitectSummary(id: $id, fullName: $fullName, city: $city, architectRating: $architectRating, ratingCount: $ratingCount, avatarUrl: $avatarUrl)';
}


}

/// @nodoc
abstract mixin class _$ArchitectSummaryCopyWith<$Res> implements $ArchitectSummaryCopyWith<$Res> {
  factory _$ArchitectSummaryCopyWith(_ArchitectSummary value, $Res Function(_ArchitectSummary) _then) = __$ArchitectSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String city, double architectRating, int ratingCount, String? avatarUrl
});




}
/// @nodoc
class __$ArchitectSummaryCopyWithImpl<$Res>
    implements _$ArchitectSummaryCopyWith<$Res> {
  __$ArchitectSummaryCopyWithImpl(this._self, this._then);

  final _ArchitectSummary _self;
  final $Res Function(_ArchitectSummary) _then;

/// Create a copy of ArchitectSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? city = null,Object? architectRating = null,Object? ratingCount = null,Object? avatarUrl = freezed,}) {
  return _then(_ArchitectSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,architectRating: null == architectRating ? _self.architectRating : architectRating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,avatarUrl: freezed == avatarUrl ? _self.avatarUrl : avatarUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
