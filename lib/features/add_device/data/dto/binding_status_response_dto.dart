class BindingStatusResponseDto {
  const BindingStatusResponseDto({
    required this.sn,
    required this.bound,
    required this.ownedByCurrentUser,
    required this.canBind,
  });

  final String sn;
  final bool bound;
  final bool ownedByCurrentUser;
  final bool canBind;

  factory BindingStatusResponseDto.fromJson(Map<String, dynamic> json) {
    return BindingStatusResponseDto(
      sn: json['sn'] as String? ?? '',
      bound: json['bound'] as bool? ?? false,
      ownedByCurrentUser: json['ownedByCurrentUser'] as bool? ?? false,
      canBind: json['canBind'] as bool? ?? false,
    );
  }

  bool get isValid => sn.trim().isNotEmpty;
}
