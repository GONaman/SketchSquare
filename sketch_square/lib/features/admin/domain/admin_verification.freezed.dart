// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'admin_verification.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AdminApplicant {

 String get id; String get fullName; String get email; String? get phone; String? get city; String? get address;
/// Create a copy of AdminApplicant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminApplicantCopyWith<AdminApplicant> get copyWith => _$AdminApplicantCopyWithImpl<AdminApplicant>(this as AdminApplicant, _$identity);

  /// Serializes this AdminApplicant to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminApplicant&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,phone,city,address);

@override
String toString() {
  return 'AdminApplicant(id: $id, fullName: $fullName, email: $email, phone: $phone, city: $city, address: $address)';
}


}

/// @nodoc
abstract mixin class $AdminApplicantCopyWith<$Res>  {
  factory $AdminApplicantCopyWith(AdminApplicant value, $Res Function(AdminApplicant) _then) = _$AdminApplicantCopyWithImpl;
@useResult
$Res call({
 String id, String fullName, String email, String? phone, String? city, String? address
});




}
/// @nodoc
class _$AdminApplicantCopyWithImpl<$Res>
    implements $AdminApplicantCopyWith<$Res> {
  _$AdminApplicantCopyWithImpl(this._self, this._then);

  final AdminApplicant _self;
  final $Res Function(AdminApplicant) _then;

/// Create a copy of AdminApplicant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? phone = freezed,Object? city = freezed,Object? address = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AdminApplicant].
extension AdminApplicantPatterns on AdminApplicant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminApplicant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminApplicant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminApplicant value)  $default,){
final _that = this;
switch (_that) {
case _AdminApplicant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminApplicant value)?  $default,){
final _that = this;
switch (_that) {
case _AdminApplicant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String fullName,  String email,  String? phone,  String? city,  String? address)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminApplicant() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.phone,_that.city,_that.address);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String fullName,  String email,  String? phone,  String? city,  String? address)  $default,) {final _that = this;
switch (_that) {
case _AdminApplicant():
return $default(_that.id,_that.fullName,_that.email,_that.phone,_that.city,_that.address);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String fullName,  String email,  String? phone,  String? city,  String? address)?  $default,) {final _that = this;
switch (_that) {
case _AdminApplicant() when $default != null:
return $default(_that.id,_that.fullName,_that.email,_that.phone,_that.city,_that.address);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminApplicant implements AdminApplicant {
  const _AdminApplicant({required this.id, required this.fullName, required this.email, this.phone, this.city, this.address});
  factory _AdminApplicant.fromJson(Map<String, dynamic> json) => _$AdminApplicantFromJson(json);

@override final  String id;
@override final  String fullName;
@override final  String email;
@override final  String? phone;
@override final  String? city;
@override final  String? address;

/// Create a copy of AdminApplicant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminApplicantCopyWith<_AdminApplicant> get copyWith => __$AdminApplicantCopyWithImpl<_AdminApplicant>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminApplicantToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminApplicant&&(identical(other.id, id) || other.id == id)&&(identical(other.fullName, fullName) || other.fullName == fullName)&&(identical(other.email, email) || other.email == email)&&(identical(other.phone, phone) || other.phone == phone)&&(identical(other.city, city) || other.city == city)&&(identical(other.address, address) || other.address == address));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,fullName,email,phone,city,address);

@override
String toString() {
  return 'AdminApplicant(id: $id, fullName: $fullName, email: $email, phone: $phone, city: $city, address: $address)';
}


}

/// @nodoc
abstract mixin class _$AdminApplicantCopyWith<$Res> implements $AdminApplicantCopyWith<$Res> {
  factory _$AdminApplicantCopyWith(_AdminApplicant value, $Res Function(_AdminApplicant) _then) = __$AdminApplicantCopyWithImpl;
@override @useResult
$Res call({
 String id, String fullName, String email, String? phone, String? city, String? address
});




}
/// @nodoc
class __$AdminApplicantCopyWithImpl<$Res>
    implements _$AdminApplicantCopyWith<$Res> {
  __$AdminApplicantCopyWithImpl(this._self, this._then);

  final _AdminApplicant _self;
  final $Res Function(_AdminApplicant) _then;

/// Create a copy of AdminApplicant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? fullName = null,Object? email = null,Object? phone = freezed,Object? city = freezed,Object? address = freezed,}) {
  return _then(_AdminApplicant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,fullName: null == fullName ? _self.fullName : fullName // ignore: cast_nullable_to_non_nullable
as String,email: null == email ? _self.email : email // ignore: cast_nullable_to_non_nullable
as String,phone: freezed == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String?,city: freezed == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$AdminVerification {

 String get id; VerificationStatus get status; String get coaRegistrationNumber; DateTime get submittedAt; AdminApplicant get user; String? get documentUrl; String? get reviewNote;
/// Create a copy of AdminVerification
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AdminVerificationCopyWith<AdminVerification> get copyWith => _$AdminVerificationCopyWithImpl<AdminVerification>(this as AdminVerification, _$identity);

  /// Serializes this AdminVerification to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AdminVerification&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.coaRegistrationNumber, coaRegistrationNumber) || other.coaRegistrationNumber == coaRegistrationNumber)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.documentUrl, documentUrl) || other.documentUrl == documentUrl)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,coaRegistrationNumber,submittedAt,user,documentUrl,reviewNote);

@override
String toString() {
  return 'AdminVerification(id: $id, status: $status, coaRegistrationNumber: $coaRegistrationNumber, submittedAt: $submittedAt, user: $user, documentUrl: $documentUrl, reviewNote: $reviewNote)';
}


}

/// @nodoc
abstract mixin class $AdminVerificationCopyWith<$Res>  {
  factory $AdminVerificationCopyWith(AdminVerification value, $Res Function(AdminVerification) _then) = _$AdminVerificationCopyWithImpl;
@useResult
$Res call({
 String id, VerificationStatus status, String coaRegistrationNumber, DateTime submittedAt, AdminApplicant user, String? documentUrl, String? reviewNote
});


$AdminApplicantCopyWith<$Res> get user;

}
/// @nodoc
class _$AdminVerificationCopyWithImpl<$Res>
    implements $AdminVerificationCopyWith<$Res> {
  _$AdminVerificationCopyWithImpl(this._self, this._then);

  final AdminVerification _self;
  final $Res Function(AdminVerification) _then;

/// Create a copy of AdminVerification
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? coaRegistrationNumber = null,Object? submittedAt = null,Object? user = null,Object? documentUrl = freezed,Object? reviewNote = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,coaRegistrationNumber: null == coaRegistrationNumber ? _self.coaRegistrationNumber : coaRegistrationNumber // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AdminApplicant,documentUrl: freezed == documentUrl ? _self.documentUrl : documentUrl // ignore: cast_nullable_to_non_nullable
as String?,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of AdminVerification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminApplicantCopyWith<$Res> get user {
  
  return $AdminApplicantCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [AdminVerification].
extension AdminVerificationPatterns on AdminVerification {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AdminVerification value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AdminVerification() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AdminVerification value)  $default,){
final _that = this;
switch (_that) {
case _AdminVerification():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AdminVerification value)?  $default,){
final _that = this;
switch (_that) {
case _AdminVerification() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  VerificationStatus status,  String coaRegistrationNumber,  DateTime submittedAt,  AdminApplicant user,  String? documentUrl,  String? reviewNote)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AdminVerification() when $default != null:
return $default(_that.id,_that.status,_that.coaRegistrationNumber,_that.submittedAt,_that.user,_that.documentUrl,_that.reviewNote);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  VerificationStatus status,  String coaRegistrationNumber,  DateTime submittedAt,  AdminApplicant user,  String? documentUrl,  String? reviewNote)  $default,) {final _that = this;
switch (_that) {
case _AdminVerification():
return $default(_that.id,_that.status,_that.coaRegistrationNumber,_that.submittedAt,_that.user,_that.documentUrl,_that.reviewNote);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  VerificationStatus status,  String coaRegistrationNumber,  DateTime submittedAt,  AdminApplicant user,  String? documentUrl,  String? reviewNote)?  $default,) {final _that = this;
switch (_that) {
case _AdminVerification() when $default != null:
return $default(_that.id,_that.status,_that.coaRegistrationNumber,_that.submittedAt,_that.user,_that.documentUrl,_that.reviewNote);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AdminVerification implements AdminVerification {
  const _AdminVerification({required this.id, required this.status, required this.coaRegistrationNumber, required this.submittedAt, required this.user, this.documentUrl, this.reviewNote});
  factory _AdminVerification.fromJson(Map<String, dynamic> json) => _$AdminVerificationFromJson(json);

@override final  String id;
@override final  VerificationStatus status;
@override final  String coaRegistrationNumber;
@override final  DateTime submittedAt;
@override final  AdminApplicant user;
@override final  String? documentUrl;
@override final  String? reviewNote;

/// Create a copy of AdminVerification
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AdminVerificationCopyWith<_AdminVerification> get copyWith => __$AdminVerificationCopyWithImpl<_AdminVerification>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AdminVerificationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AdminVerification&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.coaRegistrationNumber, coaRegistrationNumber) || other.coaRegistrationNumber == coaRegistrationNumber)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.user, user) || other.user == user)&&(identical(other.documentUrl, documentUrl) || other.documentUrl == documentUrl)&&(identical(other.reviewNote, reviewNote) || other.reviewNote == reviewNote));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,coaRegistrationNumber,submittedAt,user,documentUrl,reviewNote);

@override
String toString() {
  return 'AdminVerification(id: $id, status: $status, coaRegistrationNumber: $coaRegistrationNumber, submittedAt: $submittedAt, user: $user, documentUrl: $documentUrl, reviewNote: $reviewNote)';
}


}

