// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_search_query.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DrawingSearchQuery {

 String get q; String? get categoryId; double? get length; double? get breadth; LengthUnit get unit; int get tolerancePct; List<String> get cities; double? get minDrawingRating; double? get minArchitectRating; PriceType get priceType; int? get minPricePaise; int? get maxPricePaise; DrawingSort get sort;
/// Create a copy of DrawingSearchQuery
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingSearchQueryCopyWith<DrawingSearchQuery> get copyWith => _$DrawingSearchQueryCopyWithImpl<DrawingSearchQuery>(this as DrawingSearchQuery, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingSearchQuery&&(identical(other.q, q) || other.q == q)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.length, length) || other.length == length)&&(identical(other.breadth, breadth) || other.breadth == breadth)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.tolerancePct, tolerancePct) || other.tolerancePct == tolerancePct)&&const DeepCollectionEquality().equals(other.cities, cities)&&(identical(other.minDrawingRating, minDrawingRating) || other.minDrawingRating == minDrawingRating)&&(identical(other.minArchitectRating, minArchitectRating) || other.minArchitectRating == minArchitectRating)&&(identical(other.priceType, priceType) || other.priceType == priceType)&&(identical(other.minPricePaise, minPricePaise) || other.minPricePaise == minPricePaise)&&(identical(other.maxPricePaise, maxPricePaise) || other.maxPricePaise == maxPricePaise)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,q,categoryId,length,breadth,unit,tolerancePct,const DeepCollectionEquality().hash(cities),minDrawingRating,minArchitectRating,priceType,minPricePaise,maxPricePaise,sort);

@override
String toString() {
  return 'DrawingSearchQuery(q: $q, categoryId: $categoryId, length: $length, breadth: $breadth, unit: $unit, tolerancePct: $tolerancePct, cities: $cities, minDrawingRating: $minDrawingRating, minArchitectRating: $minArchitectRating, priceType: $priceType, minPricePaise: $minPricePaise, maxPricePaise: $maxPricePaise, sort: $sort)';
}


}

/// @nodoc
abstract mixin class $DrawingSearchQueryCopyWith<$Res>  {
  factory $DrawingSearchQueryCopyWith(DrawingSearchQuery value, $Res Function(DrawingSearchQuery) _then) = _$DrawingSearchQueryCopyWithImpl;
@useResult
$Res call({
 String q, String? categoryId, double? length, double? breadth, LengthUnit unit, int tolerancePct, List<String> cities, double? minDrawingRating, double? minArchitectRating, PriceType priceType, int? minPricePaise, int? maxPricePaise, DrawingSort sort
});




}
/// @nodoc
class _$DrawingSearchQueryCopyWithImpl<$Res>
    implements $DrawingSearchQueryCopyWith<$Res> {
  _$DrawingSearchQueryCopyWithImpl(this._self, this._then);

  final DrawingSearchQuery _self;
  final $Res Function(DrawingSearchQuery) _then;

/// Create a copy of DrawingSearchQuery
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? q = null,Object? categoryId = freezed,Object? length = freezed,Object? breadth = freezed,Object? unit = null,Object? tolerancePct = null,Object? cities = null,Object? minDrawingRating = freezed,Object? minArchitectRating = freezed,Object? priceType = null,Object? minPricePaise = freezed,Object? maxPricePaise = freezed,Object? sort = null,}) {
  return _then(_self.copyWith(
q: null == q ? _self.q : q // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,length: freezed == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as double?,breadth: freezed == breadth ? _self.breadth : breadth // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as LengthUnit,tolerancePct: null == tolerancePct ? _self.tolerancePct : tolerancePct // ignore: cast_nullable_to_non_nullable
as int,cities: null == cities ? _self.cities : cities // ignore: cast_nullable_to_non_nullable
as List<String>,minDrawingRating: freezed == minDrawingRating ? _self.minDrawingRating : minDrawingRating // ignore: cast_nullable_to_non_nullable
as double?,minArchitectRating: freezed == minArchitectRating ? _self.minArchitectRating : minArchitectRating // ignore: cast_nullable_to_non_nullable
as double?,priceType: null == priceType ? _self.priceType : priceType // ignore: cast_nullable_to_non_nullable
as PriceType,minPricePaise: freezed == minPricePaise ? _self.minPricePaise : minPricePaise // ignore: cast_nullable_to_non_nullable
as int?,maxPricePaise: freezed == maxPricePaise ? _self.maxPricePaise : maxPricePaise // ignore: cast_nullable_to_non_nullable
as int?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as DrawingSort,
  ));
}

}


