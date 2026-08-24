enum DoorRealtimeStatus {
  open,
  closed,
  stopped,
  opening,
  closing,
  running,
  unknown,
}

enum DoorMotorState { opening, stopped, closing, unknown }

class DoorRealtimeState {
  const DoorRealtimeState({this.status, this.motorState, this.positionPercent});

  final DoorRealtimeStatus? status;
  final DoorMotorState? motorState;
  final double? positionPercent;
}
