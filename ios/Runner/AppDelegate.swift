import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Le a chave do Info.plist (que foi injetada pelo flutter/MapsKey.xcconfig)
    guard let googleMapsAPIKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String else {
      fatalError("Google Maps API Key não encontrada no Info.plist. Verifique sua configuração .xcconfig.")
    }

    // Fornece a chave para o SDK
    GMSServices.provideAPIKey(googleMapsAPIKey)
      
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
