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

#if DEBUG
/// This preview will be shown on the first external display that's connected to the Mac.
/// Try playing around with the different alignments and option flags that can be used to customize the preview.
struct ExternalDisplayDemo_Previews: PreviewProvider {
    static var previews: some View {
        ExternalDisplayDemo()
            .pin(to: .externalDisplay, alignment: .center, options: [])
    }
}
#endif
