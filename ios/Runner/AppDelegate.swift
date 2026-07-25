import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mapsApiKey = (
      Bundle.main.object(
        forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
      ) as? String
    )?.trimmingCharacters(in: .whitespacesAndNewlines)

    guard let mapsApiKey,
          !mapsApiKey.isEmpty,
          !mapsApiKey.contains("$("),
          !mapsApiKey.contains("YOUR_") else {
      fatalError(
        "GOOGLE_MAPS_API_KEY is missing. Check MapsKeys.xcconfig and Info.plist."
      )
    }

    guard GMSServices.provideAPIKey(mapsApiKey) else {
      fatalError(
        "Google Maps rejected GOOGLE_MAPS_API_KEY."
      )
    }

    return super.application(
      application,
      didFinishLaunchingWithOptions: launchOptions
    )
  }

  func didInitializeImplicitFlutterEngine(
    _ engineBridge: FlutterImplicitEngineBridge
  ) {
    GeneratedPluginRegistrant.register(
      with: engineBridge.pluginRegistry
    )
  }
}