// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_inbox.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$RealmInboxIssue {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmInboxIssue);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'RealmInboxIssue()';
}


}

/// @nodoc
class $RealmInboxIssueCopyWith<$Res>  {
$RealmInboxIssueCopyWith(RealmInboxIssue _, $Res Function(RealmInboxIssue) __);
}


/// Adds pattern-matching-related methods to [RealmInboxIssue].
extension RealmInboxIssuePatterns on RealmInboxIssue {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RealmInboxFinding value)?  finding,TResult Function( RealmInboxWorkIssue value)?  work,TResult Function( RealmInboxSubmissionIssue value)?  submission,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RealmInboxFinding() when finding != null:
return finding(_that);case RealmInboxWorkIssue() when work != null:
return work(_that);case RealmInboxSubmissionIssue() when submission != null:
return submission(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RealmInboxFinding value)  finding,required TResult Function( RealmInboxWorkIssue value)  work,required TResult Function( RealmInboxSubmissionIssue value)  submission,}){
final _that = this;
switch (_that) {
case RealmInboxFinding():
return finding(_that);case RealmInboxWorkIssue():
return work(_that);case RealmInboxSubmissionIssue():
return submission(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RealmInboxFinding value)?  finding,TResult? Function( RealmInboxWorkIssue value)?  work,TResult? Function( RealmInboxSubmissionIssue value)?  submission,}){
final _that = this;
switch (_that) {
case RealmInboxFinding() when finding != null:
return finding(_that);case RealmInboxWorkIssue() when work != null:
return work(_that);case RealmInboxSubmissionIssue() when submission != null:
return submission(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( ResourceIssue finding)?  finding,TResult Function( WorkEntryState entry)?  work,TResult Function( LocalWorkSubmissionState submission)?  submission,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RealmInboxFinding() when finding != null:
return finding(_that.finding);case RealmInboxWorkIssue() when work != null:
return work(_that.entry);case RealmInboxSubmissionIssue() when submission != null:
return submission(_that.submission);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( ResourceIssue finding)  finding,required TResult Function( WorkEntryState entry)  work,required TResult Function( LocalWorkSubmissionState submission)  submission,}) {final _that = this;
switch (_that) {
case RealmInboxFinding():
return finding(_that.finding);case RealmInboxWorkIssue():
return work(_that.entry);case RealmInboxSubmissionIssue():
return submission(_that.submission);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( ResourceIssue finding)?  finding,TResult? Function( WorkEntryState entry)?  work,TResult? Function( LocalWorkSubmissionState submission)?  submission,}) {final _that = this;
switch (_that) {
case RealmInboxFinding() when finding != null:
return finding(_that.finding);case RealmInboxWorkIssue() when work != null:
return work(_that.entry);case RealmInboxSubmissionIssue() when submission != null:
return submission(_that.submission);case _:
  return null;

}
}

}

/// @nodoc


class RealmInboxFinding extends RealmInboxIssue {
  const RealmInboxFinding(this.finding): super._();
  

 final  ResourceIssue finding;

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmInboxFindingCopyWith<RealmInboxFinding> get copyWith => _$RealmInboxFindingCopyWithImpl<RealmInboxFinding>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmInboxFinding&&(identical(other.finding, finding) || other.finding == finding));
}


@override
int get hashCode {
    return Object.hash(runtimeType,finding);
}

@override
String toString() {
    return 'RealmInboxIssue.finding(finding: $finding)';
}


}

/// @nodoc
abstract mixin class $RealmInboxFindingCopyWith<$Res> implements $RealmInboxIssueCopyWith<$Res> {
  factory $RealmInboxFindingCopyWith(RealmInboxFinding value, $Res Function(RealmInboxFinding) _then) = _$RealmInboxFindingCopyWithImpl;
@useResult
$Res call({
 ResourceIssue finding
});


$ResourceIssueCopyWith<$Res> get finding;

}
/// @nodoc
class _$RealmInboxFindingCopyWithImpl<$Res>
    implements $RealmInboxFindingCopyWith<$Res> {
  _$RealmInboxFindingCopyWithImpl(this._self, this._then);

  final RealmInboxFinding _self;
  final $Res Function(RealmInboxFinding) _then;

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? finding = null,}) {
  return _then(RealmInboxFinding(
null == finding ? _self.finding : finding // ignore: cast_nullable_to_non_nullable
as ResourceIssue,
  ));
}

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResourceIssueCopyWith<$Res> get finding {
  
  return $ResourceIssueCopyWith<$Res>(_self.finding, (value) {
    return _then(_self.copyWith(finding: value));
  });
}
}

/// @nodoc


class RealmInboxWorkIssue extends RealmInboxIssue {
  const RealmInboxWorkIssue(this.entry): super._();
  

