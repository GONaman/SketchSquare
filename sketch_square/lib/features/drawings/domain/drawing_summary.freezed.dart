// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryRef {

 String get id; String get name; String get slug;
/// Create a copy of CategoryRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryRefCopyWith<CategoryRef> get copyWith => _$CategoryRefCopyWithImpl<CategoryRef>(this as CategoryRef, _$identity);

  /// Serializes this CategoryRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug);

@override
String toString() {
  return 'CategoryRef(id: $id, name: $name, slug: $slug)';
}


}

/// @nodoc
abstract mixin class $CategoryRefCopyWith<$Res>  {
  factory $CategoryRefCopyWith(CategoryRef value, $Res Function(CategoryRef) _then) = _$CategoryRefCopyWithImpl;
@useResult
$Res call({
 String id, String name, String slug
});




}
/// @nodoc
class _$CategoryRefCopyWithImpl<$Res>
    implements $CategoryRefCopyWith<$Res> {
  _$CategoryRefCopyWithImpl(this._self, this._then);

  final CategoryRef _self;
  final $Res Function(CategoryRef) _then;

/// Create a copy of CategoryRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? slug = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryRef].
extension CategoryRefPatterns on CategoryRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryRef value)  $default,){
final _that = this;
switch (_that) {
case _CategoryRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryRef value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String slug)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryRef() when $default != null:
return $default(_that.id,_that.name,_that.slug);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String slug)  $default,) {final _that = this;
switch (_that) {
case _CategoryRef():
return $default(_that.id,_that.name,_that.slug);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String slug)?  $default,) {final _that = this;
switch (_that) {
case _CategoryRef() when $default != null:
return $default(_that.id,_that.name,_that.slug);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CategoryRef implements CategoryRef {
  const _CategoryRef({required this.id, required this.name, required this.slug});
  factory _CategoryRef.fromJson(Map<String, dynamic> json) => _$CategoryRefFromJson(json);

@override final  String id;
@override final  String name;
@override final  String slug;

/// Create a copy of CategoryRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryRefCopyWith<_CategoryRef> get copyWith => __$CategoryRefCopyWithImpl<_CategoryRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CategoryRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryRef&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.slug, slug) || other.slug == slug));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,slug);

@override
String toString() {
  return 'CategoryRef(id: $id, name: $name, slug: $slug)';
}


}

/// @nodoc
abstract mixin class _$CategoryRefCopyWith<$Res> implements $CategoryRefCopyWith<$Res> {
  factory _$CategoryRefCopyWith(_CategoryRef value, $Res Function(_CategoryRef) _then) = __$CategoryRefCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String slug
});




}
/// @nodoc
class __$CategoryRefCopyWithImpl<$Res>
    implements _$CategoryRefCopyWith<$Res> {
  __$CategoryRefCopyWithImpl(this._self, this._then);

  final _CategoryRef _self;
  final $Res Function(_CategoryRef) _then;

/// Create a copy of CategoryRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? slug = null,}) {
  return _then(_CategoryRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DrawingSummary {

 String get id; String get title; CategoryRef get category; String get city; double get plotLengthFt; double get plotBreadthFt; double get plotAreaSqft; int get floors; String? get facing; int get pricePaise; bool get isFree; double get avgRating; int get ratingCount; String? get previewUrl; ArchitectSummary get architect; DrawingStatus get status; DateTime get createdAt;// 0..1, only present for plot-size searches (1 = exact).
 double? get sizeMatch;
/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingSummaryCopyWith<DrawingSummary> get copyWith => _$DrawingSummaryCopyWithImpl<DrawingSummary>(this as DrawingSummary, _$identity);

  /// Serializes this DrawingSummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.city, city) || other.city == city)&&(identical(other.plotLengthFt, plotLengthFt) || other.plotLengthFt == plotLengthFt)&&(identical(other.plotBreadthFt, plotBreadthFt) || other.plotBreadthFt == plotBreadthFt)&&(identical(other.plotAreaSqft, plotAreaSqft) || other.plotAreaSqft == plotAreaSqft)&&(identical(other.floors, floors) || other.floors == floors)&&(identical(other.facing, facing) || other.facing == facing)&&(identical(other.pricePaise, pricePaise) || other.pricePaise == pricePaise)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.avgRating, avgRating) || other.avgRating == avgRating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.architect, architect) || other.architect == architect)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sizeMatch, sizeMatch) || other.sizeMatch == sizeMatch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,city,plotLengthFt,plotBreadthFt,plotAreaSqft,floors,facing,pricePaise,isFree,avgRating,ratingCount,previewUrl,architect,status,createdAt,sizeMatch);

@override
String toString() {
  return 'DrawingSummary(id: $id, title: $title, category: $category, city: $city, plotLengthFt: $plotLengthFt, plotBreadthFt: $plotBreadthFt, plotAreaSqft: $plotAreaSqft, floors: $floors, facing: $facing, pricePaise: $pricePaise, isFree: $isFree, avgRating: $avgRating, ratingCount: $ratingCount, previewUrl: $previewUrl, architect: $architect, status: $status, createdAt: $createdAt, sizeMatch: $sizeMatch)';
}


}

/// @nodoc
abstract mixin class $DrawingSummaryCopyWith<$Res>  {
  factory $DrawingSummaryCopyWith(DrawingSummary value, $Res Function(DrawingSummary) _then) = _$DrawingSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String title, CategoryRef category, String city, double plotLengthFt, double plotBreadthFt, double plotAreaSqft, int floors, String? facing, int pricePaise, bool isFree, double avgRating, int ratingCount, String? previewUrl, ArchitectSummary architect, DrawingStatus status, DateTime createdAt, double? sizeMatch
});


$CategoryRefCopyWith<$Res> get category;$ArchitectSummaryCopyWith<$Res> get architect;

}
/// @nodoc
class _$DrawingSummaryCopyWithImpl<$Res>
    implements $DrawingSummaryCopyWith<$Res> {
  _$DrawingSummaryCopyWithImpl(this._self, this._then);

  final DrawingSummary _self;
  final $Res Function(DrawingSummary) _then;

/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? category = null,Object? city = null,Object? plotLengthFt = null,Object? plotBreadthFt = null,Object? plotAreaSqft = null,Object? floors = null,Object? facing = freezed,Object? pricePaise = null,Object? isFree = null,Object? avgRating = null,Object? ratingCount = null,Object? previewUrl = freezed,Object? architect = null,Object? status = null,Object? createdAt = null,Object? sizeMatch = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryRef,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,plotLengthFt: null == plotLengthFt ? _self.plotLengthFt : plotLengthFt // ignore: cast_nullable_to_non_nullable
as double,plotBreadthFt: null == plotBreadthFt ? _self.plotBreadthFt : plotBreadthFt // ignore: cast_nullable_to_non_nullable
as double,plotAreaSqft: null == plotAreaSqft ? _self.plotAreaSqft : plotAreaSqft // ignore: cast_nullable_to_non_nullable
as double,floors: null == floors ? _self.floors : floors // ignore: cast_nullable_to_non_nullable
as int,facing: freezed == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as String?,pricePaise: null == pricePaise ? _self.pricePaise : pricePaise // ignore: cast_nullable_to_non_nullable
as int,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,avgRating: null == avgRating ? _self.avgRating : avgRating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,architect: null == architect ? _self.architect : architect // ignore: cast_nullable_to_non_nullable
as ArchitectSummary,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DrawingStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,sizeMatch: freezed == sizeMatch ? _self.sizeMatch : sizeMatch // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryRefCopyWith<$Res> get category {
  
  return $CategoryRefCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArchitectSummaryCopyWith<$Res> get architect {
  
  return $ArchitectSummaryCopyWith<$Res>(_self.architect, (value) {
    return _then(_self.copyWith(architect: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrawingSummary].
extension DrawingSummaryPatterns on DrawingSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawingSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawingSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawingSummary value)  $default,){
final _that = this;
switch (_that) {
case _DrawingSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawingSummary value)?  $default,){
final _that = this;
switch (_that) {
case _DrawingSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  CategoryRef category,  String city,  double plotLengthFt,  double plotBreadthFt,  double plotAreaSqft,  int floors,  String? facing,  int pricePaise,  bool isFree,  double avgRating,  int ratingCount,  String? previewUrl,  ArchitectSummary architect,  DrawingStatus status,  DateTime createdAt,  double? sizeMatch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawingSummary() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.city,_that.plotLengthFt,_that.plotBreadthFt,_that.plotAreaSqft,_that.floors,_that.facing,_that.pricePaise,_that.isFree,_that.avgRating,_that.ratingCount,_that.previewUrl,_that.architect,_that.status,_that.createdAt,_that.sizeMatch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  CategoryRef category,  String city,  double plotLengthFt,  double plotBreadthFt,  double plotAreaSqft,  int floors,  String? facing,  int pricePaise,  bool isFree,  double avgRating,  int ratingCount,  String? previewUrl,  ArchitectSummary architect,  DrawingStatus status,  DateTime createdAt,  double? sizeMatch)  $default,) {final _that = this;
switch (_that) {
case _DrawingSummary():
return $default(_that.id,_that.title,_that.category,_that.city,_that.plotLengthFt,_that.plotBreadthFt,_that.plotAreaSqft,_that.floors,_that.facing,_that.pricePaise,_that.isFree,_that.avgRating,_that.ratingCount,_that.previewUrl,_that.architect,_that.status,_that.createdAt,_that.sizeMatch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  CategoryRef category,  String city,  double plotLengthFt,  double plotBreadthFt,  double plotAreaSqft,  int floors,  String? facing,  int pricePaise,  bool isFree,  double avgRating,  int ratingCount,  String? previewUrl,  ArchitectSummary architect,  DrawingStatus status,  DateTime createdAt,  double? sizeMatch)?  $default,) {final _that = this;
switch (_that) {
case _DrawingSummary() when $default != null:
return $default(_that.id,_that.title,_that.category,_that.city,_that.plotLengthFt,_that.plotBreadthFt,_that.plotAreaSqft,_that.floors,_that.facing,_that.pricePaise,_that.isFree,_that.avgRating,_that.ratingCount,_that.previewUrl,_that.architect,_that.status,_that.createdAt,_that.sizeMatch);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DrawingSummary implements DrawingSummary {
  const _DrawingSummary({required this.id, required this.title, required this.category, required this.city, required this.plotLengthFt, required this.plotBreadthFt, required this.plotAreaSqft, required this.floors, this.facing, required this.pricePaise, required this.isFree, this.avgRating = 0, this.ratingCount = 0, this.previewUrl, required this.architect, required this.status, required this.createdAt, this.sizeMatch});
  factory _DrawingSummary.fromJson(Map<String, dynamic> json) => _$DrawingSummaryFromJson(json);

@override final  String id;
@override final  String title;
@override final  CategoryRef category;
@override final  String city;
@override final  double plotLengthFt;
@override final  double plotBreadthFt;
@override final  double plotAreaSqft;
@override final  int floors;
@override final  String? facing;
@override final  int pricePaise;
@override final  bool isFree;
@override@JsonKey() final  double avgRating;
@override@JsonKey() final  int ratingCount;
@override final  String? previewUrl;
@override final  ArchitectSummary architect;
@override final  DrawingStatus status;
@override final  DateTime createdAt;
// 0..1, only present for plot-size searches (1 = exact).
@override final  double? sizeMatch;

/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawingSummaryCopyWith<_DrawingSummary> get copyWith => __$DrawingSummaryCopyWithImpl<_DrawingSummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrawingSummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawingSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.category, category) || other.category == category)&&(identical(other.city, city) || other.city == city)&&(identical(other.plotLengthFt, plotLengthFt) || other.plotLengthFt == plotLengthFt)&&(identical(other.plotBreadthFt, plotBreadthFt) || other.plotBreadthFt == plotBreadthFt)&&(identical(other.plotAreaSqft, plotAreaSqft) || other.plotAreaSqft == plotAreaSqft)&&(identical(other.floors, floors) || other.floors == floors)&&(identical(other.facing, facing) || other.facing == facing)&&(identical(other.pricePaise, pricePaise) || other.pricePaise == pricePaise)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.avgRating, avgRating) || other.avgRating == avgRating)&&(identical(other.ratingCount, ratingCount) || other.ratingCount == ratingCount)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.architect, architect) || other.architect == architect)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sizeMatch, sizeMatch) || other.sizeMatch == sizeMatch));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,category,city,plotLengthFt,plotBreadthFt,plotAreaSqft,floors,facing,pricePaise,isFree,avgRating,ratingCount,previewUrl,architect,status,createdAt,sizeMatch);

