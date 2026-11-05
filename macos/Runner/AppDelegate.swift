import UIKit
import Flutter
import GoogleMaps
import OSLog


@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Debug")
        // 1. Retrieve the key from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "googleMapsApiKey") as? String {
            // 2. Provide the key to GMSServices
            GMSServices.provideAPIKey(apiKey)
            //print("Registered Google Maps API Key : \(apiKey)")
            //logger.notice("Registered Google Maps API Key : \(apiKey)")
        } else {
            print("Error: Google Maps API Key missing from Info.plist")
            logger.error("Error: Google Maps API Key missing from Info.plist")
        }
        //GeneratedPluginRegistrant.register(with: self) - picked up via FlutterAppDelegate
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}
