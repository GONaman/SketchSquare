// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'drawing_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DrawingViewer {

 bool get isOwner; bool get isPurchased; bool get inCart; bool get canDownload; int? get freeDownloadsRemaining; Review? get myReview; bool get isFavorite; bool get isInterested;
/// Create a copy of DrawingViewer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingViewerCopyWith<DrawingViewer> get copyWith => _$DrawingViewerCopyWithImpl<DrawingViewer>(this as DrawingViewer, _$identity);

  /// Serializes this DrawingViewer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingViewer&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&(identical(other.isPurchased, isPurchased) || other.isPurchased == isPurchased)&&(identical(other.inCart, inCart) || other.inCart == inCart)&&(identical(other.canDownload, canDownload) || other.canDownload == canDownload)&&(identical(other.freeDownloadsRemaining, freeDownloadsRemaining) || other.freeDownloadsRemaining == freeDownloadsRemaining)&&(identical(other.myReview, myReview) || other.myReview == myReview)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isInterested, isInterested) || other.isInterested == isInterested));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOwner,isPurchased,inCart,canDownload,freeDownloadsRemaining,myReview,isFavorite,isInterested);

@override
String toString() {
  return 'DrawingViewer(isOwner: $isOwner, isPurchased: $isPurchased, inCart: $inCart, canDownload: $canDownload, freeDownloadsRemaining: $freeDownloadsRemaining, myReview: $myReview, isFavorite: $isFavorite, isInterested: $isInterested)';
}


}

