import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "better_brushing/volume_buttons"
  private var channel: FlutterMethodChannel?
  private var volumePauseEnabled = false
  private var volumeObservation: NSKeyValueObservation?
  private var lastVolume: Float = AVAudioSession.sharedInstance().outputVolume

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      channel = FlutterMethodChannel(
        name: channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel?.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "setEnabled":
          let enabled = call.arguments as? Bool ?? false
          self?.setVolumePauseEnabled(enabled)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setVolumePauseEnabled(_ enabled: Bool) {
    volumePauseEnabled = enabled
    if enabled {
      let session = AVAudioSession.sharedInstance()
      try? session.setActive(true)
      lastVolume = session.outputVolume
      volumeObservation = session.observe(\.outputVolume, options: [.new]) { [weak self] _, change in
        guard let self, self.volumePauseEnabled else {
          return
        }
        let volume = change.newValue ?? self.lastVolume
        if volume != self.lastVolume {
          self.lastVolume = volume
          self.channel?.invokeMethod("volumeButtonPressed", arguments: nil)
        }
      }
    } else {
      volumeObservation = nil
    }
  }
}
