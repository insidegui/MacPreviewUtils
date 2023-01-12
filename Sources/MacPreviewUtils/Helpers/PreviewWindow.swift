#if DEBUG
import SwiftUI
import Combine

extension EnvironmentValues {
    var previewWindow: NSWindow? {
        get { self[PreviewWindowEnvironmentKey.self] }
        set { self[PreviewWindowEnvironmentKey.self] = newValue }
    }
}

private struct PreviewWindowEnvironmentKey: EnvironmentKey {
    static var defaultValue: NSWindow?
}

typealias NSWindowSubject = PassthroughSubject<NSWindow?, Never>

extension View {
    func injectPreviewWindow() -> some View {
        modifier(PreviewWindowModifier())
    }
}

struct PreviewWindowModifier: ViewModifier {

    private let windowSubject = NSWindowSubject()

    @State private var window: NSWindow?

    func body(content: Content) -> some View {
        content
            .environment(\.previewWindow, window)
            .background(
                PreviewWindowProvidingView(subject: windowSubject)
            )
            .onReceive(windowSubject.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)) { [window] newWindow in
                guard newWindow !== window else { return }
                self.window = newWindow
            }
    }

}

struct PreviewWindowProvidingView: NSViewRepresentable {
    typealias NSViewType = _PreviewWindowGrabbingView

    var subject: NSWindowSubject

    func makeNSView(context: Context) -> _PreviewWindowGrabbingView {
        let v = _PreviewWindowGrabbingView { window in
            subject.send(window)
        }
        return v
    }

    func updateNSView(_ nsView: _PreviewWindowGrabbingView, context: Context) {

    }
}

final class _PreviewWindowGrabbingView: NSView {

    var callback: (NSWindow?) -> Void

    init(callback: @escaping (NSWindow?) -> Void) {
        self.callback = callback

        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        callback(window)
    }

}
#endif
