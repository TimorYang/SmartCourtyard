// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_public_key_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthPublicKeyResponseDto {

 String get keyId; String get algorithm; String get publicKey; String get nonce;@JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson) int get expiresInSeconds;
/// Create a copy of AuthPublicKeyResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AuthPublicKeyResponseDtoCopyWith<AuthPublicKeyResponseDto> get copyWith => _$AuthPublicKeyResponseDtoCopyWithImpl<AuthPublicKeyResponseDto>(this as AuthPublicKeyResponseDto, _$identity);

  /// Serializes this AuthPublicKeyResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AuthPublicKeyResponseDto&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.nonce, nonce) || other.nonce == nonce)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyId,algorithm,publicKey,nonce,expiresInSeconds);

@override
String toString() {
  return 'AuthPublicKeyResponseDto(keyId: $keyId, algorithm: $algorithm, publicKey: $publicKey, nonce: $nonce, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class $AuthPublicKeyResponseDtoCopyWith<$Res>  {
  factory $AuthPublicKeyResponseDtoCopyWith(AuthPublicKeyResponseDto value, $Res Function(AuthPublicKeyResponseDto) _then) = _$AuthPublicKeyResponseDtoCopyWithImpl;
@useResult
$Res call({
 String keyId, String algorithm, String publicKey, String nonce,@JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson) int expiresInSeconds
});




}
/// @nodoc
class _$AuthPublicKeyResponseDtoCopyWithImpl<$Res>
    implements $AuthPublicKeyResponseDtoCopyWith<$Res> {
  _$AuthPublicKeyResponseDtoCopyWithImpl(this._self, this._then);

  final AuthPublicKeyResponseDto _self;
  final $Res Function(AuthPublicKeyResponseDto) _then;

/// Create a copy of AuthPublicKeyResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? keyId = null,Object? algorithm = null,Object? publicKey = null,Object? nonce = null,Object? expiresInSeconds = null,}) {
  return _then(_self.copyWith(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AuthPublicKeyResponseDto].
extension AuthPublicKeyResponseDtoPatterns on AuthPublicKeyResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AuthPublicKeyResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AuthPublicKeyResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AuthPublicKeyResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _AuthPublicKeyResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AuthPublicKeyResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _AuthPublicKeyResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String keyId,  String algorithm,  String publicKey,  String nonce, @JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson)  int expiresInSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AuthPublicKeyResponseDto() when $default != null:
return $default(_that.keyId,_that.algorithm,_that.publicKey,_that.nonce,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String keyId,  String algorithm,  String publicKey,  String nonce, @JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson)  int expiresInSeconds)  $default,) {final _that = this;
switch (_that) {
case _AuthPublicKeyResponseDto():
return $default(_that.keyId,_that.algorithm,_that.publicKey,_that.nonce,_that.expiresInSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String keyId,  String algorithm,  String publicKey,  String nonce, @JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson)  int expiresInSeconds)?  $default,) {final _that = this;
switch (_that) {
case _AuthPublicKeyResponseDto() when $default != null:
return $default(_that.keyId,_that.algorithm,_that.publicKey,_that.nonce,_that.expiresInSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AuthPublicKeyResponseDto implements AuthPublicKeyResponseDto {
  const _AuthPublicKeyResponseDto({required this.keyId, required this.algorithm, required this.publicKey, required this.nonce, @JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson) required this.expiresInSeconds});
  factory _AuthPublicKeyResponseDto.fromJson(Map<String, dynamic> json) => _$AuthPublicKeyResponseDtoFromJson(json);

@override final  String keyId;
@override final  String algorithm;
@override final  String publicKey;
@override final  String nonce;
@override@JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson) final  int expiresInSeconds;

/// Create a copy of AuthPublicKeyResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AuthPublicKeyResponseDtoCopyWith<_AuthPublicKeyResponseDto> get copyWith => __$AuthPublicKeyResponseDtoCopyWithImpl<_AuthPublicKeyResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AuthPublicKeyResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AuthPublicKeyResponseDto&&(identical(other.keyId, keyId) || other.keyId == keyId)&&(identical(other.algorithm, algorithm) || other.algorithm == algorithm)&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.nonce, nonce) || other.nonce == nonce)&&(identical(other.expiresInSeconds, expiresInSeconds) || other.expiresInSeconds == expiresInSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,keyId,algorithm,publicKey,nonce,expiresInSeconds);

@override
String toString() {
  return 'AuthPublicKeyResponseDto(keyId: $keyId, algorithm: $algorithm, publicKey: $publicKey, nonce: $nonce, expiresInSeconds: $expiresInSeconds)';
}


}

/// @nodoc
abstract mixin class _$AuthPublicKeyResponseDtoCopyWith<$Res> implements $AuthPublicKeyResponseDtoCopyWith<$Res> {
  factory _$AuthPublicKeyResponseDtoCopyWith(_AuthPublicKeyResponseDto value, $Res Function(_AuthPublicKeyResponseDto) _then) = __$AuthPublicKeyResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String keyId, String algorithm, String publicKey, String nonce,@JsonKey(name: 'expiresIn', fromJson: _expiresInSecondsFromJson) int expiresInSeconds
});




}
/// @nodoc
class __$AuthPublicKeyResponseDtoCopyWithImpl<$Res>
    implements _$AuthPublicKeyResponseDtoCopyWith<$Res> {
  __$AuthPublicKeyResponseDtoCopyWithImpl(this._self, this._then);

  final _AuthPublicKeyResponseDto _self;
  final $Res Function(_AuthPublicKeyResponseDto) _then;

/// Create a copy of AuthPublicKeyResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? keyId = null,Object? algorithm = null,Object? publicKey = null,Object? nonce = null,Object? expiresInSeconds = null,}) {
  return _then(_AuthPublicKeyResponseDto(
keyId: null == keyId ? _self.keyId : keyId // ignore: cast_nullable_to_non_nullable
as String,algorithm: null == algorithm ? _self.algorithm : algorithm // ignore: cast_nullable_to_non_nullable
as String,publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,nonce: null == nonce ? _self.nonce : nonce // ignore: cast_nullable_to_non_nullable
as String,expiresInSeconds: null == expiresInSeconds ? _self.expiresInSeconds : expiresInSeconds // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
