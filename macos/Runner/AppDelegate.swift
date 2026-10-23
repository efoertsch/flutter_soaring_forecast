import Cocoa
import FlutterMacOS
import GoogleMaps

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)
        // 1. Retrieve the key from Info.plist
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsAPIKey") as? String {
            // 2. Provide the key to GMSServices
            GMSServices.provideAPIKey(apiKey)
        } else {
            print("Error: Google Maps API Key missing from Info.plist")
        }
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
