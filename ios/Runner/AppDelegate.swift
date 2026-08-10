import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let googleMapsAPIKey = "AIzaSyC5dhJuUtRPjpahNFgAcilWyo-iqjMrVbc"
  private var isGoogleMapsConfigured = false
  private var googleMapsConfigurationChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    isGoogleMapsConfigured = GMSServices.provideAPIKey(Self.googleMapsAPIKey)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "GoogleMapsConfiguration"
    ) else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "com.diettime.diet_time/google_maps_configuration",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "isConfigured" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.isGoogleMapsConfigured ?? false)
    }
    googleMapsConfigurationChannel = channel
  }
}
