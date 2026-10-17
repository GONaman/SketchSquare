// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_flow_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SheetItem {

 String get localId; String get name; int get sizeBytes; SheetType get type; bool get isPreview; SheetUploadStatus get status;// 0..1 while uploading.
 double get progress; String? get serverSheetId;// Kept after a successful PUT so a failed registration retries without re-uploading.
 String? get objectKey; String? get error; PickedSheetFile? get file;
/// Create a copy of SheetItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SheetItemCopyWith<SheetItem> get copyWith => _$SheetItemCopyWithImpl<SheetItem>(this as SheetItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SheetItem&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPreview, isPreview) || other.isPreview == isPreview)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.serverSheetId, serverSheetId) || other.serverSheetId == serverSheetId)&&(identical(other.objectKey, objectKey) || other.objectKey == objectKey)&&(identical(other.error, error) || other.error == error)&&(identical(other.file, file) || other.file == file));
}


@override
int get hashCode => Object.hash(runtimeType,localId,name,sizeBytes,type,isPreview,status,progress,serverSheetId,objectKey,error,file);

@override
String toString() {
  return 'SheetItem(localId: $localId, name: $name, sizeBytes: $sizeBytes, type: $type, isPreview: $isPreview, status: $status, progress: $progress, serverSheetId: $serverSheetId, objectKey: $objectKey, error: $error, file: $file)';
}


}

/// @nodoc
abstract mixin class $SheetItemCopyWith<$Res>  {
  factory $SheetItemCopyWith(SheetItem value, $Res Function(SheetItem) _then) = _$SheetItemCopyWithImpl;
@useResult
$Res call({
 String localId, String name, int sizeBytes, SheetType type, bool isPreview, SheetUploadStatus status, double progress, String? serverSheetId, String? objectKey, String? error, PickedSheetFile? file
});




}
/// @nodoc
class _$SheetItemCopyWithImpl<$Res>
    implements $SheetItemCopyWith<$Res> {
  _$SheetItemCopyWithImpl(this._self, this._then);

  final SheetItem _self;
  final $Res Function(SheetItem) _then;

/// Create a copy of SheetItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? localId = null,Object? name = null,Object? sizeBytes = null,Object? type = null,Object? isPreview = null,Object? status = null,Object? progress = null,Object? serverSheetId = freezed,Object? objectKey = freezed,Object? error = freezed,Object? file = freezed,}) {
  return _then(_self.copyWith(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SheetType,isPreview: null == isPreview ? _self.isPreview : isPreview // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SheetUploadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,serverSheetId: freezed == serverSheetId ? _self.serverSheetId : serverSheetId // ignore: cast_nullable_to_non_nullable
as String?,objectKey: freezed == objectKey ? _self.objectKey : objectKey // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedSheetFile?,
  ));
}

}


/// Adds pattern-matching-related methods to [SheetItem].
extension SheetItemPatterns on SheetItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SheetItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SheetItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SheetItem value)  $default,){
final _that = this;
switch (_that) {
case _SheetItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SheetItem value)?  $default,){
final _that = this;
switch (_that) {
case _SheetItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String localId,  String name,  int sizeBytes,  SheetType type,  bool isPreview,  SheetUploadStatus status,  double progress,  String? serverSheetId,  String? objectKey,  String? error,  PickedSheetFile? file)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SheetItem() when $default != null:
return $default(_that.localId,_that.name,_that.sizeBytes,_that.type,_that.isPreview,_that.status,_that.progress,_that.serverSheetId,_that.objectKey,_that.error,_that.file);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String localId,  String name,  int sizeBytes,  SheetType type,  bool isPreview,  SheetUploadStatus status,  double progress,  String? serverSheetId,  String? objectKey,  String? error,  PickedSheetFile? file)  $default,) {final _that = this;
switch (_that) {
case _SheetItem():
return $default(_that.localId,_that.name,_that.sizeBytes,_that.type,_that.isPreview,_that.status,_that.progress,_that.serverSheetId,_that.objectKey,_that.error,_that.file);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String localId,  String name,  int sizeBytes,  SheetType type,  bool isPreview,  SheetUploadStatus status,  double progress,  String? serverSheetId,  String? objectKey,  String? error,  PickedSheetFile? file)?  $default,) {final _that = this;
switch (_that) {
case _SheetItem() when $default != null:
return $default(_that.localId,_that.name,_that.sizeBytes,_that.type,_that.isPreview,_that.status,_that.progress,_that.serverSheetId,_that.objectKey,_that.error,_that.file);case _:
  return null;

}
}

}

