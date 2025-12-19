import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    //  https://leanflutter.dev/zh/documentation/window_manager/quick-start#macos
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  // https://github.com/macosui/macos_ui/issues/328#issuecomment-1403568232
  // https://leanflutter.dev/zh/blog/click-dock-icon-to-restore-after-closing-the-window
  override func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    if !flag {
      for window in NSApp.windows {
        if (window.isFloatingPanel && window.title == "Colors") {
          if (!window.isVisible) {
            window.orderOut(self)
          }
        }else{
          if !window.isVisible {
            window.setIsVisible(true)
          }
          window.makeKeyAndOrderFront(self)
          NSApp.activate(ignoringOtherApps: true)
        }
      }
    }
    return true
  }
}
