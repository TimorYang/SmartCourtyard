import '../entities/login_device_context.dart';

abstract interface class LoginDeviceContextProvider {
  Future<LoginDeviceContext> read();
}