/// @nodoc


class _SheetItem extends SheetItem {
  const _SheetItem({required this.localId, required this.name, required this.sizeBytes, this.type = SheetType.architectural, this.isPreview = false, this.status = SheetUploadStatus.queued, this.progress = 0, this.serverSheetId, this.objectKey, this.error, this.file}): super._();
  

@override final  String localId;
@override final  String name;
@override final  int sizeBytes;
@override@JsonKey() final  SheetType type;
@override@JsonKey() final  bool isPreview;
@override@JsonKey() final  SheetUploadStatus status;
// 0..1 while uploading.
@override@JsonKey() final  double progress;
@override final  String? serverSheetId;
// Kept after a successful PUT so a failed registration retries without re-uploading.
@override final  String? objectKey;
@override final  String? error;
@override final  PickedSheetFile? file;

/// Create a copy of SheetItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SheetItemCopyWith<_SheetItem> get copyWith => __$SheetItemCopyWithImpl<_SheetItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SheetItem&&(identical(other.localId, localId) || other.localId == localId)&&(identical(other.name, name) || other.name == name)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes)&&(identical(other.type, type) || other.type == type)&&(identical(other.isPreview, isPreview) || other.isPreview == isPreview)&&(identical(other.status, status) || other.status == status)&&(identical(other.progress, progress) || other.progress == progress)&&(identical(other.serverSheetId, serverSheetId) || other.serverSheetId == serverSheetId)&&(identical(other.objectKey, objectKey) || other.objectKey == objectKey)&&(identical(other.error, error) || other.error == error)&&(identical(other.file, file) || other.file == file));
}


@override
int get hashCode => Object.hash(runtimeType,localId,name,sizeBytes,type,isPreview,status,progress,serverSheetId,objectKey,error,file);

@override
String toString() {
  return 'SheetItem(localId: $localId, name: $name, sizeBytes: $sizeBytes, type: $type, isPreview: $isPreview, status: $status, progress: $progress, serverSheetId: $serverSheetId, objectKey: $objectKey, error: $error, file: $file)';
}


}

/// @nodoc
abstract mixin class _$SheetItemCopyWith<$Res> implements $SheetItemCopyWith<$Res> {
  factory _$SheetItemCopyWith(_SheetItem value, $Res Function(_SheetItem) _then) = __$SheetItemCopyWithImpl;
@override @useResult
$Res call({
 String localId, String name, int sizeBytes, SheetType type, bool isPreview, SheetUploadStatus status, double progress, String? serverSheetId, String? objectKey, String? error, PickedSheetFile? file
});




}
/// @nodoc
class __$SheetItemCopyWithImpl<$Res>
    implements _$SheetItemCopyWith<$Res> {
  __$SheetItemCopyWithImpl(this._self, this._then);

  final _SheetItem _self;
  final $Res Function(_SheetItem) _then;

/// Create a copy of SheetItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? localId = null,Object? name = null,Object? sizeBytes = null,Object? type = null,Object? isPreview = null,Object? status = null,Object? progress = null,Object? serverSheetId = freezed,Object? objectKey = freezed,Object? error = freezed,Object? file = freezed,}) {
  return _then(_SheetItem(
localId: null == localId ? _self.localId : localId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sizeBytes: null == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as SheetType,isPreview: null == isPreview ? _self.isPreview : isPreview // ignore: cast_nullable_to_non_nullable
as bool,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as SheetUploadStatus,progress: null == progress ? _self.progress : progress // ignore: cast_nullable_to_non_nullable
as double,serverSheetId: freezed == serverSheetId ? _self.serverSheetId : serverSheetId // ignore: cast_nullable_to_non_nullable
as String?,objectKey: freezed == objectKey ? _self.objectKey : objectKey // ignore: cast_nullable_to_non_nullable
as String?,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,file: freezed == file ? _self.file : file // ignore: cast_nullable_to_non_nullable
as PickedSheetFile?,
  ));
}


}

