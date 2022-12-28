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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    fputs("This message was logged to stderr\n", stderr)

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
