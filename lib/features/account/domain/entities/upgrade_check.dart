enum UpgradePackageKind { application, firmware }

enum UpgradeScheduleMode { immediate, postpone }

enum UpgradeTargetAvailability { online, offline }

enum UpgradeExecutionStatus { idle, upgrading, completed }

/// A downloadable update displayed in the app or firmware update cards.
class UpgradePackage {
  const UpgradePackage({
    required this.id,
    required this.name,
    required this.version,
    required this.sizeLabel,
    required this.releaseDateLabel,
    required this.kind,
    this.isSelected = false,
  });

  /// Stable update identifier; not shown in the UI. Required String, e.g. app-1-2-5.
  final String id;

  /// Update name shown beside the selection control. Required String.
  final String name;

  /// Target release version shown below the package name. Required String.
  final String version;

  /// Download size shown in package metadata. Required String, e.g. 18.3 MB.
  final String sizeLabel;

  /// Release date shown in package metadata. Required String, e.g. 2026-06-29.
  final String releaseDateLabel;

  /// Whether this is the application card or a device firmware package. Required enum.
  final UpgradePackageKind kind;

  /// Selection state for the checkbox. Required bool with a false default.
  final bool isSelected;

  UpgradePackage copyWith({bool? isSelected}) => UpgradePackage(
    id: id,
    name: name,
    version: version,
    sizeLabel: sizeLabel,
    releaseDateLabel: releaseDateLabel,
    kind: kind,
    isSelected: isSelected ?? this.isSelected,
  );

  factory UpgradePackage.fromJson(Map<String, dynamic> json) => UpgradePackage(
    id: json['id'] as String,
    name: json['name'] as String,
    version: json['version'] as String,
    sizeLabel: json['sizeLabel'] as String,
    releaseDateLabel: json['releaseDateLabel'] as String,
    kind: UpgradePackageKind.values.byName(json['kind'] as String),
    isSelected: json['isSelected'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'sizeLabel': sizeLabel,
    'releaseDateLabel': releaseDateLabel,
    'kind': kind.name,
    'isSelected': isSelected,
  };

  factory UpgradePackage.mockApp() => const UpgradePackage(
    id: 'app-1-2-5',
    name: 'App version update',
    version: 'v1.2.5',
    sizeLabel: '18.3 MB',
    releaseDateLabel: '2026-06-29',
    kind: UpgradePackageKind.application,
  );
}

/// A device firmware group rendered as an expandable card.
class UpgradeableDevice {
  const UpgradeableDevice({
    required this.id,
    required this.name,
    required this.doorDeviceName,
    required this.serialNumber,
    required this.currentVersion,
    required this.packages,
    this.isExpanded = true,
    this.status = UpgradeExecutionStatus.idle,
    this.progress = 0,
  });

  /// Stable device identifier; not shown in the UI. Required String.
  final String id;

  /// Device title shown in the card header. Required String.
  final String name;

  /// Door device name shown in the detail section. Required String.
  final String doorDeviceName;

  /// Device serial number shown in the detail section. Required String.
  final String serialNumber;

  /// Installed version shown in the detail section. Required String.
  final String currentVersion;

  /// Firmware packages nested under this device. Required non-empty list.
  final List<UpgradePackage> packages;

  /// Whether the firmware details are visible. Required bool with a true default.
  final bool isExpanded;

  /// Mock execution state for the progress card. Required enum with idle default.
  final UpgradeExecutionStatus status;

  /// Mock update percentage shown in the progress card. Required integer from 0 to 100.
  final int progress;

  bool get hasSelection => packages.any((item) => item.isSelected);
  bool get isFullySelected =>
      packages.isNotEmpty && packages.every((item) => item.isSelected);

  UpgradeableDevice copyWith({
    List<UpgradePackage>? packages,
    bool? isExpanded,
    UpgradeExecutionStatus? status,
    int? progress,
  }) => UpgradeableDevice(
    id: id,
    name: name,
    doorDeviceName: doorDeviceName,
    serialNumber: serialNumber,
    currentVersion: currentVersion,
    packages: packages ?? this.packages,
    isExpanded: isExpanded ?? this.isExpanded,
    status: status ?? this.status,
    progress: progress ?? this.progress,
  );

