// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_form.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrawingForm {

 String get title; String get description; String? get categoryId; String get city; double? get plotLength; double? get plotBreadth; PlotUnit get unit; int? get floors; int? get bedrooms; String? get facing; List<String> get tags; bool get isFree;// Integer paise; 0 while unset. Ignored when [isFree].
 int get pricePaise;
/// Create a copy of DrawingForm
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingFormCopyWith<DrawingForm> get copyWith => _$DrawingFormCopyWithImpl<DrawingForm>(this as DrawingForm, _$identity);

  /// Serializes this DrawingForm to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingForm&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.city, city) || other.city == city)&&(identical(other.plotLength, plotLength) || other.plotLength == plotLength)&&(identical(other.plotBreadth, plotBreadth) || other.plotBreadth == plotBreadth)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.floors, floors) || other.floors == floors)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.facing, facing) || other.facing == facing)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.pricePaise, pricePaise) || other.pricePaise == pricePaise));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,city,plotLength,plotBreadth,unit,floors,bedrooms,facing,const DeepCollectionEquality().hash(tags),isFree,pricePaise);

@override
String toString() {
  return 'DrawingForm(title: $title, description: $description, categoryId: $categoryId, city: $city, plotLength: $plotLength, plotBreadth: $plotBreadth, unit: $unit, floors: $floors, bedrooms: $bedrooms, facing: $facing, tags: $tags, isFree: $isFree, pricePaise: $pricePaise)';
}


}

/// @nodoc
abstract mixin class $DrawingFormCopyWith<$Res>  {
  factory $DrawingFormCopyWith(DrawingForm value, $Res Function(DrawingForm) _then) = _$DrawingFormCopyWithImpl;
@useResult
$Res call({
 String title, String description, String? categoryId, String city, double? plotLength, double? plotBreadth, PlotUnit unit, int? floors, int? bedrooms, String? facing, List<String> tags, bool isFree, int pricePaise
});




}
/// @nodoc
class _$DrawingFormCopyWithImpl<$Res>
    implements $DrawingFormCopyWith<$Res> {
  _$DrawingFormCopyWithImpl(this._self, this._then);

  final DrawingForm _self;
  final $Res Function(DrawingForm) _then;

/// Create a copy of DrawingForm
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? description = null,Object? categoryId = freezed,Object? city = null,Object? plotLength = freezed,Object? plotBreadth = freezed,Object? unit = null,Object? floors = freezed,Object? bedrooms = freezed,Object? facing = freezed,Object? tags = null,Object? isFree = null,Object? pricePaise = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,plotLength: freezed == plotLength ? _self.plotLength : plotLength // ignore: cast_nullable_to_non_nullable
as double?,plotBreadth: freezed == plotBreadth ? _self.plotBreadth : plotBreadth // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as PlotUnit,floors: freezed == floors ? _self.floors : floors // ignore: cast_nullable_to_non_nullable
as int?,bedrooms: freezed == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int?,facing: freezed == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,pricePaise: null == pricePaise ? _self.pricePaise : pricePaise // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DrawingForm].
extension DrawingFormPatterns on DrawingForm {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawingForm value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawingForm() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawingForm value)  $default,){
final _that = this;
switch (_that) {
case _DrawingForm():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawingForm value)?  $default,){
final _that = this;
switch (_that) {
case _DrawingForm() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String description,  String? categoryId,  String city,  double? plotLength,  double? plotBreadth,  PlotUnit unit,  int? floors,  int? bedrooms,  String? facing,  List<String> tags,  bool isFree,  int pricePaise)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawingForm() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.city,_that.plotLength,_that.plotBreadth,_that.unit,_that.floors,_that.bedrooms,_that.facing,_that.tags,_that.isFree,_that.pricePaise);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String description,  String? categoryId,  String city,  double? plotLength,  double? plotBreadth,  PlotUnit unit,  int? floors,  int? bedrooms,  String? facing,  List<String> tags,  bool isFree,  int pricePaise)  $default,) {final _that = this;
switch (_that) {
case _DrawingForm():
return $default(_that.title,_that.description,_that.categoryId,_that.city,_that.plotLength,_that.plotBreadth,_that.unit,_that.floors,_that.bedrooms,_that.facing,_that.tags,_that.isFree,_that.pricePaise);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String description,  String? categoryId,  String city,  double? plotLength,  double? plotBreadth,  PlotUnit unit,  int? floors,  int? bedrooms,  String? facing,  List<String> tags,  bool isFree,  int pricePaise)?  $default,) {final _that = this;
switch (_that) {
case _DrawingForm() when $default != null:
return $default(_that.title,_that.description,_that.categoryId,_that.city,_that.plotLength,_that.plotBreadth,_that.unit,_that.floors,_that.bedrooms,_that.facing,_that.tags,_that.isFree,_that.pricePaise);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DrawingForm extends DrawingForm {
  const _DrawingForm({this.title = '', this.description = '', this.categoryId, this.city = '', this.plotLength, this.plotBreadth, this.unit = PlotUnit.ft, this.floors, this.bedrooms, this.facing, final  List<String> tags = const <String>[], this.isFree = false, this.pricePaise = 0}): _tags = tags,super._();
  factory _DrawingForm.fromJson(Map<String, dynamic> json) => _$DrawingFormFromJson(json);

@override@JsonKey() final  String title;
@override@JsonKey() final  String description;
@override final  String? categoryId;
@override@JsonKey() final  String city;
@override final  double? plotLength;
@override final  double? plotBreadth;
@override@JsonKey() final  PlotUnit unit;
@override final  int? floors;
@override final  int? bedrooms;
@override final  String? facing;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  bool isFree;
// Integer paise; 0 while unset. Ignored when [isFree].
@override@JsonKey() final  int pricePaise;

/// Create a copy of DrawingForm
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawingFormCopyWith<_DrawingForm> get copyWith => __$DrawingFormCopyWithImpl<_DrawingForm>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrawingFormToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawingForm&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.city, city) || other.city == city)&&(identical(other.plotLength, plotLength) || other.plotLength == plotLength)&&(identical(other.plotBreadth, plotBreadth) || other.plotBreadth == plotBreadth)&&(identical(other.unit, unit) || other.unit == unit)&&(identical(other.floors, floors) || other.floors == floors)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.facing, facing) || other.facing == facing)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.pricePaise, pricePaise) || other.pricePaise == pricePaise));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,description,categoryId,city,plotLength,plotBreadth,unit,floors,bedrooms,facing,const DeepCollectionEquality().hash(_tags),isFree,pricePaise);

