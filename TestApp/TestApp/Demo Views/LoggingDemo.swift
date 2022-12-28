import SwiftUI
import MacPreviewUtils

struct LoggingDemo: View {
    var body: some View {
        VStack {
            Button("Log") {
                print("Logging something at \(Date.now)")
            }
        }
            .frame(width: 200, height: 200)
            .task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                print("👋🏻 Hello, console")
            }
    }
}

#if DEBUG
/// When previewing this file, a console showing the contents of stdout (i.e. `print()`) will be shown.
/// The preview console can be used by itself and has options to pick which display and where on screen it'll show up,
/// but it may also be combined with the pin to display modifier, in which case it'll be shown next to the pinned preview window.
struct LoggingDemo_Previews: PreviewProvider {
    static var previews: some View {
        LoggingDemo()
            .pin(to: .builtInDisplay)
            .previewConsole()
    }
}
#endif
