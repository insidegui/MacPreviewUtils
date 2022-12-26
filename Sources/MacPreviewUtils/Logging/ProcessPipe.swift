#if DEBUG
import Foundation
import Combine

final class ProcessPipe {

    enum MessageSource: Int {
        case stdout
    }

    struct Message: Identifiable, Hashable {
        var id = UUID()
        var date = Date()
        var source: MessageSource
        var contents: String
    }

    static let current = ProcessPipe()

    private(set) var messages = [Message]()

    let newMessage = PassthroughSubject<Message, Never>()

    private var activated = false

    func activate() {
        guard !activated else { return }
        activated = true

        Task {
            await read(stdoutPipe, as: .stdout)
        }
    }

    private lazy var stdoutPipe: Pipe = {
        let pipe = Pipe()
        setvbuf(stdout, nil, _IOLBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        return pipe
    }()

    private func read(_ pipe: Pipe, as source: MessageSource) async {
        do {
            for try await line in pipe.fileHandleForReading.bytes.lines {
                let message = Message(source: source, contents: line)

                await MainActor.run {
                    newMessage.send(message)
                    messages.append(message)
                }

                await Task.yield()
            }
        } catch {
            if !ProcessInfo.isSwiftUIPreview {
                assertionFailure("\(source) streaming failed: \(error)")
            }
        }
    }

}
#endif
