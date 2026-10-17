// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'city_count.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CityCount {

 String get city; int get count;
/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CityCountCopyWith<CityCount> get copyWith => _$CityCountCopyWithImpl<CityCount>(this as CityCount, _$identity);

  /// Serializes this CityCount to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CityCount&&(identical(other.city, city) || other.city == city)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,count);

@override
String toString() {
  return 'CityCount(city: $city, count: $count)';
}


}

/// @nodoc
abstract mixin class $CityCountCopyWith<$Res>  {
  factory $CityCountCopyWith(CityCount value, $Res Function(CityCount) _then) = _$CityCountCopyWithImpl;
@useResult
$Res call({
 String city, int count
});




}
/// @nodoc
class _$CityCountCopyWithImpl<$Res>
    implements $CityCountCopyWith<$Res> {
  _$CityCountCopyWithImpl(this._self, this._then);

  final CityCount _self;
  final $Res Function(CityCount) _then;

/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? city = null,Object? count = null,}) {
  return _then(_self.copyWith(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CityCount].
extension CityCountPatterns on CityCount {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CityCount value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CityCount() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CityCount value)  $default,){
final _that = this;
switch (_that) {
case _CityCount():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CityCount value)?  $default,){
final _that = this;
switch (_that) {
case _CityCount() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String city,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CityCount() when $default != null:
return $default(_that.city,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String city,  int count)  $default,) {final _that = this;
switch (_that) {
case _CityCount():
return $default(_that.city,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String city,  int count)?  $default,) {final _that = this;
switch (_that) {
case _CityCount() when $default != null:
return $default(_that.city,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CityCount implements CityCount {
  const _CityCount({required this.city, this.count = 0});
  factory _CityCount.fromJson(Map<String, dynamic> json) => _$CityCountFromJson(json);

@override final  String city;
@override@JsonKey() final  int count;

/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CityCountCopyWith<_CityCount> get copyWith => __$CityCountCopyWithImpl<_CityCount>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CityCountToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CityCount&&(identical(other.city, city) || other.city == city)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,city,count);

@override
String toString() {
  return 'CityCount(city: $city, count: $count)';
}


}

/// @nodoc
abstract mixin class _$CityCountCopyWith<$Res> implements $CityCountCopyWith<$Res> {
  factory _$CityCountCopyWith(_CityCount value, $Res Function(_CityCount) _then) = __$CityCountCopyWithImpl;
@override @useResult
$Res call({
 String city, int count
});




}
/// @nodoc
class __$CityCountCopyWithImpl<$Res>
    implements _$CityCountCopyWith<$Res> {
  __$CityCountCopyWithImpl(this._self, this._then);

  final _CityCount _self;
  final $Res Function(_CityCount) _then;

/// Create a copy of CityCount
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? city = null,Object? count = null,}) {
  return _then(_CityCount(
city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
