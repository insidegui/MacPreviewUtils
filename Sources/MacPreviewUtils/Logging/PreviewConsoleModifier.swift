import SwiftUI

public extension View {
    func previewConsole(display: DisplaySelector? = nil,
                        alignment: Alignment? = nil,
                        options: PreviewConsoleModifier.Options = [],
                        source: StaticString = #file) -> some View
    {
        #if DEBUG
        modifier(PreviewConsoleModifier(alignment: alignment, options: options, source: source))
            .overrideDisplaySelectorIfNeeded(with: display)
            .injectPreviewWindow()
        #else
        self
        #endif
    }
}

#if DEBUG
extension View {
    @ViewBuilder
    func overrideDisplaySelectorIfNeeded(with selector: DisplaySelector?) -> some View {
        if let selector {
            self
                .environment(\.displaySelector, selector)
        } else {
            self
        }
    }
}

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

    /// Determines which of the Mac's displays will be used to show the console.
    /// If not provided, uses the Mac's main display, or the same display as the ``PinToDisplayModifier``
    /// applied to the view hierarchy.
    public var display: DisplaySelector?

    /// Determines the position of the console within the display's bounds.
    /// If `nil`, then the console will be positioned automatically next to the preview window when using ``PinToDisplayModifier``,
    /// or at the bottom trailing edge if not using the ``PinToDisplayModifier``.
    public var alignment: Alignment?

    /// Configures additional behavior for the console.
    public var options: Options

    /// Used by the console to indicate which Swift file that included the modifier.
    public var source: StaticString

    /// Shows an output console that streams the contents of the app's standard output
    /// when running in SwiftUI previews.
    /// - Parameters:
    ///   - display: See ``display``.
    ///   - alignment: See ``alignment``.
    ///   - options: See ``options-swift.property``
    ///   - source: See ``source``.
    public init(display: DisplaySelector? = nil,
                alignment: Alignment? = nil,
                options: Options,
                source: StaticString)
    {
        self.display = display
        self.alignment = alignment
        self.options = options
        self.source = source
    }

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

    var body: some View {
        content()
            .onChange(of: previewWindow) { [previewWindow] targetWindow in
                guard let targetWindow, targetWindow !== previewWindow else { return }

                let controller = ConsoleWindowController(
                    targetting: targetWindow,
                    alignment: alignment,
                    displaySelector: displaySelector,
                    source: source
                )
                controller.showWindow(nil)
            }
    }
}

// MARK: - Console UI Implementation

final class ConsolePanel: NSPanel, MacPreviewUtilsWindow {

    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        guard let screen else {
            return super.constrainFrameRect(frameRect, to: screen)
        }

        return constrainPreview(to: frameRect, on: screen)
    }

}

final class ConsoleWindowController: NSWindowController {

    static var current: ConsoleWindowController?

    weak var trackedWindow: NSWindow?
    var alignment: Alignment?
    var displaySelector: DisplaySelector?

    convenience init(targetting trackedWindow: NSWindow, alignment: Alignment?, displaySelector: DisplaySelector, source: StaticString) {
        Self.current?.close()
        Self.current = nil

        let panel = ConsolePanel(
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

        Self.current = self
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)

        ProcessPipe.current.activate()

        NSApplication.shared.activateForPreview { [weak self] in
            guard let self = self else { return }

            self.positionWindows()

            DispatchQueue.main.async {
                self.window?.alphaValue = 1
            }
        }
    }

    private let padding: CGFloat = 22

    private var effectiveAlignment: Alignment { alignment ?? .bottomTrailing }

    private var shouldTrackWindow: Bool {
        guard let trackedWindow else { return false }
        return trackedWindow.frame.origin != .zero
    }

    private func positionWindows() {
        guard shouldTrackWindow else {
            positionWithoutTrackedWindow()
            return
        }

        if alignment != nil {
            positionWithoutTrackedWindow()
        } else {
            positionRelativeToPreview()
        }
    }

    private func positionWithoutTrackedWindow() {
        guard let screen = NSScreen.matching(displaySelector ?? .mainDisplay) else { return }

        window?.position(on: screen, using: effectiveAlignment, ignoreSafeArea: false)
    }

    private func positionRelativeToPreview() {
        guard let consoleWindow = window, let trackedWindow else { return }

        var trackedFrame = trackedWindow.frame
        trackedFrame.origin.y += consoleWindow.frame.height
        trackedFrame = trackedWindow.constrainPreview(to: trackedFrame, on: trackedWindow.screen)

        trackedWindow.setFrame(trackedFrame, display: true)

        var consoleFrame = consoleWindow.frame
        consoleFrame.origin.x = trackedFrame.midX - consoleFrame.width / 2
        consoleFrame.origin.y = trackedFrame.maxY - trackedFrame.height - consoleFrame.height - padding

        consoleWindow.setFrame(consoleFrame, display: true)
    }

}

// MARK: - Internal Preview

struct PreviewConsoleTestView: View {
    private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack {
            Button("Log") {
                print("Logging something at \(Date.now)")
            }
        }
            .frame(width: 200, height: 200)
            .onReceive(timer) { _ in
                print("This was print()ed \(Int(Date.now.timeIntervalSinceReferenceDate))")
            }
    }
}

struct PreviewConsoleTestView_Previews: PreviewProvider {
    static var previews: some View {
        PreviewConsoleTestView()
            .pin(to: .mainDisplay, alignment: .topTrailing, options: [])
            .previewConsole()
    }
}
#endif
