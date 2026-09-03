/// Control modes accepted by the F-box control-mode update API.
///
/// The API wire values are intentionally separate from the values used by the
/// door-detail response model. The update endpoint accepts PB as 0 and OSC as
/// 1, both encoded as strings.
enum FBoxControlMode {
  pb('0'),
  osc('1');

  const FBoxControlMode(this.apiValue);

  final String apiValue;
}
