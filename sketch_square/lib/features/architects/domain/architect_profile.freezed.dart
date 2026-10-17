// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'architect_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TopArchitect {

 ArchitectSummary get architect; int get drawingCount;
/// Create a copy of TopArchitect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TopArchitectCopyWith<TopArchitect> get copyWith => _$TopArchitectCopyWithImpl<TopArchitect>(this as TopArchitect, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TopArchitect&&(identical(other.architect, architect) || other.architect == architect)&&(identical(other.drawingCount, drawingCount) || other.drawingCount == drawingCount));
}


@override
int get hashCode => Object.hash(runtimeType,architect,drawingCount);

@override
String toString() {
  return 'TopArchitect(architect: $architect, drawingCount: $drawingCount)';
}


}

/// @nodoc
abstract mixin class $TopArchitectCopyWith<$Res>  {
  factory $TopArchitectCopyWith(TopArchitect value, $Res Function(TopArchitect) _then) = _$TopArchitectCopyWithImpl;
@useResult
$Res call({
 ArchitectSummary architect, int drawingCount
});


$ArchitectSummaryCopyWith<$Res> get architect;

}
/// @nodoc
class _$TopArchitectCopyWithImpl<$Res>
    implements $TopArchitectCopyWith<$Res> {
  _$TopArchitectCopyWithImpl(this._self, this._then);

  final TopArchitect _self;
  final $Res Function(TopArchitect) _then;

/// Create a copy of TopArchitect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? architect = null,Object? drawingCount = null,}) {
  return _then(_self.copyWith(
architect: null == architect ? _self.architect : architect // ignore: cast_nullable_to_non_nullable
as ArchitectSummary,drawingCount: null == drawingCount ? _self.drawingCount : drawingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of TopArchitect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArchitectSummaryCopyWith<$Res> get architect {
  
  return $ArchitectSummaryCopyWith<$Res>(_self.architect, (value) {
    return _then(_self.copyWith(architect: value));
  });
}
}


/// Adds pattern-matching-related methods to [TopArchitect].
extension TopArchitectPatterns on TopArchitect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TopArchitect value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TopArchitect() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TopArchitect value)  $default,){
final _that = this;
switch (_that) {
case _TopArchitect():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TopArchitect value)?  $default,){
final _that = this;
switch (_that) {
case _TopArchitect() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ArchitectSummary architect,  int drawingCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TopArchitect() when $default != null:
return $default(_that.architect,_that.drawingCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ArchitectSummary architect,  int drawingCount)  $default,) {final _that = this;
switch (_that) {
case _TopArchitect():
return $default(_that.architect,_that.drawingCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ArchitectSummary architect,  int drawingCount)?  $default,) {final _that = this;
switch (_that) {
case _TopArchitect() when $default != null:
return $default(_that.architect,_that.drawingCount);case _:
  return null;

}
}

}

/// @nodoc


class _TopArchitect implements TopArchitect {
  const _TopArchitect({required this.architect, this.drawingCount = 0});
  

@override final  ArchitectSummary architect;
@override@JsonKey() final  int drawingCount;

/// Create a copy of TopArchitect
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TopArchitectCopyWith<_TopArchitect> get copyWith => __$TopArchitectCopyWithImpl<_TopArchitect>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TopArchitect&&(identical(other.architect, architect) || other.architect == architect)&&(identical(other.drawingCount, drawingCount) || other.drawingCount == drawingCount));
}


@override
int get hashCode => Object.hash(runtimeType,architect,drawingCount);

@override
String toString() {
  return 'TopArchitect(architect: $architect, drawingCount: $drawingCount)';
}


}