@override
String toString() {
  return 'DrawingForm(title: $title, description: $description, categoryId: $categoryId, city: $city, plotLength: $plotLength, plotBreadth: $plotBreadth, unit: $unit, floors: $floors, bedrooms: $bedrooms, facing: $facing, tags: $tags, isFree: $isFree, pricePaise: $pricePaise)';
}


}

/// @nodoc
abstract mixin class _$DrawingFormCopyWith<$Res> implements $DrawingFormCopyWith<$Res> {
  factory _$DrawingFormCopyWith(_DrawingForm value, $Res Function(_DrawingForm) _then) = __$DrawingFormCopyWithImpl;
@override @useResult
$Res call({
 String title, String description, String? categoryId, String city, double? plotLength, double? plotBreadth, PlotUnit unit, int? floors, int? bedrooms, String? facing, List<String> tags, bool isFree, int pricePaise
});




}
/// @nodoc
class __$DrawingFormCopyWithImpl<$Res>
    implements _$DrawingFormCopyWith<$Res> {
  __$DrawingFormCopyWithImpl(this._self, this._then);

  final _DrawingForm _self;
  final $Res Function(_DrawingForm) _then;

/// Create a copy of DrawingForm
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? description = null,Object? categoryId = freezed,Object? city = null,Object? plotLength = freezed,Object? plotBreadth = freezed,Object? unit = null,Object? floors = freezed,Object? bedrooms = freezed,Object? facing = freezed,Object? tags = null,Object? isFree = null,Object? pricePaise = null,}) {
  return _then(_DrawingForm(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,categoryId: freezed == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,plotLength: freezed == plotLength ? _self.plotLength : plotLength // ignore: cast_nullable_to_non_nullable
as double?,plotBreadth: freezed == plotBreadth ? _self.plotBreadth : plotBreadth // ignore: cast_nullable_to_non_nullable
as double?,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as PlotUnit,floors: freezed == floors ? _self.floors : floors // ignore: cast_nullable_to_non_nullable
as int?,bedrooms: freezed == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int?,facing: freezed == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,pricePaise: null == pricePaise ? _self.pricePaise : pricePaise // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