@override
String toString() {
  return 'DrawingSummary(id: $id, title: $title, category: $category, city: $city, plotLengthFt: $plotLengthFt, plotBreadthFt: $plotBreadthFt, plotAreaSqft: $plotAreaSqft, floors: $floors, facing: $facing, pricePaise: $pricePaise, isFree: $isFree, avgRating: $avgRating, ratingCount: $ratingCount, previewUrl: $previewUrl, architect: $architect, status: $status, createdAt: $createdAt, sizeMatch: $sizeMatch)';
}


}

/// @nodoc
abstract mixin class _$DrawingSummaryCopyWith<$Res> implements $DrawingSummaryCopyWith<$Res> {
  factory _$DrawingSummaryCopyWith(_DrawingSummary value, $Res Function(_DrawingSummary) _then) = __$DrawingSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, CategoryRef category, String city, double plotLengthFt, double plotBreadthFt, double plotAreaSqft, int floors, String? facing, int pricePaise, bool isFree, double avgRating, int ratingCount, String? previewUrl, ArchitectSummary architect, DrawingStatus status, DateTime createdAt, double? sizeMatch
});


@override $CategoryRefCopyWith<$Res> get category;@override $ArchitectSummaryCopyWith<$Res> get architect;

}
/// @nodoc
class __$DrawingSummaryCopyWithImpl<$Res>
    implements _$DrawingSummaryCopyWith<$Res> {
  __$DrawingSummaryCopyWithImpl(this._self, this._then);

  final _DrawingSummary _self;
  final $Res Function(_DrawingSummary) _then;

/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? category = null,Object? city = null,Object? plotLengthFt = null,Object? plotBreadthFt = null,Object? plotAreaSqft = null,Object? floors = null,Object? facing = freezed,Object? pricePaise = null,Object? isFree = null,Object? avgRating = null,Object? ratingCount = null,Object? previewUrl = freezed,Object? architect = null,Object? status = null,Object? createdAt = null,Object? sizeMatch = freezed,}) {
  return _then(_DrawingSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryRef,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,plotLengthFt: null == plotLengthFt ? _self.plotLengthFt : plotLengthFt // ignore: cast_nullable_to_non_nullable
as double,plotBreadthFt: null == plotBreadthFt ? _self.plotBreadthFt : plotBreadthFt // ignore: cast_nullable_to_non_nullable
as double,plotAreaSqft: null == plotAreaSqft ? _self.plotAreaSqft : plotAreaSqft // ignore: cast_nullable_to_non_nullable
as double,floors: null == floors ? _self.floors : floors // ignore: cast_nullable_to_non_nullable
as int,facing: freezed == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as String?,pricePaise: null == pricePaise ? _self.pricePaise : pricePaise // ignore: cast_nullable_to_non_nullable
as int,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,avgRating: null == avgRating ? _self.avgRating : avgRating // ignore: cast_nullable_to_non_nullable
as double,ratingCount: null == ratingCount ? _self.ratingCount : ratingCount // ignore: cast_nullable_to_non_nullable
as int,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,architect: null == architect ? _self.architect : architect // ignore: cast_nullable_to_non_nullable
as ArchitectSummary,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DrawingStatus,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,sizeMatch: freezed == sizeMatch ? _self.sizeMatch : sizeMatch // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryRefCopyWith<$Res> get category {
  
  return $CategoryRefCopyWith<$Res>(_self.category, (value) {
    return _then(_self.copyWith(category: value));
  });
}/// Create a copy of DrawingSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArchitectSummaryCopyWith<$Res> get architect {
  
  return $ArchitectSummaryCopyWith<$Res>(_self.architect, (value) {
    return _then(_self.copyWith(architect: value));
  });
}
}

// dart format on