/// @nodoc
abstract mixin class $DrawingViewerCopyWith<$Res>  {
  factory $DrawingViewerCopyWith(DrawingViewer value, $Res Function(DrawingViewer) _then) = _$DrawingViewerCopyWithImpl;
@useResult
$Res call({
 bool isOwner, bool isPurchased, bool inCart, bool canDownload, int? freeDownloadsRemaining, Review? myReview, bool isFavorite, bool isInterested
});


$ReviewCopyWith<$Res>? get myReview;

}
/// @nodoc
class _$DrawingViewerCopyWithImpl<$Res>
    implements $DrawingViewerCopyWith<$Res> {
  _$DrawingViewerCopyWithImpl(this._self, this._then);

  final DrawingViewer _self;
  final $Res Function(DrawingViewer) _then;

/// Create a copy of DrawingViewer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOwner = null,Object? isPurchased = null,Object? inCart = null,Object? canDownload = null,Object? freeDownloadsRemaining = freezed,Object? myReview = freezed,Object? isFavorite = null,Object? isInterested = null,}) {
  return _then(_self.copyWith(
isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,isPurchased: null == isPurchased ? _self.isPurchased : isPurchased // ignore: cast_nullable_to_non_nullable
as bool,inCart: null == inCart ? _self.inCart : inCart // ignore: cast_nullable_to_non_nullable
as bool,canDownload: null == canDownload ? _self.canDownload : canDownload // ignore: cast_nullable_to_non_nullable
as bool,freeDownloadsRemaining: freezed == freeDownloadsRemaining ? _self.freeDownloadsRemaining : freeDownloadsRemaining // ignore: cast_nullable_to_non_nullable
as int?,myReview: freezed == myReview ? _self.myReview : myReview // ignore: cast_nullable_to_non_nullable
as Review?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isInterested: null == isInterested ? _self.isInterested : isInterested // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of DrawingViewer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get myReview {
    if (_self.myReview == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.myReview!, (value) {
    return _then(_self.copyWith(myReview: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrawingViewer].
extension DrawingViewerPatterns on DrawingViewer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawingViewer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawingViewer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawingViewer value)  $default,){
final _that = this;
switch (_that) {
case _DrawingViewer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawingViewer value)?  $default,){
final _that = this;
switch (_that) {
case _DrawingViewer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOwner,  bool isPurchased,  bool inCart,  bool canDownload,  int? freeDownloadsRemaining,  Review? myReview,  bool isFavorite,  bool isInterested)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawingViewer() when $default != null:
return $default(_that.isOwner,_that.isPurchased,_that.inCart,_that.canDownload,_that.freeDownloadsRemaining,_that.myReview,_that.isFavorite,_that.isInterested);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOwner,  bool isPurchased,  bool inCart,  bool canDownload,  int? freeDownloadsRemaining,  Review? myReview,  bool isFavorite,  bool isInterested)  $default,) {final _that = this;
switch (_that) {
case _DrawingViewer():
return $default(_that.isOwner,_that.isPurchased,_that.inCart,_that.canDownload,_that.freeDownloadsRemaining,_that.myReview,_that.isFavorite,_that.isInterested);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOwner,  bool isPurchased,  bool inCart,  bool canDownload,  int? freeDownloadsRemaining,  Review? myReview,  bool isFavorite,  bool isInterested)?  $default,) {final _that = this;
switch (_that) {
case _DrawingViewer() when $default != null:
return $default(_that.isOwner,_that.isPurchased,_that.inCart,_that.canDownload,_that.freeDownloadsRemaining,_that.myReview,_that.isFavorite,_that.isInterested);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DrawingViewer implements DrawingViewer {
  const _DrawingViewer({this.isOwner = false, this.isPurchased = false, this.inCart = false, this.canDownload = false, this.freeDownloadsRemaining, this.myReview, this.isFavorite = false, this.isInterested = false});
  factory _DrawingViewer.fromJson(Map<String, dynamic> json) => _$DrawingViewerFromJson(json);

@override@JsonKey() final  bool isOwner;
@override@JsonKey() final  bool isPurchased;
@override@JsonKey() final  bool inCart;
@override@JsonKey() final  bool canDownload;
@override final  int? freeDownloadsRemaining;
@override final  Review? myReview;
@override@JsonKey() final  bool isFavorite;
@override@JsonKey() final  bool isInterested;

/// Create a copy of DrawingViewer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawingViewerCopyWith<_DrawingViewer> get copyWith => __$DrawingViewerCopyWithImpl<_DrawingViewer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DrawingViewerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawingViewer&&(identical(other.isOwner, isOwner) || other.isOwner == isOwner)&&(identical(other.isPurchased, isPurchased) || other.isPurchased == isPurchased)&&(identical(other.inCart, inCart) || other.inCart == inCart)&&(identical(other.canDownload, canDownload) || other.canDownload == canDownload)&&(identical(other.freeDownloadsRemaining, freeDownloadsRemaining) || other.freeDownloadsRemaining == freeDownloadsRemaining)&&(identical(other.myReview, myReview) || other.myReview == myReview)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite)&&(identical(other.isInterested, isInterested) || other.isInterested == isInterested));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOwner,isPurchased,inCart,canDownload,freeDownloadsRemaining,myReview,isFavorite,isInterested);

@override
String toString() {
  return 'DrawingViewer(isOwner: $isOwner, isPurchased: $isPurchased, inCart: $inCart, canDownload: $canDownload, freeDownloadsRemaining: $freeDownloadsRemaining, myReview: $myReview, isFavorite: $isFavorite, isInterested: $isInterested)';
}


}

/// @nodoc
abstract mixin class _$DrawingViewerCopyWith<$Res> implements $DrawingViewerCopyWith<$Res> {
  factory _$DrawingViewerCopyWith(_DrawingViewer value, $Res Function(_DrawingViewer) _then) = __$DrawingViewerCopyWithImpl;
@override @useResult
$Res call({
 bool isOwner, bool isPurchased, bool inCart, bool canDownload, int? freeDownloadsRemaining, Review? myReview, bool isFavorite, bool isInterested
});


@override $ReviewCopyWith<$Res>? get myReview;

}
/// @nodoc
class __$DrawingViewerCopyWithImpl<$Res>
    implements _$DrawingViewerCopyWith<$Res> {
  __$DrawingViewerCopyWithImpl(this._self, this._then);

  final _DrawingViewer _self;
  final $Res Function(_DrawingViewer) _then;

/// Create a copy of DrawingViewer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOwner = null,Object? isPurchased = null,Object? inCart = null,Object? canDownload = null,Object? freeDownloadsRemaining = freezed,Object? myReview = freezed,Object? isFavorite = null,Object? isInterested = null,}) {
  return _then(_DrawingViewer(
isOwner: null == isOwner ? _self.isOwner : isOwner // ignore: cast_nullable_to_non_nullable
as bool,isPurchased: null == isPurchased ? _self.isPurchased : isPurchased // ignore: cast_nullable_to_non_nullable
as bool,inCart: null == inCart ? _self.inCart : inCart // ignore: cast_nullable_to_non_nullable
as bool,canDownload: null == canDownload ? _self.canDownload : canDownload // ignore: cast_nullable_to_non_nullable
as bool,freeDownloadsRemaining: freezed == freeDownloadsRemaining ? _self.freeDownloadsRemaining : freeDownloadsRemaining // ignore: cast_nullable_to_non_nullable
as int?,myReview: freezed == myReview ? _self.myReview : myReview // ignore: cast_nullable_to_non_nullable
as Review?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,isInterested: null == isInterested ? _self.isInterested : isInterested // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of DrawingViewer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReviewCopyWith<$Res>? get myReview {
    if (_self.myReview == null) {
    return null;
  }

  return $ReviewCopyWith<$Res>(_self.myReview!, (value) {
    return _then(_self.copyWith(myReview: value));
  });
}
}

/// @nodoc
mixin _$DrawingDetail {

 DrawingSummary get summary; String get description; int get viewCount; int get purchaseCount; String? get failureReason; List<Sheet> get sheets; CursorPage<Review> get reviews; DrawingViewer get viewer;
/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DrawingDetailCopyWith<DrawingDetail> get copyWith => _$DrawingDetailCopyWithImpl<DrawingDetail>(this as DrawingDetail, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DrawingDetail&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.description, description) || other.description == description)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&const DeepCollectionEquality().equals(other.sheets, sheets)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.viewer, viewer) || other.viewer == viewer));
}


@override
int get hashCode => Object.hash(runtimeType,summary,description,viewCount,purchaseCount,failureReason,const DeepCollectionEquality().hash(sheets),reviews,viewer);

@override
String toString() {
  return 'DrawingDetail(summary: $summary, description: $description, viewCount: $viewCount, purchaseCount: $purchaseCount, failureReason: $failureReason, sheets: $sheets, reviews: $reviews, viewer: $viewer)';
}


}

/// @nodoc
abstract mixin class $DrawingDetailCopyWith<$Res>  {
  factory $DrawingDetailCopyWith(DrawingDetail value, $Res Function(DrawingDetail) _then) = _$DrawingDetailCopyWithImpl;
@useResult
$Res call({
 DrawingSummary summary, String description, int viewCount, int purchaseCount, String? failureReason, List<Sheet> sheets, CursorPage<Review> reviews, DrawingViewer viewer
});


$DrawingSummaryCopyWith<$Res> get summary;$DrawingViewerCopyWith<$Res> get viewer;

}
/// @nodoc
class _$DrawingDetailCopyWithImpl<$Res>
    implements $DrawingDetailCopyWith<$Res> {
  _$DrawingDetailCopyWithImpl(this._self, this._then);

  final DrawingDetail _self;
  final $Res Function(DrawingDetail) _then;

/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? summary = null,Object? description = null,Object? viewCount = null,Object? purchaseCount = null,Object? failureReason = freezed,Object? sheets = null,Object? reviews = null,Object? viewer = null,}) {
  return _then(_self.copyWith(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DrawingSummary,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,sheets: null == sheets ? _self.sheets : sheets // ignore: cast_nullable_to_non_nullable
as List<Sheet>,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as CursorPage<Review>,viewer: null == viewer ? _self.viewer : viewer // ignore: cast_nullable_to_non_nullable
as DrawingViewer,
  ));
}
/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawingSummaryCopyWith<$Res> get summary {
  
  return $DrawingSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawingViewerCopyWith<$Res> get viewer {
  
  return $DrawingViewerCopyWith<$Res>(_self.viewer, (value) {
    return _then(_self.copyWith(viewer: value));
  });
}
}