 final  WorkEntryState entry;

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmInboxWorkIssueCopyWith<RealmInboxWorkIssue> get copyWith => _$RealmInboxWorkIssueCopyWithImpl<RealmInboxWorkIssue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmInboxWorkIssue&&(identical(other.entry, entry) || other.entry == entry));
}


@override
int get hashCode {
    return Object.hash(runtimeType,entry);
}

@override
String toString() {
    return 'RealmInboxIssue.work(entry: $entry)';
}


}

/// @nodoc
abstract mixin class $RealmInboxWorkIssueCopyWith<$Res> implements $RealmInboxIssueCopyWith<$Res> {
  factory $RealmInboxWorkIssueCopyWith(RealmInboxWorkIssue value, $Res Function(RealmInboxWorkIssue) _then) = _$RealmInboxWorkIssueCopyWithImpl;
@useResult
$Res call({
 WorkEntryState entry
});


$WorkEntryStateCopyWith<$Res> get entry;

}
/// @nodoc
class _$RealmInboxWorkIssueCopyWithImpl<$Res>
    implements $RealmInboxWorkIssueCopyWith<$Res> {
  _$RealmInboxWorkIssueCopyWithImpl(this._self, this._then);

  final RealmInboxWorkIssue _self;
  final $Res Function(RealmInboxWorkIssue) _then;

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? entry = null,}) {
  return _then(RealmInboxWorkIssue(
null == entry ? _self.entry : entry // ignore: cast_nullable_to_non_nullable
as WorkEntryState,
  ));
}

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkEntryStateCopyWith<$Res> get entry {
  
  return $WorkEntryStateCopyWith<$Res>(_self.entry, (value) {
    return _then(_self.copyWith(entry: value));
  });
}
}

/// @nodoc


class RealmInboxSubmissionIssue extends RealmInboxIssue {
  const RealmInboxSubmissionIssue(this.submission): super._();
  

 final  LocalWorkSubmissionState submission;

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmInboxSubmissionIssueCopyWith<RealmInboxSubmissionIssue> get copyWith => _$RealmInboxSubmissionIssueCopyWithImpl<RealmInboxSubmissionIssue>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmInboxSubmissionIssue&&(identical(other.submission, submission) || other.submission == submission));
}


@override
int get hashCode {
    return Object.hash(runtimeType,submission);
}

@override
String toString() {
    return 'RealmInboxIssue.submission(submission: $submission)';
}


}

/// @nodoc
abstract mixin class $RealmInboxSubmissionIssueCopyWith<$Res> implements $RealmInboxIssueCopyWith<$Res> {
  factory $RealmInboxSubmissionIssueCopyWith(RealmInboxSubmissionIssue value, $Res Function(RealmInboxSubmissionIssue) _then) = _$RealmInboxSubmissionIssueCopyWithImpl;
@useResult
$Res call({
 LocalWorkSubmissionState submission
});


$LocalWorkSubmissionStateCopyWith<$Res> get submission;

}
/// @nodoc
class _$RealmInboxSubmissionIssueCopyWithImpl<$Res>
    implements $RealmInboxSubmissionIssueCopyWith<$Res> {
  _$RealmInboxSubmissionIssueCopyWithImpl(this._self, this._then);

  final RealmInboxSubmissionIssue _self;
  final $Res Function(RealmInboxSubmissionIssue) _then;

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? submission = null,}) {
  return _then(RealmInboxSubmissionIssue(
null == submission ? _self.submission : submission // ignore: cast_nullable_to_non_nullable
as LocalWorkSubmissionState,
  ));
}

/// Create a copy of RealmInboxIssue
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LocalWorkSubmissionStateCopyWith<$Res> get submission {
  
  return $LocalWorkSubmissionStateCopyWith<$Res>(_self.submission, (value) {
    return _then(_self.copyWith(submission: value));
  });
}
}

/// @nodoc
mixin _$RealmInboxState {

 RealmPublicationView get publication; List<RealmInboxIssue> get issues; List<skir.PublicationChange> get changes; List<skir.CompilationRoot> get pendingRoots; List<WorkEntryState> get localWork; List<LocalWorkSubmissionState> get submissions;
/// Create a copy of RealmInboxState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealmInboxStateCopyWith<RealmInboxState> get copyWith => _$RealmInboxStateCopyWithImpl<RealmInboxState>(this as RealmInboxState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as RealmInboxState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RealmInboxState&&(identical(other.publication, _this.publication) || other.publication == _this.publication)&&const DeepCollectionEquality().equals(other.issues, _this.issues)&&const DeepCollectionEquality().equals(other.changes, _this.changes)&&const DeepCollectionEquality().equals(other.pendingRoots, _this.pendingRoots)&&const DeepCollectionEquality().equals(other.localWork, _this.localWork)&&const DeepCollectionEquality().equals(other.submissions, _this.submissions));
}


