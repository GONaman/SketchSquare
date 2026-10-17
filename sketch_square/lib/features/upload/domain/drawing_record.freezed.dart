// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrawingRecord {

 String get id; String get title; String get description; CategoryRef? get category; String get city; double get plotLengthFt; double get plotBreadthFt; double get plotAreaSqft; int get floors; int? get bedrooms; String? get facing; List<String> get tags; int get pricePaise; bool get isFree; DrawingStatus get status; String? get failureReason; List<DrawingSheet> get sheets; String? get previewUrl; int get viewCount; int get purchaseCount;
/// Create a copy of DrawingRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingRecordCopyWith<DrawingRecord> get copyWith => _$DrawingRecordCopyWithImpl<DrawingRecord>(this as DrawingRecord, _$identity);

  /// Serializes this DrawingRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.city, city) || other.city == city)&&(identical(other.plotLengthFt, plotLengthFt) || other.plotLengthFt == plotLengthFt)&&(identical(other.plotBreadthFt, plotBreadthFt) || other.plotBreadthFt == plotBreadthFt)&&(identical(other.plotAreaSqft, plotAreaSqft) || other.plotAreaSqft == plotAreaSqft)&&(identical(other.floors, floors) || other.floors == floors)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.facing, facing) || other.facing == facing)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.pricePaise, pricePaise) || other.pricePaise == pricePaise)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.status, status) || other.status == status)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&const DeepCollectionEquality().equals(other.sheets, sheets)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,category,city,plotLengthFt,plotBreadthFt,plotAreaSqft,floors,bedrooms,facing,const DeepCollectionEquality().hash(tags),pricePaise,isFree,status,failureReason,const DeepCollectionEquality().hash(sheets),previewUrl,viewCount,purchaseCount]);

@override
String toString() {
  return 'DrawingRecord(id: $id, title: $title, description: $description, category: $category, city: $city, plotLengthFt: $plotLengthFt, plotBreadthFt: $plotBreadthFt, plotAreaSqft: $plotAreaSqft, floors: $floors, bedrooms: $bedrooms, facing: $facing, tags: $tags, pricePaise: $pricePaise, isFree: $isFree, status: $status, failureReason: $failureReason, sheets: $sheets, previewUrl: $previewUrl, viewCount: $viewCount, purchaseCount: $purchaseCount)';
}


}

