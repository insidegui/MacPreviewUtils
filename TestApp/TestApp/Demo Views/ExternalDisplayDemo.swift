import SwiftUI
import MacPreviewUtils

struct ExternalDisplayDemo: View {
    var body: some View {
        List {
            ForEach(0...100, id: \.self) { i in
                Text("List Item #\(i + 1)")
                    .font(.title2)
            }
        }
        .frame(width: 500, height: 400)
    }
}

struct ExternalDisplayDemo_Previews: PreviewProvider {
    static var previews: some View {
        ExternalDisplayDemo()
            .pin(to: .sidecarDisplay, alignment: .center, options: [])
    }
}