/// Adds pattern-matching-related methods to [DrawingDetail].
extension DrawingDetailPatterns on DrawingDetail {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DrawingDetail value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DrawingDetail() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DrawingDetail value)  $default,){
final _that = this;
switch (_that) {
case _DrawingDetail():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DrawingDetail value)?  $default,){
final _that = this;
switch (_that) {
case _DrawingDetail() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DrawingSummary summary,  String description,  int viewCount,  int purchaseCount,  String? failureReason,  List<Sheet> sheets,  CursorPage<Review> reviews,  DrawingViewer viewer)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DrawingDetail() when $default != null:
return $default(_that.summary,_that.description,_that.viewCount,_that.purchaseCount,_that.failureReason,_that.sheets,_that.reviews,_that.viewer);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DrawingSummary summary,  String description,  int viewCount,  int purchaseCount,  String? failureReason,  List<Sheet> sheets,  CursorPage<Review> reviews,  DrawingViewer viewer)  $default,) {final _that = this;
switch (_that) {
case _DrawingDetail():
return $default(_that.summary,_that.description,_that.viewCount,_that.purchaseCount,_that.failureReason,_that.sheets,_that.reviews,_that.viewer);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DrawingSummary summary,  String description,  int viewCount,  int purchaseCount,  String? failureReason,  List<Sheet> sheets,  CursorPage<Review> reviews,  DrawingViewer viewer)?  $default,) {final _that = this;
switch (_that) {
case _DrawingDetail() when $default != null:
return $default(_that.summary,_that.description,_that.viewCount,_that.purchaseCount,_that.failureReason,_that.sheets,_that.reviews,_that.viewer);case _:
  return null;

}
}

}