@override
int get hashCode {
  final _this = this as RealmInboxState;
  return Object.hash(runtimeType,_this.publication,const DeepCollectionEquality().hash(_this.issues),const DeepCollectionEquality().hash(_this.changes),const DeepCollectionEquality().hash(_this.pendingRoots),const DeepCollectionEquality().hash(_this.localWork),const DeepCollectionEquality().hash(_this.submissions));
}

@override
String toString() {
  final _this = this as RealmInboxState;
  return 'RealmInboxState(publication: ${_this.publication}, issues: ${_this.issues}, changes: ${_this.changes}, pendingRoots: ${_this.pendingRoots}, localWork: ${_this.localWork}, submissions: ${_this.submissions})';
}


}

/// @nodoc
abstract mixin class $RealmInboxStateCopyWith<$Res>  {
  factory $RealmInboxStateCopyWith(RealmInboxState value, $Res Function(RealmInboxState) _then) = _$RealmInboxStateCopyWithImpl;
@useResult
$Res call({
 RealmPublicationView publication, List<RealmInboxIssue> issues, List<skir.PublicationChange> changes, List<skir.CompilationRoot> pendingRoots, List<WorkEntryState> localWork, List<LocalWorkSubmissionState> submissions
});


$RealmPublicationViewCopyWith<$Res> get publication;

}
/// @nodoc
class _$RealmInboxStateCopyWithImpl<$Res>
    implements $RealmInboxStateCopyWith<$Res> {
  _$RealmInboxStateCopyWithImpl(this._self, this._then);

  final RealmInboxState _self;
  final $Res Function(RealmInboxState) _then;

/// Create a copy of RealmInboxState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publication = null,Object? issues = null,Object? changes = null,Object? pendingRoots = null,Object? localWork = null,Object? submissions = null,}) {
  return _then(RealmInboxState(
publication: null == publication ? _self.publication : publication // ignore: cast_nullable_to_non_nullable
as RealmPublicationView,issues: null == issues ? _self.issues : issues // ignore: cast_nullable_to_non_nullable
as List<RealmInboxIssue>,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<skir.PublicationChange>,pendingRoots: null == pendingRoots ? _self.pendingRoots : pendingRoots // ignore: cast_nullable_to_non_nullable
as List<skir.CompilationRoot>,localWork: null == localWork ? _self.localWork : localWork // ignore: cast_nullable_to_non_nullable
as List<WorkEntryState>,submissions: null == submissions ? _self.submissions : submissions // ignore: cast_nullable_to_non_nullable
as List<LocalWorkSubmissionState>,
  ));
}
/// Create a copy of RealmInboxState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPublicationViewCopyWith<$Res> get publication {
  
  return $RealmPublicationViewCopyWith<$Res>(_self.publication, (value) {
    return _then(_self.copyWith(publication: value));
  });
}
}


/// Adds pattern-matching-related methods to [RealmInboxState].
extension RealmInboxStatePatterns on RealmInboxState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RealmInboxState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RealmInboxState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RealmInboxState value)  $default,){
final _that = this;
switch (_that) {
case _RealmInboxState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RealmInboxState value)?  $default,){
final _that = this;
switch (_that) {
case _RealmInboxState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( RealmPublicationView publication,  List<RealmInboxIssue> issues,  List<skir.PublicationChange> changes,  List<skir.CompilationRoot> pendingRoots,  List<WorkEntryState> localWork,  List<LocalWorkSubmissionState> submissions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RealmInboxState() when $default != null:
return $default(_that.publication,_that.issues,_that.changes,_that.pendingRoots,_that.localWork,_that.submissions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( RealmPublicationView publication,  List<RealmInboxIssue> issues,  List<skir.PublicationChange> changes,  List<skir.CompilationRoot> pendingRoots,  List<WorkEntryState> localWork,  List<LocalWorkSubmissionState> submissions)  $default,) {final _that = this;
switch (_that) {
case _RealmInboxState():
return $default(_that.publication,_that.issues,_that.changes,_that.pendingRoots,_that.localWork,_that.submissions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( RealmPublicationView publication,  List<RealmInboxIssue> issues,  List<skir.PublicationChange> changes,  List<skir.CompilationRoot> pendingRoots,  List<WorkEntryState> localWork,  List<LocalWorkSubmissionState> submissions)?  $default,) {final _that = this;
switch (_that) {
case _RealmInboxState() when $default != null:
return $default(_that.publication,_that.issues,_that.changes,_that.pendingRoots,_that.localWork,_that.submissions);case _:
  return null;

}
}

}

/// @nodoc


class _RealmInboxState implements RealmInboxState {
  const _RealmInboxState({required this.publication,  List<RealmInboxIssue> issues = const [],  List<skir.PublicationChange> changes = const [],  List<skir.CompilationRoot> pendingRoots = const [],  List<WorkEntryState> localWork = const [],  List<LocalWorkSubmissionState> submissions = const []}): _issues = issues,_changes = changes,_pendingRoots = pendingRoots,_localWork = localWork,_submissions = submissions;
  

@override final  RealmPublicationView publication;
 final  List<RealmInboxIssue> _issues;
@override@JsonKey() List<RealmInboxIssue> get issues {
  if (_issues is EqualUnmodifiableListView) return _issues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_issues);
}

 final  List<skir.PublicationChange> _changes;
@override@JsonKey() List<skir.PublicationChange> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}

 final  List<skir.CompilationRoot> _pendingRoots;
@override@JsonKey() List<skir.CompilationRoot> get pendingRoots {
  if (_pendingRoots is EqualUnmodifiableListView) return _pendingRoots;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_pendingRoots);
}

 final  List<WorkEntryState> _localWork;
@override@JsonKey() List<WorkEntryState> get localWork {
  if (_localWork is EqualUnmodifiableListView) return _localWork;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_localWork);
}

 final  List<LocalWorkSubmissionState> _submissions;
@override@JsonKey() List<LocalWorkSubmissionState> get submissions {
  if (_submissions is EqualUnmodifiableListView) return _submissions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_submissions);
}


