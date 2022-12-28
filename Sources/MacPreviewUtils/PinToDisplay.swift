import SwiftUI
import OSLog

// MARK: - Public Interfaces

public extension View {

    /// See ``PinToDisplayModifier``.
    @ViewBuilder
    func pin(to display: DisplaySelector, alignment: Alignment = .center, options: PinToDisplayModifier.Options = []) -> some View {
        #if DEBUG
        if ProcessInfo.isSwiftUIPreview {
            modifier(PinToDisplayModifier(
                alignment: alignment,
                options: options
            ))
            .environment(\.displaySelector, display)
        } else {
            let _ = PinToDisplayModifier.warnImproperUse()
            self
        }
        #else
        self
        #endif
    }
}

/// Type used to filter the available displays on a Mac in order to select a given display for SwiftUI previews.
public struct DisplaySelector: ExpressibleByStringLiteral {

    /// The closure that's executed for each available display.
    public var filter: (NSScreen) -> Bool

    /// Initializes a predicate for filtering based on a display's name.
    /// - Parameter value: A value that the target display's localized name should contain (case insensitive).
    ///
    /// When selecting a display based on name, you don't have to call this initializer,
    /// you can initialize a ``DisplaySelector`` from a string literal:
    ///
    /// ```swift
    /// MyView()
    ///     .pin(to: "dell")
    /// ```
    public init(stringLiteral value: StringLiteralType) {
        self.filter = { $0.localizedName.localizedCaseInsensitiveContains(value) }
    }

    /// Initializes a predicate for filtering based on custom criteria.
    /// - Parameter filter: A closure that takes an `NSScreen` and returns `true` if the display should be selected.
    /// The first display in the `NSScreen.screens` array that matches the filter will be used.
    public init(_ filter: @escaping (NSScreen) -> Bool) {
        self.filter = filter
    }

}

public extension DisplaySelector {
    /// A predicate that matches the Mac's current main display.
    static let mainDisplay: DisplaySelector = {
        DisplaySelector { $0 == NSScreen.main }
    }()
    /// A predicate that matches the first external display that's connected to the Mac.
    /// "External display" is any display that's not the current main display for the Mac.
    static let externalDisplay: DisplaySelector = {
        DisplaySelector { $0 != NSScreen.main }
    }()
    /// A predicate that matches the first Sidecar display that's available.
    static let sidecarDisplay: DisplaySelector = "sidecar"
    /// A predicate that matches the built-in display on Mac laptops.
    static let builtInDisplay: DisplaySelector = "built-in"
}

// MARK: - Implementation

/// Causes the SwiftUI view to always show up in a specific display.
public struct PinToDisplayModifier: ViewModifier {

    /// Configures the behavior of the ``PinToDisplayModifier``.
    public struct Options: OptionSet {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// The preview will only be shown pinned to the specified display when it's running in interactive mode (play button in Xcode's canvas).
        public static let interactiveOnly = Options(rawValue: 1 << 0)

        /// The preview window will ignore safe areas like the Dock and Menu Bar.
        ///
        /// - note: If you'd like to have an interactive preview that overlaps with the macOS Menu Bar,
        /// you must set both ``ignoreSafeArea`` and ``hideTitleBar``.
        public static let ignoreSafeArea = Options(rawValue: 1 << 1)

        /// The preview window will have its title bar hidden when running in interactive mode.
        ///
        /// - note: If you'd like to have an interactive preview that overlaps with the macOS Menu Bar,
        /// you must set both ``ignoreSafeArea`` and ``hideTitleBar``.
        public static let hideTitleBar = Options(rawValue: 1 << 2)
    }

    var alignment: Alignment
    var options: Options

