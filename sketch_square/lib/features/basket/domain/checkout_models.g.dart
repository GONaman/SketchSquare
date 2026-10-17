// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckoutOrder _$CheckoutOrderFromJson(Map<String, dynamic> json) =>
    _CheckoutOrder(
      orderId: json['orderId'] as String,
      razorpayKeyId: json['razorpayKeyId'] as String,
      amountPaise: (json['amountPaise'] as num).toInt(),
      currency: json['currency'] as String? ?? 'INR',
      purchaseIds:
          (json['purchaseIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$CheckoutOrderToJson(_CheckoutOrder instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'razorpayKeyId': instance.razorpayKeyId,
      'amountPaise': instance.amountPaise,
      'currency': instance.currency,
      'purchaseIds': instance.purchaseIds,
    };
