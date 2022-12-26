import SwiftUI

public extension View {
    func previewConsole(alignment: Alignment? = nil, options: PreviewConsoleModifier.Options, source: StaticString = #file) -> some View {
        #if DEBUG
        modifier(PreviewConsoleModifier(alignment: alignment, options: options, source: source))
            .injectPreviewWindow()
        #else
        self
        #endif
    }
}

#if DEBUG
public struct PreviewConsoleModifier: ViewModifier {

    /// Configures the behavior of ``PreviewConsoleModifier``.
    public struct Options: OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// The preview console will only be shown when it's running in interactive mode (play button in Xcode's canvas).
        public static let interactiveOnly = Options(rawValue: 1 << 0)
    }

    public var alignment: Alignment?
    public var options: Options
    public var source: StaticString

    @ViewBuilder
    public func body(content: Content) -> some View {
        #if DEBUG
        if !ProcessInfo.isSwiftUIPreview {
            let _ = Self.warnImproperUse()
            content
        } else {
            if options.contains(.interactiveOnly) {
                if ProcessInfo.isInteractiveSwiftUIPreview {
                    PreviewConsoleContainer(alignment: alignment, source: source) { content }
                } else {
                    content
                }
            } else {
                PreviewConsoleContainer(alignment: alignment, source: source) { content }
            }
        }
        #else
        content
        #endif
    }

}

private struct PreviewConsoleContainer<Content>: View where Content: View {
    var alignment: Alignment?
    var source: StaticString
    var content: () -> Content

    init(alignment: Alignment?, source: StaticString, @ViewBuilder content: @escaping () -> Content) {
        self.alignment = alignment
        self.source = source
        self.content = content
    }

    @Environment(\.previewWindow)
    private var previewWindow

    @Environment(\.displaySelector)
    private var displaySelector

    @State private var consoleController: ConsoleWindowController?

    var body: some View {
        content()
            .onChange(of: previewWindow) { targetWindow in
                guard let targetWindow else { return }

                consoleController?.close()

                let controller = ConsoleWindowController(
                    targetting: targetWindow,
                    alignment: alignment,
                    displaySelector: displaySelector,
                    source: source
                )
                controller.showWindow(nil)

                consoleController = controller
            }
    }
}

// MARK: - Console UI Implementation

final class ConsoleWindowController: NSWindowController {

    weak var trackedWindow: NSWindow?
    var alignment: Alignment?
    var displaySelector: DisplaySelector?

    convenience init(targetting trackedWindow: NSWindow, alignment: Alignment?, displaySelector: DisplaySelector, source: StaticString) {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: PreviewConsoleView.minWidth, height: PreviewConsoleView.minHeight),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView, .hudWindow, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.hidesOnDeactivate = false
        panel.alphaValue = 0

        self.init(window: panel)

        self.trackedWindow = trackedWindow
        self.alignment = alignment
        self.displaySelector = displaySelector

        panel.title = URL(fileURLWithPath: "\(source)").deletingPathExtension().lastPathComponent

        contentViewController = NSHostingController(rootView: PreviewConsoleView())
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        ProcessPipe.current.activate()

        DispatchQueue.main.async {
            self.positionWindows()
            self.window?.alphaValue = 1
        }
    }

    private let padding: CGFloat = 22

    private func positionWindows() {
        NSLog("👁️‍🗨️ Display selector: \(String(describing: displaySelector))")

        if let alignment {
            #warning("TODO: Allow user to specify display for this modifier as well")
            window?.position(on: .main!, using: alignment, ignoreSafeArea: false)
        } else {
            positionRelativeToPreview()
        }
    }

    private func positionRelativeToPreview() {
        guard let consoleWindow = window, let trackedWindow else { return }

        var trackedFrame = trackedWindow.frame
        trackedFrame.origin.y += consoleWindow.frame.height

        trackedWindow.setFrame(trackedFrame, display: true)

        var consoleFrame = consoleWindow.frame
        consoleFrame.origin.x = trackedFrame.midX - consoleFrame.width / 2
        consoleFrame.origin.y = trackedFrame.maxY - trackedFrame.height - consoleFrame.height - padding

        consoleWindow.setFrame(consoleFrame, display: true)
    }

}

// MARK: - Internal Preview

struct PreviewConsoleTestView: View {
    var body: some View {
        VStack {
            Button("Log") {
                print("Logging something at \(Date.now)")
            }
        }
            .frame(width: 200, height: 200)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("⏰ This message was delayed by half a second")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("⏰⏰ This one was delayed by one second")

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            print("👋🏻 Just logging one last time")
                        }
                    }
                }
            }
    }
}

struct PreviewConsoleTestView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewConsoleTestView()
            .pin(to: .builtInDisplay, alignment: .topTrailing, options: [])
            .previewConsole(alignment: .topTrailing, options: [])
    }
}
#endif