/// @nodoc
abstract mixin class _$AdminVerificationCopyWith<$Res> implements $AdminVerificationCopyWith<$Res> {
  factory _$AdminVerificationCopyWith(_AdminVerification value, $Res Function(_AdminVerification) _then) = __$AdminVerificationCopyWithImpl;
@override @useResult
$Res call({
 String id, VerificationStatus status, String coaRegistrationNumber, DateTime submittedAt, AdminApplicant user, String? documentUrl, String? reviewNote
});


@override $AdminApplicantCopyWith<$Res> get user;

}
/// @nodoc
class __$AdminVerificationCopyWithImpl<$Res>
    implements _$AdminVerificationCopyWith<$Res> {
  __$AdminVerificationCopyWithImpl(this._self, this._then);

  final _AdminVerification _self;
  final $Res Function(_AdminVerification) _then;

/// Create a copy of AdminVerification
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? coaRegistrationNumber = null,Object? submittedAt = null,Object? user = null,Object? documentUrl = freezed,Object? reviewNote = freezed,}) {
  return _then(_AdminVerification(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as VerificationStatus,coaRegistrationNumber: null == coaRegistrationNumber ? _self.coaRegistrationNumber : coaRegistrationNumber // ignore: cast_nullable_to_non_nullable
as String,submittedAt: null == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime,user: null == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as AdminApplicant,documentUrl: freezed == documentUrl ? _self.documentUrl : documentUrl // ignore: cast_nullable_to_non_nullable
as String?,reviewNote: freezed == reviewNote ? _self.reviewNote : reviewNote // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of AdminVerification
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdminApplicantCopyWith<$Res> get user {
  
  return $AdminApplicantCopyWith<$Res>(_self.user, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}

// dart format on
