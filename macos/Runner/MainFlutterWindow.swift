import Cocoa
import FlutterMacOS
import window_manager

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }

  // https://leanflutter.dev/zh/documentation/window_manager/quick-start#macos-1
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }

  @IBAction func showPreferences(_ sender: Any?) {
    guard let flutterViewController = self.contentViewController as?FlutterViewController else {
      return
    }
      let channel = FlutterMethodChannel(name: "cn.belier.certimate/channel", binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.invokeMethod("openSettings", arguments: nil)
  }
}
