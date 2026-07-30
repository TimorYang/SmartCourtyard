import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/region_option.dart';
import 'providers.dart';

final regionSelectionControllerProvider =
    AsyncNotifierProvider<RegionSelectionController, RegionSelectionState>(
      RegionSelectionController.new,
    );

class RegionSelectionState {
  const RegionSelectionState({
    required this.regions,
    required this.selectedRegionCode,
    this.isSaving = false,
  });

  final List<RegionOption> regions;
  final String? selectedRegionCode;
  final bool isSaving;

  RegionSelectionState copyWith({String? selectedRegionCode, bool? isSaving}) {
    return RegionSelectionState(
      regions: regions,
      selectedRegionCode: selectedRegionCode ?? this.selectedRegionCode,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class RegionSelectionController extends AsyncNotifier<RegionSelectionState> {
  @override
  Future<RegionSelectionState> build() async {
    final repository = ref.watch(accountRepositoryProvider);
    final profile = await repository.readCachedProfile();
    final regions = await repository.fetchRegionOptions(
      requestId:
          'account-region-options-${DateTime.now().microsecondsSinceEpoch}',
    );
    final profileRegionCode = profile?.regionCode ?? profile?.country;
    final selectedRegionCode =
        regions.any((region) => region.code == profileRegionCode)
        ? profileRegionCode
        : regions.isEmpty
        ? null
        : regions.first.code;
    return RegionSelectionState(
      regions: regions,
      selectedRegionCode: selectedRegionCode,
    );
  }

  Future<bool> select(String regionCode) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null || current.isSaving) {
      return false;
    }
    if (current.selectedRegionCode == regionCode) return true;
    if (!current.regions.any((region) => region.code == regionCode)) {
      return false;
    }
    state = AsyncData(current.copyWith(isSaving: true));
    final updated = await ref
        .read(accountControllerProvider.notifier)
        .updateRegion(regionCode);
    state = AsyncData(
      current.copyWith(
        selectedRegionCode: updated ? regionCode : current.selectedRegionCode,
        isSaving: false,
      ),
    );
    return updated;
  }
}
