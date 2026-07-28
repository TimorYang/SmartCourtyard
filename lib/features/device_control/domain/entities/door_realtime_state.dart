enum DoorRealtimeStatus {
  open,
  closed,
  stopped,
  opening,
  closing,
  running,
  unknown,
}

class DoorRealtimeState {
  const DoorRealtimeState({this.status, this.positionPercent});

  final DoorRealtimeStatus? status;
  final double? positionPercent;
}
