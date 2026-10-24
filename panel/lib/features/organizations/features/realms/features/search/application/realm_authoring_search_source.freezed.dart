// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'realm_authoring_search_source.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AuthoringSearchResultPayload {

 skir.AuthoringSearchHit get hit; AuthoringDocument get document; ResourceIssues get issues; HostContext get hostContext;



@override
bool operator ==(Object other) {
  final _this = this as AuthoringSearchResultPayload;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthoringSearchResultPayload&&(identical(other.hit, _this.hit) || other.hit == _this.hit)&&(identical(other.document, _this.document) || other.document == _this.document)&&(identical(other.issues, _this.issues) || other.issues == _this.issues)&&(identical(other.hostContext, _this.hostContext) || other.hostContext == _this.hostContext));
}


@override
int get hashCode {
  final _this = this as AuthoringSearchResultPayload;
  return Object.hash(runtimeType,_this.hit,_this.document,_this.issues,_this.hostContext);
}

@override
String toString() {
  final _this = this as AuthoringSearchResultPayload;
  return 'AuthoringSearchResultPayload(hit: ${_this.hit}, document: ${_this.document}, issues: ${_this.issues}, hostContext: ${_this.hostContext})';
}


}





/// @nodoc


class _AuthoringSearchResultPayload extends AuthoringSearchResultPayload {
  const _AuthoringSearchResultPayload({required this.hit, required this.document, required this.issues, this.hostContext = HostContext.empty}): super._();
  

@override final  skir.AuthoringSearchHit hit;
@override final  AuthoringDocument document;
@override final  ResourceIssues issues;
@override@JsonKey() final  HostContext hostContext;




@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthoringSearchResultPayload&&(identical(other.hit, hit) || other.hit == hit)&&(identical(other.document, document) || other.document == document)&&(identical(other.issues, issues) || other.issues == issues)&&(identical(other.hostContext, hostContext) || other.hostContext == hostContext));
}


@override
int get hashCode {
    return Object.hash(runtimeType,hit,document,issues,hostContext);
}

@override
String toString() {
    return 'AuthoringSearchResultPayload(hit: $hit, document: $document, issues: $issues, hostContext: $hostContext)';
}


}




// dart format on