/// @nodoc
mixin _$UploadFlowState {

 bool get loaded; UploadStep get step; DrawingForm get form; String? get draftId; List<SheetItem> get sheets; List<CategoryRef> get categories; String? get categoriesError;// Show validation messages (after the user tried to continue).
 bool get showErrors; bool get saving;// Last save/restore/publish error to display in a banner.
 String? get error;// Transient notices, e.g. files rejected by client-side validation.
 List<String> get notices; PublishPhase get phase; String? get failureReason;// Polling gave up (offline / timeout) but the server may still be working.
 bool get pollStalled;// Contribution rule (8.3); null until loaded or if it couldn't be fetched.
 ContributionStatus? get contribution;
/// Create a copy of UploadFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UploadFlowStateCopyWith<UploadFlowState> get copyWith => _$UploadFlowStateCopyWithImpl<UploadFlowState>(this as UploadFlowState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UploadFlowState&&(identical(other.loaded, loaded) || other.loaded == loaded)&&(identical(other.step, step) || other.step == step)&&(identical(other.form, form) || other.form == form)&&(identical(other.draftId, draftId) || other.draftId == draftId)&&const DeepCollectionEquality().equals(other.sheets, sheets)&&const DeepCollectionEquality().equals(other.categories, categories)&&(identical(other.categoriesError, categoriesError) || other.categoriesError == categoriesError)&&(identical(other.showErrors, showErrors) || other.showErrors == showErrors)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other.notices, notices)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.pollStalled, pollStalled) || other.pollStalled == pollStalled)&&(identical(other.contribution, contribution) || other.contribution == contribution));
}


@override
int get hashCode => Object.hash(runtimeType,loaded,step,form,draftId,const DeepCollectionEquality().hash(sheets),const DeepCollectionEquality().hash(categories),categoriesError,showErrors,saving,error,const DeepCollectionEquality().hash(notices),phase,failureReason,pollStalled,contribution);

@override
String toString() {
  return 'UploadFlowState(loaded: $loaded, step: $step, form: $form, draftId: $draftId, sheets: $sheets, categories: $categories, categoriesError: $categoriesError, showErrors: $showErrors, saving: $saving, error: $error, notices: $notices, phase: $phase, failureReason: $failureReason, pollStalled: $pollStalled, contribution: $contribution)';
}


}

/// @nodoc
abstract mixin class $UploadFlowStateCopyWith<$Res>  {
  factory $UploadFlowStateCopyWith(UploadFlowState value, $Res Function(UploadFlowState) _then) = _$UploadFlowStateCopyWithImpl;
@useResult
$Res call({
 bool loaded, UploadStep step, DrawingForm form, String? draftId, List<SheetItem> sheets, List<CategoryRef> categories, String? categoriesError, bool showErrors, bool saving, String? error, List<String> notices, PublishPhase phase, String? failureReason, bool pollStalled, ContributionStatus? contribution
});


$DrawingFormCopyWith<$Res> get form;

}
/// @nodoc
class _$UploadFlowStateCopyWithImpl<$Res>
    implements $UploadFlowStateCopyWith<$Res> {
  _$UploadFlowStateCopyWithImpl(this._self, this._then);

  final UploadFlowState _self;
  final $Res Function(UploadFlowState) _then;

/// Create a copy of UploadFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? loaded = null,Object? step = null,Object? form = null,Object? draftId = freezed,Object? sheets = null,Object? categories = null,Object? categoriesError = freezed,Object? showErrors = null,Object? saving = null,Object? error = freezed,Object? notices = null,Object? phase = null,Object? failureReason = freezed,Object? pollStalled = null,Object? contribution = freezed,}) {
  return _then(_self.copyWith(
loaded: null == loaded ? _self.loaded : loaded // ignore: cast_nullable_to_non_nullable
as bool,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as UploadStep,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as DrawingForm,draftId: freezed == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String?,sheets: null == sheets ? _self.sheets : sheets // ignore: cast_nullable_to_non_nullable
as List<SheetItem>,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryRef>,categoriesError: freezed == categoriesError ? _self.categoriesError : categoriesError // ignore: cast_nullable_to_non_nullable
as String?,showErrors: null == showErrors ? _self.showErrors : showErrors // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notices: null == notices ? _self.notices : notices // ignore: cast_nullable_to_non_nullable
as List<String>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PublishPhase,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,pollStalled: null == pollStalled ? _self.pollStalled : pollStalled // ignore: cast_nullable_to_non_nullable
as bool,contribution: freezed == contribution ? _self.contribution : contribution // ignore: cast_nullable_to_non_nullable
as ContributionStatus?,
  ));
}
/// Create a copy of UploadFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawingFormCopyWith<$Res> get form {
  
  return $DrawingFormCopyWith<$Res>(_self.form, (value) {
    return _then(_self.copyWith(form: value));
  });
}
}


