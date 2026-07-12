/// Local-only network inspection settings.
///
/// Keep these disabled unless a developer explicitly needs to inspect traffic.
abstract final class NetworkDebugSettings {
  static const proxy = 'PROXY 192.168.50.48:9090';
  // static const proxy = '';

  /// Never enable this outside a short-lived, local debugging session.
  static const allowInvalidProxyCertificates = true;
}
