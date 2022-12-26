#if DEBUG
import SwiftUI

struct PreviewConsoleView: View {
    static var minWidth: CGFloat { 580 }
    static var minHeight: CGFloat { 250 }

    @State private var messages = [ProcessPipe.Message]()

    var body: some View {
        List {
            ForEach(messages) { message in
                Text(message.contents)
                    .font(.system(.body, design: .monospaced))
                    .contextMenu {
                        Button("Copy") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(message.contents, forType: .string)
                        }
                    }
            }
        }
        .frame(minWidth: Self.minWidth, maxWidth: .infinity, minHeight: Self.minHeight, maxHeight: .infinity)
        .task {
            for await message in ProcessPipe.current.newMessage.values {
                messages.append(message)
            }
        }
    }
}
#endif