/// Adds pattern-matching-related methods to [DrawingSearchQuery].
extension DrawingSearchQueryPatterns on DrawingSearchQuery {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawingSearchQuery value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawingSearchQuery() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawingSearchQuery value)  $default,){
final _that = this;
switch (_that) {
case _DrawingSearchQuery():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawingSearchQuery value)?  $default,){
final _that = this;
switch (_that) {
case _DrawingSearchQuery() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String q,  String? categoryId,  double? length,  double? breadth,  LengthUnit unit,  int tolerancePct,  List<String> cities,  double? minDrawingRating,  double? minArchitectRating,  PriceType priceType,  int? minPricePaise,  int? maxPricePaise,  DrawingSort sort)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawingSearchQuery() when $default != null:
return $default(_that.q,_that.categoryId,_that.length,_that.breadth,_that.unit,_that.tolerancePct,_that.cities,_that.minDrawingRating,_that.minArchitectRating,_that.priceType,_that.minPricePaise,_that.maxPricePaise,_that.sort);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String q,  String? categoryId,  double? length,  double? breadth,  LengthUnit unit,  int tolerancePct,  List<String> cities,  double? minDrawingRating,  double? minArchitectRating,  PriceType priceType,  int? minPricePaise,  int? maxPricePaise,  DrawingSort sort)  $default,) {final _that = this;
switch (_that) {
case _DrawingSearchQuery():
return $default(_that.q,_that.categoryId,_that.length,_that.breadth,_that.unit,_that.tolerancePct,_that.cities,_that.minDrawingRating,_that.minArchitectRating,_that.priceType,_that.minPricePaise,_that.maxPricePaise,_that.sort);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String q,  String? categoryId,  double? length,  double? breadth,  LengthUnit unit,  int tolerancePct,  List<String> cities,  double? minDrawingRating,  double? minArchitectRating,  PriceType priceType,  int? minPricePaise,  int? maxPricePaise,  DrawingSort sort)?  $default,) {final _that = this;
switch (_that) {
case _DrawingSearchQuery() when $default != null:
return $default(_that.q,_that.categoryId,_that.length,_that.breadth,_that.unit,_that.tolerancePct,_that.cities,_that.minDrawingRating,_that.minArchitectRating,_that.priceType,_that.minPricePaise,_that.maxPricePaise,_that.sort);case _:
  return null;

}
}

}

/// @nodoc


class _DrawingSearchQuery extends DrawingSearchQuery {
  const _DrawingSearchQuery({this.q = '', this.categoryId, this.length, this.breadth, this.unit = LengthUnit.ft, this.tolerancePct = defaultTolerancePct, final  List<String> cities = const <String>[], this.minDrawingRating, this.minArchitectRating, this.priceType = PriceType.all, this.minPricePaise, this.maxPricePaise, this.sort = DrawingSort.relevance}): _cities = cities,super._();
  

@override@JsonKey() final  String q;
@override final  String? categoryId;
@override final  double? length;
@override final  double? breadth;
@override@JsonKey() final  LengthUnit unit;
@override@JsonKey() final  int tolerancePct;
 final  List<String> _cities;
@override@JsonKey() List<String> get cities {
  if (_cities is EqualUnmodifiableListView) return _cities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cities);
}

@override final  double? minDrawingRating;
@override final  double? minArchitectRating;
@override@JsonKey() final  PriceType priceType;
@override final  int? minPricePaise;
@override final  int? maxPricePaise;
@override@JsonKey() final  DrawingSort sort;

