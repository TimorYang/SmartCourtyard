class AccountOverviewDto {
  const AccountOverviewDto({required this.profile, required this.doorSummary});

  final AccountOverviewProfileDto profile;
  final AccountOverviewDoorSummaryDto doorSummary;

  factory AccountOverviewDto.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'];
    final doorSummary = json['doorSummary'];
    if (profile is! Map || doorSummary is! Map) {
      throw const FormatException('Account overview is missing required data.');
    }
    return AccountOverviewDto(
      profile: AccountOverviewProfileDto.fromJson(
        Map<String, dynamic>.from(profile),
      ),
      doorSummary: AccountOverviewDoorSummaryDto.fromJson(
        Map<String, dynamic>.from(doorSummary),
      ),
    );
  }
}

class AccountOverviewProfileDto {
  const AccountOverviewProfileDto({required this.nickname});

  final String nickname;

  factory AccountOverviewProfileDto.fromJson(Map<String, dynamic> json) {
    return AccountOverviewProfileDto(
      nickname: json['nickname'] as String? ?? '',
    );
  }
}

class AccountOverviewDoorSummaryDto {
  const AccountOverviewDoorSummaryDto({
    required this.ownedDoorCount,
    required this.sharedDoorCount,
    required this.receivingDoorCount,
  });

  final int ownedDoorCount;
  final int sharedDoorCount;
  final int receivingDoorCount;

  factory AccountOverviewDoorSummaryDto.fromJson(Map<String, dynamic> json) {
    return AccountOverviewDoorSummaryDto(
      ownedDoorCount: _count(json['ownedDoorCount']),
      sharedDoorCount: _count(json['sharedDoorCount']),
      receivingDoorCount: _count(json['receivingDoorCount']),
    );
  }

  static int _count(Object? value) {
    if (value is int && value >= 0) {
      return value;
    }
    throw const FormatException('Account overview contains an invalid count.');
  }
}