/// @nodoc
abstract mixin class $DrawingRecordCopyWith<$Res>  {
  factory $DrawingRecordCopyWith(DrawingRecord value, $Res Function(DrawingRecord) _then) = _$DrawingRecordCopyWithImpl;
@useResult
$Res call({
 String id, String title, String description, CategoryRef? category, String city, double plotLengthFt, double plotBreadthFt, double plotAreaSqft, int floors, int? bedrooms, String? facing, List<String> tags, int pricePaise, bool isFree, DrawingStatus status, String? failureReason, List<DrawingSheet> sheets, String? previewUrl, int viewCount, int purchaseCount
});


$CategoryRefCopyWith<$Res>? get category;

}
/// @nodoc
class _$DrawingRecordCopyWithImpl<$Res>
    implements $DrawingRecordCopyWith<$Res> {
  _$DrawingRecordCopyWithImpl(this._self, this._then);

  final DrawingRecord _self;
  final $Res Function(DrawingRecord) _then;

/// Create a copy of DrawingRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = freezed,Object? city = null,Object? plotLengthFt = null,Object? plotBreadthFt = null,Object? plotAreaSqft = null,Object? floors = null,Object? bedrooms = freezed,Object? facing = freezed,Object? tags = null,Object? pricePaise = null,Object? isFree = null,Object? status = null,Object? failureReason = freezed,Object? sheets = null,Object? previewUrl = freezed,Object? viewCount = null,Object? purchaseCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryRef?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,plotLengthFt: null == plotLengthFt ? _self.plotLengthFt : plotLengthFt // ignore: cast_nullable_to_non_nullable
as double,plotBreadthFt: null == plotBreadthFt ? _self.plotBreadthFt : plotBreadthFt // ignore: cast_nullable_to_non_nullable
as double,plotAreaSqft: null == plotAreaSqft ? _self.plotAreaSqft : plotAreaSqft // ignore: cast_nullable_to_non_nullable
as double,floors: null == floors ? _self.floors : floors // ignore: cast_nullable_to_non_nullable
as int,bedrooms: freezed == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int?,facing: freezed == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,pricePaise: null == pricePaise ? _self.pricePaise : pricePaise // ignore: cast_nullable_to_non_nullable
as int,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DrawingStatus,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,sheets: null == sheets ? _self.sheets : sheets // ignore: cast_nullable_to_non_nullable
as List<DrawingSheet>,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of DrawingRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryRefCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryRefCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrawingRecord].
extension DrawingRecordPatterns on DrawingRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawingRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawingRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawingRecord value)  $default,){
final _that = this;
switch (_that) {
case _DrawingRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawingRecord value)?  $default,){
final _that = this;
switch (_that) {
case _DrawingRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String description,  CategoryRef? category,  String city,  double plotLengthFt,  double plotBreadthFt,  double plotAreaSqft,  int floors,  int? bedrooms,  String? facing,  List<String> tags,  int pricePaise,  bool isFree,  DrawingStatus status,  String? failureReason,  List<DrawingSheet> sheets,  String? previewUrl,  int viewCount,  int purchaseCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawingRecord() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.city,_that.plotLengthFt,_that.plotBreadthFt,_that.plotAreaSqft,_that.floors,_that.bedrooms,_that.facing,_that.tags,_that.pricePaise,_that.isFree,_that.status,_that.failureReason,_that.sheets,_that.previewUrl,_that.viewCount,_that.purchaseCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String description,  CategoryRef? category,  String city,  double plotLengthFt,  double plotBreadthFt,  double plotAreaSqft,  int floors,  int? bedrooms,  String? facing,  List<String> tags,  int pricePaise,  bool isFree,  DrawingStatus status,  String? failureReason,  List<DrawingSheet> sheets,  String? previewUrl,  int viewCount,  int purchaseCount)  $default,) {final _that = this;
switch (_that) {
case _DrawingRecord():
return $default(_that.id,_that.title,_that.description,_that.category,_that.city,_that.plotLengthFt,_that.plotBreadthFt,_that.plotAreaSqft,_that.floors,_that.bedrooms,_that.facing,_that.tags,_that.pricePaise,_that.isFree,_that.status,_that.failureReason,_that.sheets,_that.previewUrl,_that.viewCount,_that.purchaseCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String description,  CategoryRef? category,  String city,  double plotLengthFt,  double plotBreadthFt,  double plotAreaSqft,  int floors,  int? bedrooms,  String? facing,  List<String> tags,  int pricePaise,  bool isFree,  DrawingStatus status,  String? failureReason,  List<DrawingSheet> sheets,  String? previewUrl,  int viewCount,  int purchaseCount)?  $default,) {final _that = this;
switch (_that) {
case _DrawingRecord() when $default != null:
return $default(_that.id,_that.title,_that.description,_that.category,_that.city,_that.plotLengthFt,_that.plotBreadthFt,_that.plotAreaSqft,_that.floors,_that.bedrooms,_that.facing,_that.tags,_that.pricePaise,_that.isFree,_that.status,_that.failureReason,_that.sheets,_that.previewUrl,_that.viewCount,_that.purchaseCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DrawingRecord extends DrawingRecord {
  const _DrawingRecord({required this.id, required this.title, this.description = '', this.category, this.city = '', this.plotLengthFt = 0, this.plotBreadthFt = 0, this.plotAreaSqft = 0, this.floors = 1, this.bedrooms, this.facing, final  List<String> tags = const <String>[], this.pricePaise = 0, this.isFree = false, required this.status, this.failureReason, final  List<DrawingSheet> sheets = const <DrawingSheet>[], this.previewUrl, this.viewCount = 0, this.purchaseCount = 0}): _tags = tags,_sheets = sheets,super._();
  factory _DrawingRecord.fromJson(Map<String, dynamic> json) => _$DrawingRecordFromJson(json);

@override final  String id;
@override final  String title;
@override@JsonKey() final  String description;
@override final  CategoryRef? category;
@override@JsonKey() final  String city;
@override@JsonKey() final  double plotLengthFt;
@override@JsonKey() final  double plotBreadthFt;
@override@JsonKey() final  double plotAreaSqft;
@override@JsonKey() final  int floors;
@override final  int? bedrooms;
@override final  String? facing;
 final  List<String> _tags;
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override@JsonKey() final  int pricePaise;
@override@JsonKey() final  bool isFree;
@override final  DrawingStatus status;
@override final  String? failureReason;
 final  List<DrawingSheet> _sheets;
@override@JsonKey() List<DrawingSheet> get sheets {
  if (_sheets is EqualUnmodifiableListView) return _sheets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sheets);
}

@override final  String? previewUrl;
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  int purchaseCount;

/// Create a copy of DrawingRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawingRecordCopyWith<_DrawingRecord> get copyWith => __$DrawingRecordCopyWithImpl<_DrawingRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrawingRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawingRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.city, city) || other.city == city)&&(identical(other.plotLengthFt, plotLengthFt) || other.plotLengthFt == plotLengthFt)&&(identical(other.plotBreadthFt, plotBreadthFt) || other.plotBreadthFt == plotBreadthFt)&&(identical(other.plotAreaSqft, plotAreaSqft) || other.plotAreaSqft == plotAreaSqft)&&(identical(other.floors, floors) || other.floors == floors)&&(identical(other.bedrooms, bedrooms) || other.bedrooms == bedrooms)&&(identical(other.facing, facing) || other.facing == facing)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.pricePaise, pricePaise) || other.pricePaise == pricePaise)&&(identical(other.isFree, isFree) || other.isFree == isFree)&&(identical(other.status, status) || other.status == status)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&const DeepCollectionEquality().equals(other._sheets, _sheets)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,title,description,category,city,plotLengthFt,plotBreadthFt,plotAreaSqft,floors,bedrooms,facing,const DeepCollectionEquality().hash(_tags),pricePaise,isFree,status,failureReason,const DeepCollectionEquality().hash(_sheets),previewUrl,viewCount,purchaseCount]);

@override
String toString() {
  return 'DrawingRecord(id: $id, title: $title, description: $description, category: $category, city: $city, plotLengthFt: $plotLengthFt, plotBreadthFt: $plotBreadthFt, plotAreaSqft: $plotAreaSqft, floors: $floors, bedrooms: $bedrooms, facing: $facing, tags: $tags, pricePaise: $pricePaise, isFree: $isFree, status: $status, failureReason: $failureReason, sheets: $sheets, previewUrl: $previewUrl, viewCount: $viewCount, purchaseCount: $purchaseCount)';
}


}

/// @nodoc
abstract mixin class _$DrawingRecordCopyWith<$Res> implements $DrawingRecordCopyWith<$Res> {
  factory _$DrawingRecordCopyWith(_DrawingRecord value, $Res Function(_DrawingRecord) _then) = __$DrawingRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String description, CategoryRef? category, String city, double plotLengthFt, double plotBreadthFt, double plotAreaSqft, int floors, int? bedrooms, String? facing, List<String> tags, int pricePaise, bool isFree, DrawingStatus status, String? failureReason, List<DrawingSheet> sheets, String? previewUrl, int viewCount, int purchaseCount
});


@override $CategoryRefCopyWith<$Res>? get category;

}
/// @nodoc
class __$DrawingRecordCopyWithImpl<$Res>
    implements _$DrawingRecordCopyWith<$Res> {
  __$DrawingRecordCopyWithImpl(this._self, this._then);

  final _DrawingRecord _self;
  final $Res Function(_DrawingRecord) _then;

/// Create a copy of DrawingRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? description = null,Object? category = freezed,Object? city = null,Object? plotLengthFt = null,Object? plotBreadthFt = null,Object? plotAreaSqft = null,Object? floors = null,Object? bedrooms = freezed,Object? facing = freezed,Object? tags = null,Object? pricePaise = null,Object? isFree = null,Object? status = null,Object? failureReason = freezed,Object? sheets = null,Object? previewUrl = freezed,Object? viewCount = null,Object? purchaseCount = null,}) {
  return _then(_DrawingRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as CategoryRef?,city: null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,plotLengthFt: null == plotLengthFt ? _self.plotLengthFt : plotLengthFt // ignore: cast_nullable_to_non_nullable
as double,plotBreadthFt: null == plotBreadthFt ? _self.plotBreadthFt : plotBreadthFt // ignore: cast_nullable_to_non_nullable
as double,plotAreaSqft: null == plotAreaSqft ? _self.plotAreaSqft : plotAreaSqft // ignore: cast_nullable_to_non_nullable
as double,floors: null == floors ? _self.floors : floors // ignore: cast_nullable_to_non_nullable
as int,bedrooms: freezed == bedrooms ? _self.bedrooms : bedrooms // ignore: cast_nullable_to_non_nullable
as int?,facing: freezed == facing ? _self.facing : facing // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,pricePaise: null == pricePaise ? _self.pricePaise : pricePaise // ignore: cast_nullable_to_non_nullable
as int,isFree: null == isFree ? _self.isFree : isFree // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DrawingStatus,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,sheets: null == sheets ? _self._sheets : sheets // ignore: cast_nullable_to_non_nullable
as List<DrawingSheet>,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of DrawingRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CategoryRefCopyWith<$Res>? get category {
    if (_self.category == null) {
    return null;
  }

  return $CategoryRefCopyWith<$Res>(_self.category!, (value) {
    return _then(_self.copyWith(category: value));
  });
}
}

// dart format on
