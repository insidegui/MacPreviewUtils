#if DEBUG
import SwiftUI

struct PreviewConsoleView: View {
    static var minWidth: CGFloat { 580 }
    static var minHeight: CGFloat { 250 }

    @State private var messages = [ProcessPipe.Message]()

    @State private var autoscroll = true

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(messages) { message in
                    Text(message.contents)
                        .tag(message.id)
                        .id(message.id)
                        .font(.system(.body, design: .monospaced))
                        .contextMenu {
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(message.contents, forType: .string)
                            }
                        }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0, content: {
                HStack {
                    Button {
                        autoscroll.toggle()
                    } label: {
                        Image(systemName: "arrow.up.left")
                            .symbolVariant(.circle)
                    }
                    .help("Scroll automatically")
                    .font(.headline)
                    .foregroundColor(autoscroll ? .accentColor : .primary)

                    Spacer()
                }
                .buttonStyle(.borderless)
                .padding(12)
                .background(Material.bar)
                .overlay(alignment: .top) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(.quaternary)
                }
            })
            .frame(minWidth: Self.minWidth, maxWidth: .infinity, minHeight: Self.minHeight, maxHeight: .infinity)
            .task {
                for await message in ProcessPipe.current.newMessage.values {
                    messages.append(message)

                    if autoscroll {
                        try? await Task.sleep(nanoseconds: 1_000_000)
                        proxy.scrollTo(message.id)
                    }
                }
            }
        }
    }
}
#endif
