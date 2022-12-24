import SwiftUI

// MARK: - Public Interfaces

public extension View {

    /// See ``PinToDisplayModifier``.
    @ViewBuilder
    func pin(to display: DisplaySelector, alignment: Alignment = .center, interactiveOnly: Bool = false) -> some View {
        if ProcessInfo.isSwiftUIPreview {
            modifier(PinToDisplayModifier(selector: display, alignment: alignment, interactiveOnly: interactiveOnly))
        } else {
            self
        }
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
    static let externalDisplay: DisplaySelector = {
        DisplaySelector { $0 != NSScreen.main }
    }()
    /// A predicate that matches the first Sidecar display that's available.
    static let sidecarDisplay: DisplaySelector = "sidecar"
    /// A predicate that matches the built-in display on Mac laptops.
    static let builtInDisplay: DisplaySelector = "built-in"
}

// MARK: - Implementation

#if DEBUG
extension DisplaySelector {
    func callAsFunction(_ screen: NSScreen?) -> Bool {
        guard let screen else { return false }
        return filter(screen)
    }
}

/// Causes the SwiftUI view to always show up in a specific display.
public struct PinToDisplayModifier: ViewModifier {

    var selector: DisplaySelector
    var alignment: Alignment
    var interactiveOnly: Bool

    /// Causes the SwiftUI view to always show up in a specific display.
    /// - Parameter predicate: Used to determine which display will be used.
    /// - Parameter alignment: Determines the position for the preview window within the specified display's bounds.
    /// Supported alignments are `.leading`, `.center`, `.trailing`, `.top`, `.bottom`, or any valid combination such as `.topLeading`.
    /// - Parameter interactiveOnly: If `true`, then the modifier will have no effect unless the SwiftUI preview is in interactive mode.
    ///
    /// Apply this modifier to a macOS SwiftUI preview's contents in order to always show the preview in a specific display.
    /// For more information on how to select the display, read ``DisplaySelector``.
    ///
    /// This modifier has no effect if the app is not running in a SwiftUI preview, or in release builds.
    ///
    /// - note: There's a convenient `.pin(...)` extension on `View` for this modifier, prefer that over using it directly.
    public init(selector: DisplaySelector, alignment: Alignment, interactiveOnly: Bool) {
        self.selector = selector
        self.alignment = alignment
        self.interactiveOnly = interactiveOnly
    }

    public func body(content: Content) -> some View {
        content
            .onAppear {
                guard let targetScreen = NSScreen.screens.first(where: { selector($0) }) else { return }

                let app = NSApplication.shared
                let windows = app.windows

                if interactiveOnly {
                    guard ProcessInfo.isInteractiveSwiftUIPreview else { return }
                }

                guard let targetWindow = windows.last else { return }

                targetWindow.level = .floating
                targetWindow.makeKeyAndOrderFront(nil)
                targetWindow.isMovable = false
                targetWindow.alphaValue = 0
                targetWindow.hidesOnDeactivate = false

                windows.filter({ $0 !== targetWindow }).forEach({ $0.close() })

                app.setActivationPolicy(.accessory)
                app.unhide(nil)

                DispatchQueue.main.async {
                    targetWindow.position(on: targetScreen, using: alignment)

                    DispatchQueue.main.async {
                        targetWindow.alphaValue = 1
                        ProcessInfo.activateXcode()
                    }
                }
            }
    }

}

private extension NSWindow {
    func position(on screen: NSScreen, using alignment: Alignment) {
        var f = frame

        switch alignment.horizontal {
        case .leading:
            f.origin.x = screen.frame.minX
        case .trailing:
            f.origin.x = screen.frame.maxX - f.size.width
        default:
            f.origin.x = screen.frame.midX - f.size.width / 2
        }

        switch alignment.vertical {
        case .top:
            f.origin.y = screen.frame.maxY - f.size.height
        case .bottom:
            f.origin.y = screen.frame.minY
        default:
            f.origin.y = screen.frame.midY - f.size.height / 2
        }

        setFrame(f, display: true, animate: false)
    }
}

struct PreviewOnExternalDisplay_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, world 123")
            .foregroundColor(.red)
            .font(.largeTitle)
            .frame(minWidth: 300)
            .padding(120)
            .pin(to: .builtInDisplay, alignment: .topLeading, interactiveOnly: true)
    }
}
#endif