  factory UpgradeableDevice.fromJson(Map<String, dynamic> json) =>
      UpgradeableDevice(
        id: json['id'] as String,
        name: json['name'] as String,
        doorDeviceName: json['doorDeviceName'] as String,
        serialNumber: json['serialNumber'] as String,
        currentVersion: json['currentVersion'] as String,
        packages: (json['packages'] as List<dynamic>)
            .map(
              (item) => UpgradePackage.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
        isExpanded: json['isExpanded'] as bool? ?? true,
        status: UpgradeExecutionStatus.values.byName(
          json['status'] as String? ?? UpgradeExecutionStatus.idle.name,
        ),
        progress: json['progress'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'doorDeviceName': doorDeviceName,
    'serialNumber': serialNumber,
    'currentVersion': currentVersion,
    'packages': packages.map((item) => item.toJson()).toList(growable: false),
    'isExpanded': isExpanded,
    'status': status.name,
    'progress': progress,
  };

  factory UpgradeableDevice.mock({required String id, required String name}) =>
      UpgradeableDevice(
        id: id,
        name: name,
        doorDeviceName: 'GDO',
        serialNumber: 'SN-2024-001',
        currentVersion: 'v2.1.0',
        packages: const [
          UpgradePackage(
            id: 'motor',
            name: 'Motor · Mo store name',
            version: 'v1.2.5',
            sizeLabel: '18.3 MB',
            releaseDateLabel: '2026-06-29',
            kind: UpgradePackageKind.firmware,
          ),
          UpgradePackage(
            id: 'wifi',
            name: 'WiFi module WiFi · Wireless module',
            version: 'v1.2.5',
            sizeLabel: '18.3 MB',
            releaseDateLabel: '2026-06-29',
            kind: UpgradePackageKind.firmware,
          ),
        ],
      );
}

/// A target availability row shown in the upgrade scheduling dialog.
class UpgradeTargetStatus {
  const UpgradeTargetStatus({required this.name, required this.availability});

  /// Device location name shown in the scheduling dialog. Required String.
  final String name;

  /// Current online state shown by the colored status tag. Required enum.
  final UpgradeTargetAvailability availability;

  factory UpgradeTargetStatus.fromJson(Map<String, dynamic> json) =>
      UpgradeTargetStatus(
        name: json['name'] as String,
        availability: UpgradeTargetAvailability.values.byName(
          json['availability'] as String,
        ),
      );

  Map<String, dynamic> toJson() => {
    'name': name,
    'availability': availability.name,
  };

  factory UpgradeTargetStatus.mockOnline() => const UpgradeTargetStatus(
    name: 'Parking Entrance',
    availability: UpgradeTargetAvailability.online,
  );
}

/// Upgrade time choice held by the confirmation dialog.
class UpgradeSchedule {
  const UpgradeSchedule({required this.mode, this.scheduledAt});

  /// Immediate or postponed upgrade choice. Required enum.
  final UpgradeScheduleMode mode;

  /// Local date/time selected for postponed updates; null for immediate mode.
  final DateTime? scheduledAt;

  UpgradeSchedule copyWith({
    UpgradeScheduleMode? mode,
    DateTime? scheduledAt,
  }) => UpgradeSchedule(
    mode: mode ?? this.mode,
    scheduledAt: scheduledAt ?? this.scheduledAt,
  );

  factory UpgradeSchedule.fromJson(Map<String, dynamic> json) =>
      UpgradeSchedule(
        mode: UpgradeScheduleMode.values.byName(json['mode'] as String),
        scheduledAt: json['scheduledAt'] == null
            ? null
            : DateTime.parse(json['scheduledAt'] as String),
      );

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'scheduledAt': scheduledAt?.toIso8601String(),
  };

  factory UpgradeSchedule.mock() => UpgradeSchedule(
    mode: UpgradeScheduleMode.postpone,
    scheduledAt: DateTime.now(),
  );
}