    /// Causes the SwiftUI view to always show up in a specific display.
    /// - Parameter alignment: Determines the position for the preview window within the specified display's bounds.
    /// Supported alignments are `.leading`, `.center`, `.trailing`, `.top`, `.bottom`, or any valid combination such as `.topLeading`.
    /// - Parameter options: Controls the behavior of the display pinning, such as whether to enable it only for interactive previews and how to handle safe areas.
    ///
    /// Apply this modifier to a macOS SwiftUI preview's contents in order to always show the preview in a specific display.
    /// For more information on how to select the display, read ``DisplaySelector``.
    ///
    /// This modifier has no effect if the app is not running in a SwiftUI preview, or in release builds.
    ///
    /// - note: There's a convenient `.pin(...)` extension on `View` for this modifier, prefer that over using it directly.
    public init(alignment: Alignment, options: Options = []) {
        self.alignment = alignment
        self.options = options
    }

    #if DEBUG
    @Environment(\.displaySelector)
    private var selector: DisplaySelector

    private let windowSubject = NSWindowSubject()

    public func body(content: Content) -> some View {
        if ProcessInfo.isSwiftUIPreview {
            content
                .background {
                    PreviewWindowProvidingView(subject: windowSubject)
                }
                .onReceive(windowSubject) { window in
                    guard let window else { return }
                    attach(to: window)
                }
        } else {
            let _ = Self.warnImproperUse()
            content
        }
    }

    private func attach(to window: NSWindow) {
        guard let targetScreen = NSScreen.matching(selector) else { return }

        let app = NSApplication.shared
        let windows = app.windows

        if options.contains(.interactiveOnly) {
            guard ProcessInfo.isInteractiveSwiftUIPreview else { return }
        }

        window.level = options.contains(.ignoreSafeArea) ? .statusBar : .floating
        window.makeKeyAndOrderFront(nil)
        window.isMovable = false
        window.alphaValue = 0
        window.hidesOnDeactivate = false

        windows.filter({ $0 !== window && !($0 is MacPreviewUtilsWindow) }).forEach({ $0.close() })

        app.activateForPreview {
            if options.contains(.hideTitleBar) {
                window.styleMask.remove(.titled)
            }

            window.position(
                on: targetScreen,
                using: alignment,
                ignoreSafeArea: options.contains(.ignoreSafeArea)
            )

            DispatchQueue.main.async {
                window.alphaValue = 1
            }
        }
    }
    #else
    public func body(content: Content) -> some View {
        content
    }
    #endif

}

#if DEBUG
extension DisplaySelector {
    func callAsFunction(_ screen: NSScreen?) -> Bool {
        guard let screen else { return false }
        return filter(screen)
    }
}

struct DisplaySelectorEnvironmentKey: EnvironmentKey {
    static var defaultValue = DisplaySelector.mainDisplay
}

extension EnvironmentValues {
    var displaySelector: DisplaySelectorEnvironmentKey.Value {
        get { self[DisplaySelectorEnvironmentKey.self] }
        set { self[DisplaySelectorEnvironmentKey.self] = newValue }
    }
}

extension NSWindow {
    func position(on screen: NSScreen, using alignment: Alignment, ignoreSafeArea: Bool) {
        let screenFrame = ignoreSafeArea ? screen.frame : screen.visibleFrame
        var f = frame

        switch alignment.horizontal {
        case .leading:
            f.origin.x = screenFrame.minX
        case .trailing:
            f.origin.x = screenFrame.maxX - f.size.width
        default:
            f.origin.x = screenFrame.midX - f.size.width / 2
        }

        switch alignment.vertical {
        case .top:
            f.origin.y = screenFrame.maxY - f.size.height
        case .bottom:
            f.origin.y = screenFrame.minY
        default:
            f.origin.y = screenFrame.midY - f.size.height / 2
        }

        setFrame(f, display: true, animate: false)
    }
}

extension NSScreen {
    static func matching(_ selector: DisplaySelector) -> NSScreen? {
        NSScreen.screens.first(where: { selector($0) })
    }
}

struct PreviewOnExternalDisplay_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, world")
            .foregroundColor(.green)
            .font(.largeTitle)
            .frame(width: 200, height: 200)
            .padding()
            .pin(to: .builtInDisplay, alignment: .top, options: [.interactiveOnly])
    }
}
#endif
