import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // The app has no light theme. Without these two lines macOS paints a light window
    // and light system controls behind the Flutter view while it starts up, and the
    // title bar stays light for the whole session.
    self.backgroundColor = NSColor(
      srgbRed: 0x0A / 255.0, green: 0x0A / 255.0, blue: 0x0B / 255.0, alpha: 1
    )
    self.appearance = NSAppearance(named: .darkAqua)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