/// @nodoc
abstract mixin class _$TopArchitectCopyWith<$Res> implements $TopArchitectCopyWith<$Res> {
  factory _$TopArchitectCopyWith(_TopArchitect value, $Res Function(_TopArchitect) _then) = __$TopArchitectCopyWithImpl;
@override @useResult
$Res call({
 ArchitectSummary architect, int drawingCount
});


@override $ArchitectSummaryCopyWith<$Res> get architect;

}
/// @nodoc
class __$TopArchitectCopyWithImpl<$Res>
    implements _$TopArchitectCopyWith<$Res> {
  __$TopArchitectCopyWithImpl(this._self, this._then);

  final _TopArchitect _self;
  final $Res Function(_TopArchitect) _then;

/// Create a copy of TopArchitect
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? architect = null,Object? drawingCount = null,}) {
  return _then(_TopArchitect(
architect: null == architect ? _self.architect : architect // ignore: cast_nullable_to_non_nullable
as ArchitectSummary,drawingCount: null == drawingCount ? _self.drawingCount : drawingCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of TopArchitect
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArchitectSummaryCopyWith<$Res> get architect {
  
  return $ArchitectSummaryCopyWith<$Res>(_self.architect, (value) {
    return _then(_self.copyWith(architect: value));
  });
}
}

/// @nodoc
mixin _$ArchitectProfile {

 ArchitectSummary get architect; CursorPage<DrawingSummary> get drawings;
/// Create a copy of ArchitectProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArchitectProfileCopyWith<ArchitectProfile> get copyWith => _$ArchitectProfileCopyWithImpl<ArchitectProfile>(this as ArchitectProfile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArchitectProfile&&(identical(other.architect, architect) || other.architect == architect)&&(identical(other.drawings, drawings) || other.drawings == drawings));
}


@override
int get hashCode => Object.hash(runtimeType,architect,drawings);

@override
String toString() {
  return 'ArchitectProfile(architect: $architect, drawings: $drawings)';
}


}

/// @nodoc
abstract mixin class $ArchitectProfileCopyWith<$Res>  {
  factory $ArchitectProfileCopyWith(ArchitectProfile value, $Res Function(ArchitectProfile) _then) = _$ArchitectProfileCopyWithImpl;
@useResult
$Res call({
 ArchitectSummary architect, CursorPage<DrawingSummary> drawings
});


$ArchitectSummaryCopyWith<$Res> get architect;

}
/// @nodoc
class _$ArchitectProfileCopyWithImpl<$Res>
    implements $ArchitectProfileCopyWith<$Res> {
  _$ArchitectProfileCopyWithImpl(this._self, this._then);

  final ArchitectProfile _self;
  final $Res Function(ArchitectProfile) _then;

/// Create a copy of ArchitectProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? architect = null,Object? drawings = null,}) {
  return _then(_self.copyWith(
architect: null == architect ? _self.architect : architect // ignore: cast_nullable_to_non_nullable
as ArchitectSummary,drawings: null == drawings ? _self.drawings : drawings // ignore: cast_nullable_to_non_nullable
as CursorPage<DrawingSummary>,
  ));
}
/// Create a copy of ArchitectProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ArchitectSummaryCopyWith<$Res> get architect {
  
  return $ArchitectSummaryCopyWith<$Res>(_self.architect, (value) {
    return _then(_self.copyWith(architect: value));
  });
}
}


/// Adds pattern-matching-related methods to [ArchitectProfile].
extension ArchitectProfilePatterns on ArchitectProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArchitectProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArchitectProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArchitectProfile value)  $default,){
final _that = this;
switch (_that) {
case _ArchitectProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArchitectProfile value)?  $default,){
final _that = this;
switch (_that) {
case _ArchitectProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ArchitectSummary architect,  CursorPage<DrawingSummary> drawings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArchitectProfile() when $default != null:
return $default(_that.architect,_that.drawings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ArchitectSummary architect,  CursorPage<DrawingSummary> drawings)  $default,) {final _that = this;
switch (_that) {
case _ArchitectProfile():
return $default(_that.architect,_that.drawings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ArchitectSummary architect,  CursorPage<DrawingSummary> drawings)?  $default,) {final _that = this;
switch (_that) {
case _ArchitectProfile() when $default != null:
return $default(_that.architect,_that.drawings);case _:
  return null;

}
}

}

/// @nodoc


class _ArchitectProfile implements ArchitectProfile {
  const _ArchitectProfile({required this.architect, required this.drawings});
  

@override final  ArchitectSummary architect;
@override final  CursorPage<DrawingSummary> drawings;

/// Create a copy of ArchitectProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArchitectProfileCopyWith<_ArchitectProfile> get copyWith => __$ArchitectProfileCopyWithImpl<_ArchitectProfile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArchitectProfile&&(identical(other.architect, architect) || other.architect == architect)&&(identical(other.drawings, drawings) || other.drawings == drawings));
}


@override
int get hashCode => Object.hash(runtimeType,architect,drawings);

@override
String toString() {
  return 'ArchitectProfile(architect: $architect, drawings: $drawings)';
}


}

/// @nodoc
abstract mixin class _$ArchitectProfileCopyWith<$Res> implements $ArchitectProfileCopyWith<$Res> {
  factory _$ArchitectProfileCopyWith(_ArchitectProfile value, $Res Function(_ArchitectProfile) _then) = __$ArchitectProfileCopyWithImpl;
@override @useResult
$Res call({
 ArchitectSummary architect, CursorPage<DrawingSummary> drawings
});


@override $ArchitectSummaryCopyWith<$Res> get architect;

}
/// @nodoc
class __$ArchitectProfileCopyWithImpl<$Res>
    implements _$ArchitectProfileCopyWith<$Res> {
  __$ArchitectProfileCopyWithImpl(this._self, this._then);

  final _ArchitectProfile _self;
  final $Res Function(_ArchitectProfile) _then;

/// Create a copy of ArchitectProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? architect = null,Object? drawings = null,}) {
  return _then(_ArchitectProfile(
architect: null == architect ? _self.architect : architect // ignore: cast_nullable_to_non_nullable
as ArchitectSummary,drawings: null == drawings ? _self.drawings : drawings // ignore: cast_nullable_to_non_nullable
as CursorPage<DrawingSummary>,
  ));
}

/// Create a copy of ArchitectProfile
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
