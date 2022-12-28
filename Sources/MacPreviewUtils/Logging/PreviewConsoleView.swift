#if DEBUG
import SwiftUI

struct PreviewConsoleView: View {
    static var minWidth: CGFloat { 580 }
    static var minHeight: CGFloat { 250 }

    @State private var messages = [ProcessPipe.Message]()

    @State private var autoscroll = true

    @State private var searchTerm = ""

    private var filteredMessages: [ProcessPipe.Message] {
        messages.filter { searchTerm.isEmpty || $0.contents.localizedCaseInsensitiveContains(searchTerm) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(filteredMessages) { message in
                    ConsoleMessageView(message: message)
                }
            }
            .textSelection(.enabled)
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

                    TextField("Search", text: $searchTerm)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .overlay(alignment: .trailing) {
                            if !searchTerm.isEmpty {
                                Button {
                                    searchTerm = ""
                                } label: {
                                    Image(systemName: "xmark")
                                        .symbolVariant(.circle.fill)
                                        .padding(.trailing, 6)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .onCommand(#selector(NSControl.cancelOperation)) {
                            searchTerm = ""
                        }
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

struct ConsoleMessageView: View {
    var message: ProcessPipe.Message

    private var contents: AttributedString {
        var attributes = AttributeContainer()
        attributes.font = Font.system(.body, design: .monospaced)
        attributes.foregroundColor = Color.primary
        return AttributedString(message.contents, attributes: attributes)
    }

    var body: some View {
        Text(message.contents)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.primary)
            .tag(message.id)
            .id(message.id)
            .contextMenu {
                Button("Copy") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(message.contents, forType: .string)
                }
            }
    }
}

#endif
