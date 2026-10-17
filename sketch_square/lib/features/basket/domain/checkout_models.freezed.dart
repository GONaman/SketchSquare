// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkout_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CheckoutOrder {

 String get orderId; String get razorpayKeyId; int get amountPaise; String get currency; List<String> get purchaseIds;
/// Create a copy of CheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutOrderCopyWith<CheckoutOrder> get copyWith => _$CheckoutOrderCopyWithImpl<CheckoutOrder>(this as CheckoutOrder, _$identity);

  /// Serializes this CheckoutOrder to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.razorpayKeyId, razorpayKeyId) || other.razorpayKeyId == razorpayKeyId)&&(identical(other.amountPaise, amountPaise) || other.amountPaise == amountPaise)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.purchaseIds, purchaseIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,razorpayKeyId,amountPaise,currency,const DeepCollectionEquality().hash(purchaseIds));

@override
String toString() {
  return 'CheckoutOrder(orderId: $orderId, razorpayKeyId: $razorpayKeyId, amountPaise: $amountPaise, currency: $currency, purchaseIds: $purchaseIds)';
}


}

/// @nodoc
abstract mixin class $CheckoutOrderCopyWith<$Res>  {
  factory $CheckoutOrderCopyWith(CheckoutOrder value, $Res Function(CheckoutOrder) _then) = _$CheckoutOrderCopyWithImpl;
@useResult
$Res call({
 String orderId, String razorpayKeyId, int amountPaise, String currency, List<String> purchaseIds
});




}
/// @nodoc
class _$CheckoutOrderCopyWithImpl<$Res>
    implements $CheckoutOrderCopyWith<$Res> {
  _$CheckoutOrderCopyWithImpl(this._self, this._then);

  final CheckoutOrder _self;
  final $Res Function(CheckoutOrder) _then;

/// Create a copy of CheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orderId = null,Object? razorpayKeyId = null,Object? amountPaise = null,Object? currency = null,Object? purchaseIds = null,}) {
  return _then(_self.copyWith(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,razorpayKeyId: null == razorpayKeyId ? _self.razorpayKeyId : razorpayKeyId // ignore: cast_nullable_to_non_nullable
as String,amountPaise: null == amountPaise ? _self.amountPaise : amountPaise // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,purchaseIds: null == purchaseIds ? _self.purchaseIds : purchaseIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckoutOrder].
extension CheckoutOrderPatterns on CheckoutOrder {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutOrder value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutOrder() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutOrder value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutOrder():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutOrder value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutOrder() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String orderId,  String razorpayKeyId,  int amountPaise,  String currency,  List<String> purchaseIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutOrder() when $default != null:
return $default(_that.orderId,_that.razorpayKeyId,_that.amountPaise,_that.currency,_that.purchaseIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String orderId,  String razorpayKeyId,  int amountPaise,  String currency,  List<String> purchaseIds)  $default,) {final _that = this;
switch (_that) {
case _CheckoutOrder():
return $default(_that.orderId,_that.razorpayKeyId,_that.amountPaise,_that.currency,_that.purchaseIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String orderId,  String razorpayKeyId,  int amountPaise,  String currency,  List<String> purchaseIds)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutOrder() when $default != null:
return $default(_that.orderId,_that.razorpayKeyId,_that.amountPaise,_that.currency,_that.purchaseIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckoutOrder extends CheckoutOrder {
  const _CheckoutOrder({required this.orderId, required this.razorpayKeyId, required this.amountPaise, this.currency = 'INR', final  List<String> purchaseIds = const []}): _purchaseIds = purchaseIds,super._();
  factory _CheckoutOrder.fromJson(Map<String, dynamic> json) => _$CheckoutOrderFromJson(json);

@override final  String orderId;
@override final  String razorpayKeyId;
@override final  int amountPaise;
@override@JsonKey() final  String currency;
 final  List<String> _purchaseIds;
@override@JsonKey() List<String> get purchaseIds {
  if (_purchaseIds is EqualUnmodifiableListView) return _purchaseIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_purchaseIds);
}


/// Create a copy of CheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutOrderCopyWith<_CheckoutOrder> get copyWith => __$CheckoutOrderCopyWithImpl<_CheckoutOrder>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckoutOrderToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutOrder&&(identical(other.orderId, orderId) || other.orderId == orderId)&&(identical(other.razorpayKeyId, razorpayKeyId) || other.razorpayKeyId == razorpayKeyId)&&(identical(other.amountPaise, amountPaise) || other.amountPaise == amountPaise)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._purchaseIds, _purchaseIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orderId,razorpayKeyId,amountPaise,currency,const DeepCollectionEquality().hash(_purchaseIds));

@override
String toString() {
  return 'CheckoutOrder(orderId: $orderId, razorpayKeyId: $razorpayKeyId, amountPaise: $amountPaise, currency: $currency, purchaseIds: $purchaseIds)';
}


}

/// @nodoc
abstract mixin class _$CheckoutOrderCopyWith<$Res> implements $CheckoutOrderCopyWith<$Res> {
  factory _$CheckoutOrderCopyWith(_CheckoutOrder value, $Res Function(_CheckoutOrder) _then) = __$CheckoutOrderCopyWithImpl;
@override @useResult
$Res call({
 String orderId, String razorpayKeyId, int amountPaise, String currency, List<String> purchaseIds
});




}
/// @nodoc
class __$CheckoutOrderCopyWithImpl<$Res>
    implements _$CheckoutOrderCopyWith<$Res> {
  __$CheckoutOrderCopyWithImpl(this._self, this._then);

  final _CheckoutOrder _self;
  final $Res Function(_CheckoutOrder) _then;

/// Create a copy of CheckoutOrder
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orderId = null,Object? razorpayKeyId = null,Object? amountPaise = null,Object? currency = null,Object? purchaseIds = null,}) {
  return _then(_CheckoutOrder(
orderId: null == orderId ? _self.orderId : orderId // ignore: cast_nullable_to_non_nullable
as String,razorpayKeyId: null == razorpayKeyId ? _self.razorpayKeyId : razorpayKeyId // ignore: cast_nullable_to_non_nullable
as String,amountPaise: null == amountPaise ? _self.amountPaise : amountPaise // ignore: cast_nullable_to_non_nullable
as int,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,purchaseIds: null == purchaseIds ? _self._purchaseIds : purchaseIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
