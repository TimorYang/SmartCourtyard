import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var hardwareBridge: HardwareBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FLINXHardware") else {
      return
    }
    let messenger = registrar.messenger()
    let bridge = HardwareBridge(binaryMessenger: messenger)
    HardwareHostApiSetup.setUp(
      binaryMessenger: messenger,
      api: bridge
    )
    hardwareBridge = bridge
  }
}