/// Create a copy of DrawingSearchQuery
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawingSearchQueryCopyWith<_DrawingSearchQuery> get copyWith => __$DrawingSearchQueryCopyWithImpl<_DrawingSearchQuery>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawingSearchQuery&&(identical(other.q, q) || other.q == q)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.length, length) || other.length == length)&&(identical(other.breadth, breadth) || other.breadth == breadth)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.tolerancePct, tolerancePct) || other.tolerancePct == tolerancePct)&&const DeepCollectionEquality().equals(other._cities, _cities)&&(identical(other.minDrawingRating, minDrawingRating) || other.minDrawingRating == minDrawingRating)&&(identical(other.minArchitectRating, minArchitectRating) || other.minArchitectRating == minArchitectRating)&&(identical(other.priceType, priceType) || other.priceType == priceType)&&(identical(other.minPricePaise, minPricePaise) || other.minPricePaise == minPricePaise)&&(identical(other.maxPricePaise, maxPricePaise) || other.maxPricePaise == maxPricePaise)&&(identical(other.sort, sort) || other.sort == sort));
}


@override
int get hashCode => Object.hash(runtimeType,q,categoryId,length,breadth,unit,tolerancePct,const DeepCollectionEquality().hash(_cities),minDrawingRating,minArchitectRating,priceType,minPricePaise,maxPricePaise,sort);

@override
String toString() {
  return 'DrawingSearchQuery(q: $q, categoryId: $categoryId, length: $length, breadth: $breadth, unit: $unit, tolerancePct: $tolerancePct, cities: $cities, minDrawingRating: $minDrawingRating, minArchitectRating: $minArchitectRating, priceType: $priceType, minPricePaise: $minPricePaise, maxPricePaise: $maxPricePaise, sort: $sort)';
}


}

/// @nodoc
abstract mixin class _$DrawingSearchQueryCopyWith<$Res> implements $DrawingSearchQueryCopyWith<$Res> {
  factory _$DrawingSearchQueryCopyWith(_DrawingSearchQuery value, $Res Function(_DrawingSearchQuery) _then) = __$DrawingSearchQueryCopyWithImpl;
@override @useResult
$Res call({
 String q, String? categoryId, double? length, double? breadth, LengthUnit unit, int tolerancePct, List<String> cities, double? minDrawingRating, double? minArchitectRating, PriceType priceType, int? minPricePaise, int? maxPricePaise, DrawingSort sort
});




}
/// @nodoc
class __$DrawingSearchQueryCopyWithImpl<$Res>
    implements _$DrawingSearchQueryCopyWith<$Res> {
  __$DrawingSearchQueryCopyWithImpl(this._self, this._then);

  final _DrawingSearchQuery _self;
  final $Res Function(_DrawingSearchQuery) _then;

/// Create a copy of DrawingSearchQuery
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? q = null,Object? categoryId = freezed,Object? length = freezed,Object? breadth = freezed,Object? unit = null,Object? tolerancePct = null,Object? cities = null,Object? minDrawingRating = freezed,Object? minArchitectRating = freezed,Object? priceType = null,Object? minPricePaise = freezed,Object? maxPricePaise = freezed,Object? sort = null,}) {
  return _then(_DrawingSearchQuery(
q: null == q ? _self.q : q // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,length: freezed == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as double?,breadth: freezed == breadth ? _self.breadth : breadth // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as LengthUnit,tolerancePct: null == tolerancePct ? _self.tolerancePct : tolerancePct // ignore: cast_nullable_to_non_nullable
as int,cities: null == cities ? _self._cities : cities // ignore: cast_nullable_to_non_nullable
as List<String>,minDrawingRating: freezed == minDrawingRating ? _self.minDrawingRating : minDrawingRating // ignore: cast_nullable_to_non_nullable
as double?,minArchitectRating: freezed == minArchitectRating ? _self.minArchitectRating : minArchitectRating // ignore: cast_nullable_to_non_nullable
as double?,priceType: null == priceType ? _self.priceType : priceType // ignore: cast_nullable_to_non_nullable
as PriceType,minPricePaise: freezed == minPricePaise ? _self.minPricePaise : minPricePaise // ignore: cast_nullable_to_non_nullable
as int?,maxPricePaise: freezed == maxPricePaise ? _self.maxPricePaise : maxPricePaise // ignore: cast_nullable_to_non_nullable
as int?,sort: null == sort ? _self.sort : sort // ignore: cast_nullable_to_non_nullable
as DrawingSort,
  ));
}


}

// dart format on
