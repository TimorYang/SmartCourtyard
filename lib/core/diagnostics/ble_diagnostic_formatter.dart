import '../../platform_bridge/hardware_models.dart';

class BleDiagnosticFormatter {
  int _nextDisplayNumber = 1;
  final Map<String, _PendingDiagnostic> _pending = {};

  String format(BleDiagnosticEvent event) {
    _pending.removeWhere(
      (_, pending) =>
          event.timestampMillis - pending.timestampMillis > 60 * 1000,
    );
    final pending = _pending[event.transactionId];
    final displayNumber = switch (event.direction) {
      BleDiagnosticDirection.tx => _rememberTx(event),
      BleDiagnosticDirection.rx =>
        pending?.displayNumber ?? _nextDisplayNumber++,
    };
    final elapsedMillis =
        event.elapsedMillis ??
        (pending == null
            ? null
            : event.timestampMillis - pending.timestampMillis);
    final matched =
        event.direction == BleDiagnosticDirection.tx || pending != null;
    if (event.direction == BleDiagnosticDirection.rx && pending != null) {
      _pending.remove(event.transactionId);
    }

    final divider = '═' * 62;
    final sectionDivider = '─' * 60;
    final directionTitle = event.direction == BleDiagnosticDirection.tx
        ? '📤 BLE TX'
        : '📥 BLE RX';
    final protocolPayload = event.direction == BleDiagnosticDirection.tx
        ? event.originPayload
        : event.decryptedPayload;
    final lines = <String>[
      divider,
      '${directionTitle.padRight(42)}#${displayNumber.toString().padLeft(6, '0')}',
      divider,
      '',
      _field('Time', _formatTimestamp(event.timestampMillis)),
      if (event.direction == BleDiagnosticDirection.rx)
        _field(
          'Elapsed',
          elapsedMillis == null ? 'unknown' : '$elapsedMillis ms',
        ),
      _field(
        'Direction',
        event.direction == BleDiagnosticDirection.tx
            ? 'APP → DEVICE'
            : 'DEVICE → APP',
      ),
      _field('Type', _formatFrameType(protocolPayload)),
      _field('Operation', event.operation),
      _field('Command', _hexWord(event.command)),
      if (event.control != null) _field('Control', _hexWord(event.control!)),
      _field('Sequence', '${_hexWord(event.sequence)} (${event.sequence})'),
      _field('Length', '${event.packet.length} bytes'),
      if (event.requestId != null) _field('Request ID', event.requestId!),
      '',
      _field('Encrypt', event.encryption),
    ];

    if (event.direction == BleDiagnosticDirection.tx) {
      _appendPayloadSection(
        lines,
        title: 'Plain Protocol Payload',
        payload: event.originPayload,
        divider: sectionDivider,
      );
      _appendPayloadSection(
        lines,
        title: 'Encrypted Payload',
        payload: event.encryptedPayload,
        divider: sectionDivider,
      );
    } else {
      _appendPayloadSection(
        lines,
        title: 'Encrypted Payload',
        payload: event.encryptedPayload,
        divider: sectionDivider,
      );
      _appendPayloadSection(
        lines,
        title: 'Decrypted Protocol Payload',
        payload: event.decryptedPayload,
        divider: sectionDivider,
      );
    }

    _appendDataSection(
      lines,
      protocolPayload: protocolPayload,
      divider: sectionDivider,
    );

    _appendPayloadSection(
      lines,
      title: 'Packet',
      payload: event.packet,
      divider: sectionDivider,
    );

    if (event.direction == BleDiagnosticDirection.rx) {
      final result = !matched
          ? '⚠️ Unmatched'
          : switch (event.result?.toLowerCase()) {
              'success' => '✅ Success',
              'failure' || 'failed' => '❌ Failed',
              final value? when value.isNotEmpty => value,
              _ => '✅ Received',
            };
      lines
        ..add('')
        ..add('Result')
        ..add(sectionDivider)
        ..add(result);
    }

    lines
      ..add('')
      ..add(divider);
    return lines.join('\n');
  }

  int _rememberTx(BleDiagnosticEvent event) {
    final displayNumber = _nextDisplayNumber++;
    _pending[event.transactionId] = _PendingDiagnostic(
      displayNumber: displayNumber,
      timestampMillis: event.timestampMillis,
    );
    return displayNumber;
  }

  static String _field(String label, String value) =>
      '${label.padRight(12)}: $value';

  static String _hexWord(int value) =>
      '0x${value.toRadixString(16).padLeft(4, '0').toUpperCase()}';

  static String _hex(List<int> bytes) => bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join();

  static String _formatFrameType(List<int> protocolPayload) {
    if (protocolPayload.isEmpty) {
      return 'unknown';
    }
    final type = protocolPayload.first;
    final label = switch (type) {
      0x03 => 'Request',
      0x04 => 'Response',
      _ => 'Unknown',
    };
    return '0x${type.toRadixString(16).padLeft(2, '0').toUpperCase()} ($label)';
  }

  static void _appendDataSection(
    List<String> lines, {
    required List<int> protocolPayload,
    required String divider,
  }) {
    final data = protocolPayload.length > 5
        ? protocolPayload.sublist(5)
        : const <int>[];
    lines
      ..add('')
      ..add('Data')
      ..add(divider)
      ..add(data.isEmpty ? 'none' : _hex(data));
  }

  static void _appendPayloadSection(
    List<String> lines, {
    required String title,
    required List<int> payload,
    required String divider,
  }) {
    if (payload.isEmpty) {
      return;
    }
    lines
      ..add('')
      ..add(title)
      ..add(divider)
      ..add(_hex(payload));
  }

  static String _formatTimestamp(int timestampMillis) {
    final value = DateTime.fromMillisecondsSinceEpoch(timestampMillis);
    String two(int number) => number.toString().padLeft(2, '0');
    String three(int number) => number.toString().padLeft(3, '0');
    return '${value.year}-${two(value.month)}-${two(value.day)} '
        '${two(value.hour)}:${two(value.minute)}:${two(value.second)}.'
        '${three(value.millisecond)}';
  }
}

class _PendingDiagnostic {
  const _PendingDiagnostic({
    required this.displayNumber,
    required this.timestampMillis,
  });

  final int displayNumber;
  final int timestampMillis;
}