/// Create a copy of RealmInboxState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealmInboxStateCopyWith<_RealmInboxState> get copyWith => __$RealmInboxStateCopyWithImpl<_RealmInboxState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RealmInboxState&&(identical(other.publication, publication) || other.publication == publication)&&const DeepCollectionEquality().equals(other.issues, _issues)&&const DeepCollectionEquality().equals(other.changes, _changes)&&const DeepCollectionEquality().equals(other.pendingRoots, _pendingRoots)&&const DeepCollectionEquality().equals(other.localWork, _localWork)&&const DeepCollectionEquality().equals(other.submissions, _submissions));
}


@override
int get hashCode {
    return Object.hash(runtimeType,publication,const DeepCollectionEquality().hash(_issues),const DeepCollectionEquality().hash(_changes),const DeepCollectionEquality().hash(_pendingRoots),const DeepCollectionEquality().hash(_localWork),const DeepCollectionEquality().hash(_submissions));
}

@override
String toString() {
    return 'RealmInboxState(publication: $publication, issues: $issues, changes: $changes, pendingRoots: $pendingRoots, localWork: $localWork, submissions: $submissions)';
}


}

/// @nodoc
abstract mixin class _$RealmInboxStateCopyWith<$Res> implements $RealmInboxStateCopyWith<$Res> {
  factory _$RealmInboxStateCopyWith(_RealmInboxState value, $Res Function(_RealmInboxState) _then) = __$RealmInboxStateCopyWithImpl;
@override @useResult
$Res call({
 RealmPublicationView publication, List<RealmInboxIssue> issues, List<skir.PublicationChange> changes, List<skir.CompilationRoot> pendingRoots, List<WorkEntryState> localWork, List<LocalWorkSubmissionState> submissions
});


@override $RealmPublicationViewCopyWith<$Res> get publication;

}
/// @nodoc
class __$RealmInboxStateCopyWithImpl<$Res>
    implements _$RealmInboxStateCopyWith<$Res> {
  __$RealmInboxStateCopyWithImpl(this._self, this._then);

  final _RealmInboxState _self;
  final $Res Function(_RealmInboxState) _then;

/// Create a copy of RealmInboxState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publication = null,Object? issues = null,Object? changes = null,Object? pendingRoots = null,Object? localWork = null,Object? submissions = null,}) {
  return _then(_RealmInboxState(
publication: null == publication ? _self.publication : publication // ignore: cast_nullable_to_non_nullable
as RealmPublicationView,issues: null == issues ? _self._issues : issues // ignore: cast_nullable_to_non_nullable
as List<RealmInboxIssue>,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<skir.PublicationChange>,pendingRoots: null == pendingRoots ? _self._pendingRoots : pendingRoots // ignore: cast_nullable_to_non_nullable
as List<skir.CompilationRoot>,localWork: null == localWork ? _self._localWork : localWork // ignore: cast_nullable_to_non_nullable
as List<WorkEntryState>,submissions: null == submissions ? _self._submissions : submissions // ignore: cast_nullable_to_non_nullable
as List<LocalWorkSubmissionState>,
  ));
}

/// Create a copy of RealmInboxState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealmPublicationViewCopyWith<$Res> get publication {
  
  return $RealmPublicationViewCopyWith<$Res>(_self.publication, (value) {
    return _then(_self.copyWith(publication: value));
  });
}
}

// dart format on