/// @nodoc


class _DrawingDetail extends DrawingDetail {
  const _DrawingDetail({required this.summary, this.description = '', this.viewCount = 0, this.purchaseCount = 0, this.failureReason, final  List<Sheet> sheets = const <Sheet>[], this.reviews = const CursorPage<Review>(items: []), this.viewer = const DrawingViewer()}): _sheets = sheets,super._();
  

@override final  DrawingSummary summary;
@override@JsonKey() final  String description;
@override@JsonKey() final  int viewCount;
@override@JsonKey() final  int purchaseCount;
@override final  String? failureReason;
 final  List<Sheet> _sheets;
@override@JsonKey() List<Sheet> get sheets {
  if (_sheets is EqualUnmodifiableListView) return _sheets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sheets);
}

@override@JsonKey() final  CursorPage<Review> reviews;
@override@JsonKey() final  DrawingViewer viewer;

/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DrawingDetailCopyWith<_DrawingDetail> get copyWith => __$DrawingDetailCopyWithImpl<_DrawingDetail>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DrawingDetail&&(identical(other.summary, summary) || other.summary == summary)&&(identical(other.description, description) || other.description == description)&&(identical(other.viewCount, viewCount) || other.viewCount == viewCount)&&(identical(other.purchaseCount, purchaseCount) || other.purchaseCount == purchaseCount)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&const DeepCollectionEquality().equals(other._sheets, _sheets)&&(identical(other.reviews, reviews) || other.reviews == reviews)&&(identical(other.viewer, viewer) || other.viewer == viewer));
}


@override
int get hashCode => Object.hash(runtimeType,summary,description,viewCount,purchaseCount,failureReason,const DeepCollectionEquality().hash(_sheets),reviews,viewer);

@override
String toString() {
  return 'DrawingDetail(summary: $summary, description: $description, viewCount: $viewCount, purchaseCount: $purchaseCount, failureReason: $failureReason, sheets: $sheets, reviews: $reviews, viewer: $viewer)';
}


}

/// @nodoc
abstract mixin class _$DrawingDetailCopyWith<$Res> implements $DrawingDetailCopyWith<$Res> {
  factory _$DrawingDetailCopyWith(_DrawingDetail value, $Res Function(_DrawingDetail) _then) = __$DrawingDetailCopyWithImpl;
@override @useResult
$Res call({
 DrawingSummary summary, String description, int viewCount, int purchaseCount, String? failureReason, List<Sheet> sheets, CursorPage<Review> reviews, DrawingViewer viewer
});


@override $DrawingSummaryCopyWith<$Res> get summary;@override $DrawingViewerCopyWith<$Res> get viewer;

}
/// @nodoc
class __$DrawingDetailCopyWithImpl<$Res>
    implements _$DrawingDetailCopyWith<$Res> {
  __$DrawingDetailCopyWithImpl(this._self, this._then);

  final _DrawingDetail _self;
  final $Res Function(_DrawingDetail) _then;

/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? summary = null,Object? description = null,Object? viewCount = null,Object? purchaseCount = null,Object? failureReason = freezed,Object? sheets = null,Object? reviews = null,Object? viewer = null,}) {
  return _then(_DrawingDetail(
summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DrawingSummary,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,viewCount: null == viewCount ? _self.viewCount : viewCount // ignore: cast_nullable_to_non_nullable
as int,purchaseCount: null == purchaseCount ? _self.purchaseCount : purchaseCount // ignore: cast_nullable_to_non_nullable
as int,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,sheets: null == sheets ? _self._sheets : sheets // ignore: cast_nullable_to_non_nullable
as List<Sheet>,reviews: null == reviews ? _self.reviews : reviews // ignore: cast_nullable_to_non_nullable
as CursorPage<Review>,viewer: null == viewer ? _self.viewer : viewer // ignore: cast_nullable_to_non_nullable
as DrawingViewer,
  ));
}

/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawingSummaryCopyWith<$Res> get summary {
  
  return $DrawingSummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}/// Create a copy of DrawingDetail
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawingViewerCopyWith<$Res> get viewer {
  
  return $DrawingViewerCopyWith<$Res>(_self.viewer, (value) {
    return _then(_self.copyWith(viewer: value));
  });
}
}

// dart format on
