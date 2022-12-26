import SwiftUI
@testable import MacPreviewUtils

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

struct LoggingDemo_Previews: PreviewProvider {
    static var previews: some View {
        LoggingDemo()
            .pin(to: .sidecarDisplay, options: [])
            .previewConsole(options: [])
    }
}
