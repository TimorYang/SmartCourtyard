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
    ref.listen(accountControllerProvider, (_, next) {
      next.whenOrNull(
        data: (profile) =>
            _syncSelectedRegion(profile?.regionCode ?? profile?.country),
      );
    });

    final regionsFuture = repository.fetchRegionOptions(
      requestId:
          'account-region-options-${DateTime.now().microsecondsSinceEpoch}',
    );
    final profileFuture = ref.read(accountControllerProvider.future);

    final regions = await regionsFuture;
    final profile = await profileFuture;

    return RegionSelectionState(
      regions: regions,
      selectedRegionCode: _selectedRegionCode(
        regions,
        profile?.regionCode ?? profile?.country,
      ),
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

  void _syncSelectedRegion(String? profileRegionCode) {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null || current.isSaving) {
      return;
    }

    final selectedRegionCode = _selectedRegionCode(
      current.regions,
      profileRegionCode,
    );
    if (current.selectedRegionCode == selectedRegionCode) {
      return;
    }
    state = AsyncData(
      RegionSelectionState(
        regions: current.regions,
        selectedRegionCode: selectedRegionCode,
      ),
    );
  }

  String? _selectedRegionCode(
    List<RegionOption> regions,
    String? profileRegionCode,
  ) {
    final normalizedProfileCode = _normalizeRegionCode(profileRegionCode);
    if (normalizedProfileCode == null) {
      return regions.isEmpty ? null : regions.first.code;
    }

    for (final region in regions) {
      if (_normalizeRegionCode(region.code) == normalizedProfileCode) {
        return region.code;
      }
    }
    return null;
  }

  String? _normalizeRegionCode(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed.toUpperCase();
  }
}
