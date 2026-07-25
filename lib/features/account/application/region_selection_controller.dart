import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/region_option.dart';

final regionSelectionControllerProvider =
    NotifierProvider<RegionSelectionController, RegionSelectionState>(
      RegionSelectionController.new,
    );

class RegionSelectionState {
  const RegionSelectionState({
    required this.regions,
    required this.selectedRegionCode,
  });

  final List<RegionOption> regions;
  final String selectedRegionCode;

  RegionSelectionState copyWith({String? selectedRegionCode}) {
    return RegionSelectionState(
      regions: regions,
      selectedRegionCode: selectedRegionCode ?? this.selectedRegionCode,
    );
  }
}

class RegionSelectionController extends Notifier<RegionSelectionState> {
  static const _regions = <RegionOption>[
    RegionOption(code: 'CN'),
    RegionOption(code: 'US'),
    RegionOption(code: 'GB'),
    RegionOption(code: 'FR'),
    RegionOption(code: 'CA'),
  ];

  @override
  RegionSelectionState build() {
    return const RegionSelectionState(
      regions: _regions,
      selectedRegionCode: 'CN',
    );
  }

  void select(String regionCode) {
    if (!_regions.any((region) => region.code == regionCode)) {
      return;
    }
    state = state.copyWith(selectedRegionCode: regionCode);
  }
}
