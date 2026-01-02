import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Register custom speech recognition plugin
    let controller = window?.rootViewController as! FlutterViewController
    SpeechRecognitionPlugin.register(with: registrar(forPlugin: "SpeechRecognitionPlugin")!)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
