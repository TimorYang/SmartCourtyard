// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'engage_lab_registration_request_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EngageLabRegistrationRequestDto {

 String get registrationId; String get deviceId; String get platform;
/// Create a copy of EngageLabRegistrationRequestDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EngageLabRegistrationRequestDtoCopyWith<EngageLabRegistrationRequestDto> get copyWith => _$EngageLabRegistrationRequestDtoCopyWithImpl<EngageLabRegistrationRequestDto>(this as EngageLabRegistrationRequestDto, _$identity);

  /// Serializes this EngageLabRegistrationRequestDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EngageLabRegistrationRequestDto&&(identical(other.registrationId, registrationId) || other.registrationId == registrationId)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.platform, platform) || other.platform == platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registrationId,deviceId,platform);

@override
String toString() {
  return 'EngageLabRegistrationRequestDto(registrationId: $registrationId, deviceId: $deviceId, platform: $platform)';
}


}

/// @nodoc
abstract mixin class $EngageLabRegistrationRequestDtoCopyWith<$Res>  {
  factory $EngageLabRegistrationRequestDtoCopyWith(EngageLabRegistrationRequestDto value, $Res Function(EngageLabRegistrationRequestDto) _then) = _$EngageLabRegistrationRequestDtoCopyWithImpl;
@useResult
$Res call({
 String registrationId, String deviceId, String platform
});




}
/// @nodoc
class _$EngageLabRegistrationRequestDtoCopyWithImpl<$Res>
    implements $EngageLabRegistrationRequestDtoCopyWith<$Res> {
  _$EngageLabRegistrationRequestDtoCopyWithImpl(this._self, this._then);

  final EngageLabRegistrationRequestDto _self;
  final $Res Function(EngageLabRegistrationRequestDto) _then;

/// Create a copy of EngageLabRegistrationRequestDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? registrationId = null,Object? deviceId = null,Object? platform = null,}) {
  return _then(_self.copyWith(
registrationId: null == registrationId ? _self.registrationId : registrationId // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [EngageLabRegistrationRequestDto].
extension EngageLabRegistrationRequestDtoPatterns on EngageLabRegistrationRequestDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EngageLabRegistrationRequestDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EngageLabRegistrationRequestDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EngageLabRegistrationRequestDto value)  $default,){
final _that = this;
switch (_that) {
case _EngageLabRegistrationRequestDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EngageLabRegistrationRequestDto value)?  $default,){
final _that = this;
switch (_that) {
case _EngageLabRegistrationRequestDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String registrationId,  String deviceId,  String platform)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EngageLabRegistrationRequestDto() when $default != null:
return $default(_that.registrationId,_that.deviceId,_that.platform);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String registrationId,  String deviceId,  String platform)  $default,) {final _that = this;
switch (_that) {
case _EngageLabRegistrationRequestDto():
return $default(_that.registrationId,_that.deviceId,_that.platform);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String registrationId,  String deviceId,  String platform)?  $default,) {final _that = this;
switch (_that) {
case _EngageLabRegistrationRequestDto() when $default != null:
return $default(_that.registrationId,_that.deviceId,_that.platform);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EngageLabRegistrationRequestDto implements EngageLabRegistrationRequestDto {
  const _EngageLabRegistrationRequestDto({required this.registrationId, required this.deviceId, required this.platform});
  factory _EngageLabRegistrationRequestDto.fromJson(Map<String, dynamic> json) => _$EngageLabRegistrationRequestDtoFromJson(json);

@override final  String registrationId;
@override final  String deviceId;
@override final  String platform;

/// Create a copy of EngageLabRegistrationRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EngageLabRegistrationRequestDtoCopyWith<_EngageLabRegistrationRequestDto> get copyWith => __$EngageLabRegistrationRequestDtoCopyWithImpl<_EngageLabRegistrationRequestDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EngageLabRegistrationRequestDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EngageLabRegistrationRequestDto&&(identical(other.registrationId, registrationId) || other.registrationId == registrationId)&&(identical(other.deviceId, deviceId) || other.deviceId == deviceId)&&(identical(other.platform, platform) || other.platform == platform));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,registrationId,deviceId,platform);

@override
String toString() {
  return 'EngageLabRegistrationRequestDto(registrationId: $registrationId, deviceId: $deviceId, platform: $platform)';
}


}

/// @nodoc
abstract mixin class _$EngageLabRegistrationRequestDtoCopyWith<$Res> implements $EngageLabRegistrationRequestDtoCopyWith<$Res> {
  factory _$EngageLabRegistrationRequestDtoCopyWith(_EngageLabRegistrationRequestDto value, $Res Function(_EngageLabRegistrationRequestDto) _then) = __$EngageLabRegistrationRequestDtoCopyWithImpl;
@override @useResult
$Res call({
 String registrationId, String deviceId, String platform
});




}
/// @nodoc
class __$EngageLabRegistrationRequestDtoCopyWithImpl<$Res>
    implements _$EngageLabRegistrationRequestDtoCopyWith<$Res> {
  __$EngageLabRegistrationRequestDtoCopyWithImpl(this._self, this._then);

  final _EngageLabRegistrationRequestDto _self;
  final $Res Function(_EngageLabRegistrationRequestDto) _then;

/// Create a copy of EngageLabRegistrationRequestDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? registrationId = null,Object? deviceId = null,Object? platform = null,}) {
  return _then(_EngageLabRegistrationRequestDto(
registrationId: null == registrationId ? _self.registrationId : registrationId // ignore: cast_nullable_to_non_nullable
as String,deviceId: null == deviceId ? _self.deviceId : deviceId // ignore: cast_nullable_to_non_nullable
as String,platform: null == platform ? _self.platform : platform // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