/// Adds pattern-matching-related methods to [UploadFlowState].
extension UploadFlowStatePatterns on UploadFlowState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UploadFlowState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UploadFlowState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UploadFlowState value)  $default,){
final _that = this;
switch (_that) {
case _UploadFlowState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UploadFlowState value)?  $default,){
final _that = this;
switch (_that) {
case _UploadFlowState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool loaded,  UploadStep step,  DrawingForm form,  String? draftId,  List<SheetItem> sheets,  List<CategoryRef> categories,  String? categoriesError,  bool showErrors,  bool saving,  String? error,  List<String> notices,  PublishPhase phase,  String? failureReason,  bool pollStalled,  ContributionStatus? contribution)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UploadFlowState() when $default != null:
return $default(_that.loaded,_that.step,_that.form,_that.draftId,_that.sheets,_that.categories,_that.categoriesError,_that.showErrors,_that.saving,_that.error,_that.notices,_that.phase,_that.failureReason,_that.pollStalled,_that.contribution);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool loaded,  UploadStep step,  DrawingForm form,  String? draftId,  List<SheetItem> sheets,  List<CategoryRef> categories,  String? categoriesError,  bool showErrors,  bool saving,  String? error,  List<String> notices,  PublishPhase phase,  String? failureReason,  bool pollStalled,  ContributionStatus? contribution)  $default,) {final _that = this;
switch (_that) {
case _UploadFlowState():
return $default(_that.loaded,_that.step,_that.form,_that.draftId,_that.sheets,_that.categories,_that.categoriesError,_that.showErrors,_that.saving,_that.error,_that.notices,_that.phase,_that.failureReason,_that.pollStalled,_that.contribution);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool loaded,  UploadStep step,  DrawingForm form,  String? draftId,  List<SheetItem> sheets,  List<CategoryRef> categories,  String? categoriesError,  bool showErrors,  bool saving,  String? error,  List<String> notices,  PublishPhase phase,  String? failureReason,  bool pollStalled,  ContributionStatus? contribution)?  $default,) {final _that = this;
switch (_that) {
case _UploadFlowState() when $default != null:
return $default(_that.loaded,_that.step,_that.form,_that.draftId,_that.sheets,_that.categories,_that.categoriesError,_that.showErrors,_that.saving,_that.error,_that.notices,_that.phase,_that.failureReason,_that.pollStalled,_that.contribution);case _:
  return null;

}
}

}

/// @nodoc


class _UploadFlowState extends UploadFlowState {
  const _UploadFlowState({this.loaded = false, this.step = UploadStep.details, this.form = const DrawingForm(), this.draftId, final  List<SheetItem> sheets = const <SheetItem>[], final  List<CategoryRef> categories = const <CategoryRef>[], this.categoriesError, this.showErrors = false, this.saving = false, this.error, final  List<String> notices = const <String>[], this.phase = PublishPhase.idle, this.failureReason, this.pollStalled = false, this.contribution}): _sheets = sheets,_categories = categories,_notices = notices,super._();
  

@override@JsonKey() final  bool loaded;
@override@JsonKey() final  UploadStep step;
@override@JsonKey() final  DrawingForm form;
@override final  String? draftId;
 final  List<SheetItem> _sheets;
@override@JsonKey() List<SheetItem> get sheets {
  if (_sheets is EqualUnmodifiableListView) return _sheets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sheets);
}

 final  List<CategoryRef> _categories;
@override@JsonKey() List<CategoryRef> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

@override final  String? categoriesError;
// Show validation messages (after the user tried to continue).
@override@JsonKey() final  bool showErrors;
@override@JsonKey() final  bool saving;
// Last save/restore/publish error to display in a banner.
@override final  String? error;
// Transient notices, e.g. files rejected by client-side validation.
 final  List<String> _notices;
// Transient notices, e.g. files rejected by client-side validation.
@override@JsonKey() List<String> get notices {
  if (_notices is EqualUnmodifiableListView) return _notices;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notices);
}

@override@JsonKey() final  PublishPhase phase;
@override final  String? failureReason;
// Polling gave up (offline / timeout) but the server may still be working.
@override@JsonKey() final  bool pollStalled;
// Contribution rule (8.3); null until loaded or if it couldn't be fetched.
@override final  ContributionStatus? contribution;

