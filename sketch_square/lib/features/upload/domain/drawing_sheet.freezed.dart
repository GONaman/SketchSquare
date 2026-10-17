// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_sheet.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrawingSheet {

 String get id; SheetType get type; bool get isPreview; String? get previewUrl; String get originalMime; String get fileName; int get sizeBytes;
/// Create a copy of DrawingSheet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingSheetCopyWith<DrawingSheet> get copyWith => _$DrawingSheetCopyWithImpl<DrawingSheet>(this as DrawingSheet, _$identity);

  /// Serializes this DrawingSheet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingSheet&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPreview, isPreview) || other.isPreview == isPreview)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.originalMime, originalMime) || other.originalMime == originalMime)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,isPreview,previewUrl,originalMime,fileName,sizeBytes);

@override
String toString() {
  return 'DrawingSheet(id: $id, type: $type, isPreview: $isPreview, previewUrl: $previewUrl, originalMime: $originalMime, fileName: $fileName, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class $DrawingSheetCopyWith<$Res>  {
  factory $DrawingSheetCopyWith(DrawingSheet value, $Res Function(DrawingSheet) _then) = _$DrawingSheetCopyWithImpl;
@useResult
$Res call({
 String id, SheetType type, bool isPreview, String? previewUrl, String originalMime, String fileName, int sizeBytes
});




}
/// @nodoc
class _$DrawingSheetCopyWithImpl<$Res>
    implements $DrawingSheetCopyWith<$Res> {
  _$DrawingSheetCopyWithImpl(this._self, this._then);

  final DrawingSheet _self;
  final $Res Function(DrawingSheet) _then;

/// Create a copy of DrawingSheet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? isPreview = null,Object? previewUrl = freezed,Object? originalMime = null,Object? fileName = null,Object? sizeBytes = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SheetType,isPreview: null == isPreview ? _self.isPreview : isPreview // ignore: cast_nullable_to_non_nullable
as bool,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,originalMime: null == originalMime ? _self.originalMime : originalMime // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DrawingSheet].
extension DrawingSheetPatterns on DrawingSheet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawingSheet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawingSheet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawingSheet value)  $default,){
final _that = this;
switch (_that) {
case _DrawingSheet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawingSheet value)?  $default,){
final _that = this;
switch (_that) {
case _DrawingSheet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SheetType type,  bool isPreview,  String? previewUrl,  String originalMime,  String fileName,  int sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawingSheet() when $default != null:
return $default(_that.id,_that.type,_that.isPreview,_that.previewUrl,_that.originalMime,_that.fileName,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SheetType type,  bool isPreview,  String? previewUrl,  String originalMime,  String fileName,  int sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _DrawingSheet():
return $default(_that.id,_that.type,_that.isPreview,_that.previewUrl,_that.originalMime,_that.fileName,_that.sizeBytes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SheetType type,  bool isPreview,  String? previewUrl,  String originalMime,  String fileName,  int sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _DrawingSheet() when $default != null:
return $default(_that.id,_that.type,_that.isPreview,_that.previewUrl,_that.originalMime,_that.fileName,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DrawingSheet implements DrawingSheet {
  const _DrawingSheet({required this.id, this.type = SheetType.other, this.isPreview = false, this.previewUrl, this.originalMime = '', required this.fileName, this.sizeBytes = 0});
  factory _DrawingSheet.fromJson(Map<String, dynamic> json) => _$DrawingSheetFromJson(json);

@override final  String id;
@override@JsonKey() final  SheetType type;
@override@JsonKey() final  bool isPreview;
@override final  String? previewUrl;
@override@JsonKey() final  String originalMime;
@override final  String fileName;
@override@JsonKey() final  int sizeBytes;

/// Create a copy of DrawingSheet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawingSheetCopyWith<_DrawingSheet> get copyWith => __$DrawingSheetCopyWithImpl<_DrawingSheet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrawingSheetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawingSheet&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPreview, isPreview) || other.isPreview == isPreview)&&(identical(other.previewUrl, previewUrl) || other.previewUrl == previewUrl)&&(identical(other.originalMime, originalMime) || other.originalMime == originalMime)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,isPreview,previewUrl,originalMime,fileName,sizeBytes);

@override
String toString() {
  return 'DrawingSheet(id: $id, type: $type, isPreview: $isPreview, previewUrl: $previewUrl, originalMime: $originalMime, fileName: $fileName, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$DrawingSheetCopyWith<$Res> implements $DrawingSheetCopyWith<$Res> {
  factory _$DrawingSheetCopyWith(_DrawingSheet value, $Res Function(_DrawingSheet) _then) = __$DrawingSheetCopyWithImpl;
@override @useResult
$Res call({
 String id, SheetType type, bool isPreview, String? previewUrl, String originalMime, String fileName, int sizeBytes
});




}
/// @nodoc
class __$DrawingSheetCopyWithImpl<$Res>
    implements _$DrawingSheetCopyWith<$Res> {
  __$DrawingSheetCopyWithImpl(this._self, this._then);

  final _DrawingSheet _self;
  final $Res Function(_DrawingSheet) _then;

/// Create a copy of DrawingSheet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? isPreview = null,Object? previewUrl = freezed,Object? originalMime = null,Object? fileName = null,Object? sizeBytes = null,}) {
  return _then(_DrawingSheet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SheetType,isPreview: null == isPreview ? _self.isPreview : isPreview // ignore: cast_nullable_to_non_nullable
as bool,previewUrl: freezed == previewUrl ? _self.previewUrl : previewUrl // ignore: cast_nullable_to_non_nullable
as String?,originalMime: null == originalMime ? _self.originalMime : originalMime // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
