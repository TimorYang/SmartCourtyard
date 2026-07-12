// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_envelope_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiEnvelopeDto<T> {

 int get code; bool get success; String? get msg; T? get data;
/// Create a copy of ApiEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiEnvelopeDtoCopyWith<T, ApiEnvelopeDto<T>> get copyWith => _$ApiEnvelopeDtoCopyWithImpl<T, ApiEnvelopeDto<T>>(this as ApiEnvelopeDto<T>, _$identity);

  /// Serializes this ApiEnvelopeDto to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiEnvelopeDto<T>&&(identical(other.code, code) || other.code == code)&&(identical(other.success, success) || other.success == success)&&(identical(other.msg, msg) || other.msg == msg)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,success,msg,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'ApiEnvelopeDto<$T>(code: $code, success: $success, msg: $msg, data: $data)';
}


}

/// @nodoc
abstract mixin class $ApiEnvelopeDtoCopyWith<T,$Res>  {
  factory $ApiEnvelopeDtoCopyWith(ApiEnvelopeDto<T> value, $Res Function(ApiEnvelopeDto<T>) _then) = _$ApiEnvelopeDtoCopyWithImpl;
@useResult
$Res call({
 int code, bool success, String? msg, T? data
});




}
/// @nodoc
class _$ApiEnvelopeDtoCopyWithImpl<T,$Res>
    implements $ApiEnvelopeDtoCopyWith<T, $Res> {
  _$ApiEnvelopeDtoCopyWithImpl(this._self, this._then);

  final ApiEnvelopeDto<T> _self;
  final $Res Function(ApiEnvelopeDto<T>) _then;

/// Create a copy of ApiEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? code = null,Object? success = null,Object? msg = freezed,Object? data = freezed,}) {
  return _then(_self.copyWith(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,msg: freezed == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiEnvelopeDto].
extension ApiEnvelopeDtoPatterns<T> on ApiEnvelopeDto<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiEnvelopeDto<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiEnvelopeDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiEnvelopeDto<T> value)  $default,){
final _that = this;
switch (_that) {
case _ApiEnvelopeDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiEnvelopeDto<T> value)?  $default,){
final _that = this;
switch (_that) {
case _ApiEnvelopeDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int code,  bool success,  String? msg,  T? data)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiEnvelopeDto() when $default != null:
return $default(_that.code,_that.success,_that.msg,_that.data);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int code,  bool success,  String? msg,  T? data)  $default,) {final _that = this;
switch (_that) {
case _ApiEnvelopeDto():
return $default(_that.code,_that.success,_that.msg,_that.data);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int code,  bool success,  String? msg,  T? data)?  $default,) {final _that = this;
switch (_that) {
case _ApiEnvelopeDto() when $default != null:
return $default(_that.code,_that.success,_that.msg,_that.data);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _ApiEnvelopeDto<T> implements ApiEnvelopeDto<T> {
  const _ApiEnvelopeDto({required this.code, required this.success, this.msg, this.data});
  factory _ApiEnvelopeDto.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ApiEnvelopeDtoFromJson(json,fromJsonT);

@override final  int code;
@override final  bool success;
@override final  String? msg;
@override final  T? data;

/// Create a copy of ApiEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiEnvelopeDtoCopyWith<T, _ApiEnvelopeDto<T>> get copyWith => __$ApiEnvelopeDtoCopyWithImpl<T, _ApiEnvelopeDto<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$ApiEnvelopeDtoToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiEnvelopeDto<T>&&(identical(other.code, code) || other.code == code)&&(identical(other.success, success) || other.success == success)&&(identical(other.msg, msg) || other.msg == msg)&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,code,success,msg,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'ApiEnvelopeDto<$T>(code: $code, success: $success, msg: $msg, data: $data)';
}


}

/// @nodoc
abstract mixin class _$ApiEnvelopeDtoCopyWith<T,$Res> implements $ApiEnvelopeDtoCopyWith<T, $Res> {
  factory _$ApiEnvelopeDtoCopyWith(_ApiEnvelopeDto<T> value, $Res Function(_ApiEnvelopeDto<T>) _then) = __$ApiEnvelopeDtoCopyWithImpl;
@override @useResult
$Res call({
 int code, bool success, String? msg, T? data
});




}
/// @nodoc
class __$ApiEnvelopeDtoCopyWithImpl<T,$Res>
    implements _$ApiEnvelopeDtoCopyWith<T, $Res> {
  __$ApiEnvelopeDtoCopyWithImpl(this._self, this._then);

  final _ApiEnvelopeDto<T> _self;
  final $Res Function(_ApiEnvelopeDto<T>) _then;

/// Create a copy of ApiEnvelopeDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? code = null,Object? success = null,Object? msg = freezed,Object? data = freezed,}) {
  return _then(_ApiEnvelopeDto<T>(
code: null == code ? _self.code : code // ignore: cast_nullable_to_non_nullable
as int,success: null == success ? _self.success : success // ignore: cast_nullable_to_non_nullable
as bool,msg: freezed == msg ? _self.msg : msg // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,
  ));
}


}

// dart format on
