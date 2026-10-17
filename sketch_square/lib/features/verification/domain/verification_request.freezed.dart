// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'verification_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VerificationRequest {

 String get id; String get coaRegistrationNumber; VerificationStatus get status; String? get reviewNote; DateTime get submittedAt; DateTime? get reviewedAt;
/// Create a copy of VerificationRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VerificationRequestCopyWith<VerificationRequest> get copyWith => _$VerificationRequestCopyWithImpl<VerificationRequest>(this as VerificationRequest, _$identity);

  /// Serializes this VerificationRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VerificationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.coaRegistrationNumber, coaRegistrationNumber) || other.coaRegistrationNumber == coaRegistrationNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,coaRegistrationNumber,status,reviewNote,submittedAt,reviewedAt);

@override
String toString() {
  return 'VerificationRequest(id: $id, coaRegistrationNumber: $coaRegistrationNumber, status: $status, reviewNote: $reviewNote, submittedAt: $submittedAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class $VerificationRequestCopyWith<$Res>  {
  factory $VerificationRequestCopyWith(VerificationRequest value, $Res Function(VerificationRequest) _then) = _$VerificationRequestCopyWithImpl;
@useResult
$Res call({
 String id, String coaRegistrationNumber, VerificationStatus status, String? reviewNote, DateTime submittedAt, DateTime? reviewedAt
});




}
/// @nodoc
class _$VerificationRequestCopyWithImpl<$Res>
    implements $VerificationRequestCopyWith<$Res> {
  _$VerificationRequestCopyWithImpl(this._self, this._then);

  final VerificationRequest _self;
  final $Res Function(VerificationRequest) _then;

/// Create a copy of VerificationRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? coaRegistrationNumber = null,Object? status = null,Object? reviewNote = freezed,Object? submittedAt = null,Object? reviewedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,coaRegistrationNumber: null == coaRegistrationNumber ? _self.coaRegistrationNumber : coaRegistrationNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [VerificationRequest].
extension VerificationRequestPatterns on VerificationRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VerificationRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VerificationRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VerificationRequest value)  $default,){
final _that = this;
switch (_that) {
case _VerificationRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VerificationRequest value)?  $default,){
final _that = this;
switch (_that) {
case _VerificationRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String coaRegistrationNumber,  VerificationStatus status,  String? reviewNote,  DateTime submittedAt,  DateTime? reviewedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VerificationRequest() when $default != null:
return $default(_that.id,_that.coaRegistrationNumber,_that.status,_that.reviewNote,_that.submittedAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String coaRegistrationNumber,  VerificationStatus status,  String? reviewNote,  DateTime submittedAt,  DateTime? reviewedAt)  $default,) {final _that = this;
switch (_that) {
case _VerificationRequest():
return $default(_that.id,_that.coaRegistrationNumber,_that.status,_that.reviewNote,_that.submittedAt,_that.reviewedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String coaRegistrationNumber,  VerificationStatus status,  String? reviewNote,  DateTime submittedAt,  DateTime? reviewedAt)?  $default,) {final _that = this;
switch (_that) {
case _VerificationRequest() when $default != null:
return $default(_that.id,_that.coaRegistrationNumber,_that.status,_that.reviewNote,_that.submittedAt,_that.reviewedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VerificationRequest implements VerificationRequest {
  const _VerificationRequest({required this.id, required this.coaRegistrationNumber, required this.status, this.reviewNote, required this.submittedAt, this.reviewedAt});
  factory _VerificationRequest.fromJson(Map<String, dynamic> json) => _$VerificationRequestFromJson(json);

@override final  String id;
@override final  String coaRegistrationNumber;
@override final  VerificationStatus status;
@override final  String? reviewNote;
@override final  DateTime submittedAt;
@override final  DateTime? reviewedAt;

/// Create a copy of VerificationRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VerificationRequestCopyWith<_VerificationRequest> get copyWith => __$VerificationRequestCopyWithImpl<_VerificationRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VerificationRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VerificationRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.coaRegistrationNumber, coaRegistrationNumber) || other.coaRegistrationNumber == coaRegistrationNumber)&&(identical(other.status, status) || other.status == status)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.reviewedAt, reviewedAt) || other.reviewedAt == reviewedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,coaRegistrationNumber,status,reviewNote,submittedAt,reviewedAt);

@override
String toString() {
  return 'VerificationRequest(id: $id, coaRegistrationNumber: $coaRegistrationNumber, status: $status, reviewNote: $reviewNote, submittedAt: $submittedAt, reviewedAt: $reviewedAt)';
}


}

/// @nodoc
abstract mixin class _$VerificationRequestCopyWith<$Res> implements $VerificationRequestCopyWith<$Res> {
  factory _$VerificationRequestCopyWith(_VerificationRequest value, $Res Function(_VerificationRequest) _then) = __$VerificationRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String coaRegistrationNumber, VerificationStatus status, String? reviewNote, DateTime submittedAt, DateTime? reviewedAt
});




}
/// @nodoc
class __$VerificationRequestCopyWithImpl<$Res>
    implements _$VerificationRequestCopyWith<$Res> {
  __$VerificationRequestCopyWithImpl(this._self, this._then);

  final _VerificationRequest _self;
  final $Res Function(_VerificationRequest) _then;

/// Create a copy of VerificationRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? coaRegistrationNumber = null,Object? status = null,Object? reviewNote = freezed,Object? submittedAt = null,Object? reviewedAt = freezed,}) {
  return _then(_VerificationRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,coaRegistrationNumber: null == coaRegistrationNumber ? _self.coaRegistrationNumber : coaRegistrationNumber // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,reviewedAt: freezed == reviewedAt ? _self.reviewedAt : reviewedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