/// Create a copy of UploadFlowState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UploadFlowStateCopyWith<_UploadFlowState> get copyWith => __$UploadFlowStateCopyWithImpl<_UploadFlowState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UploadFlowState&&(identical(other.loaded, loaded) || other.loaded == loaded)&&(identical(other.step, step) || other.step == step)&&(identical(other.form, form) || other.form == form)&&(identical(other.draftId, draftId) || other.draftId == draftId)&&const DeepCollectionEquality().equals(other._sheets, _sheets)&&const DeepCollectionEquality().equals(other._categories, _categories)&&(identical(other.categoriesError, categoriesError) || other.categoriesError == categoriesError)&&(identical(other.showErrors, showErrors) || other.showErrors == showErrors)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.error, error) || other.error == error)&&const DeepCollectionEquality().equals(other._notices, _notices)&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.failureReason, failureReason) || other.failureReason == failureReason)&&(identical(other.pollStalled, pollStalled) || other.pollStalled == pollStalled)&&(identical(other.contribution, contribution) || other.contribution == contribution));
}


@override
int get hashCode => Object.hash(runtimeType,loaded,step,form,draftId,const DeepCollectionEquality().hash(_sheets),const DeepCollectionEquality().hash(_categories),categoriesError,showErrors,saving,error,const DeepCollectionEquality().hash(_notices),phase,failureReason,pollStalled,contribution);

@override
String toString() {
  return 'UploadFlowState(loaded: $loaded, step: $step, form: $form, draftId: $draftId, sheets: $sheets, categories: $categories, categoriesError: $categoriesError, showErrors: $showErrors, saving: $saving, error: $error, notices: $notices, phase: $phase, failureReason: $failureReason, pollStalled: $pollStalled, contribution: $contribution)';
}


}

/// @nodoc
abstract mixin class _$UploadFlowStateCopyWith<$Res> implements $UploadFlowStateCopyWith<$Res> {
  factory _$UploadFlowStateCopyWith(_UploadFlowState value, $Res Function(_UploadFlowState) _then) = __$UploadFlowStateCopyWithImpl;
@override @useResult
$Res call({
 bool loaded, UploadStep step, DrawingForm form, String? draftId, List<SheetItem> sheets, List<CategoryRef> categories, String? categoriesError, bool showErrors, bool saving, String? error, List<String> notices, PublishPhase phase, String? failureReason, bool pollStalled, ContributionStatus? contribution
});


@override $DrawingFormCopyWith<$Res> get form;

}
/// @nodoc
class __$UploadFlowStateCopyWithImpl<$Res>
    implements _$UploadFlowStateCopyWith<$Res> {
  __$UploadFlowStateCopyWithImpl(this._self, this._then);

  final _UploadFlowState _self;
  final $Res Function(_UploadFlowState) _then;

/// Create a copy of UploadFlowState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? loaded = null,Object? step = null,Object? form = null,Object? draftId = freezed,Object? sheets = null,Object? categories = null,Object? categoriesError = freezed,Object? showErrors = null,Object? saving = null,Object? error = freezed,Object? notices = null,Object? phase = null,Object? failureReason = freezed,Object? pollStalled = null,Object? contribution = freezed,}) {
  return _then(_UploadFlowState(
loaded: null == loaded ? _self.loaded : loaded // ignore: cast_nullable_to_non_nullable
as bool,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as UploadStep,form: null == form ? _self.form : form // ignore: cast_nullable_to_non_nullable
as DrawingForm,draftId: freezed == draftId ? _self.draftId : draftId // ignore: cast_nullable_to_non_nullable
as String?,sheets: null == sheets ? _self._sheets : sheets // ignore: cast_nullable_to_non_nullable
as List<SheetItem>,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<CategoryRef>,categoriesError: freezed == categoriesError ? _self.categoriesError : categoriesError // ignore: cast_nullable_to_non_nullable
as String?,showErrors: null == showErrors ? _self.showErrors : showErrors // ignore: cast_nullable_to_non_nullable
as bool,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,notices: null == notices ? _self._notices : notices // ignore: cast_nullable_to_non_nullable
as List<String>,phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as PublishPhase,failureReason: freezed == failureReason ? _self.failureReason : failureReason // ignore: cast_nullable_to_non_nullable
as String?,pollStalled: null == pollStalled ? _self.pollStalled : pollStalled // ignore: cast_nullable_to_non_nullable
as bool,contribution: freezed == contribution ? _self.contribution : contribution // ignore: cast_nullable_to_non_nullable
as ContributionStatus?,
  ));
}

/// Create a copy of UploadFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DrawingFormCopyWith<$Res> get form {
  
  return $DrawingFormCopyWith<$Res>(_self.form, (value) {
    return _then(_self.copyWith(form: value));
  });
}
}

// dart format on
