import SwiftUI

/// Demonstrates how SwiftUI's `Material` is rendered with the correct blur/translucency
/// effects when MacPreviewUtils is included in the app.
/// If the app does not link against MacPreviewUtils, then the materials are rendered in an inactive state.
struct MaterialTranslucencyDemo: View {
    var body: some View {
        ZStack {
            Image("PreviewWallpaper")
                .resizable()
                .aspectRatio(contentMode: .fill)

            VStack {
                materialPreview(.ultraThin, named: "Ultra Thin")
                materialPreview(.thin, named: "Thin")
                materialPreview(.regular, named: "Regular")
                materialPreview(.thick, named: "Thick")
                materialPreview(.ultraThick, named: "Ultra Thick")
                materialPreview(.bar, named: "Bar")
            }
        }
    }

    @ViewBuilder
    private func materialPreview(_ material: Material, named name: String) -> some View {
        Text(name)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(material, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal)
    }
}

#if DEBUG
struct MaterialTranslucencyDemo_Previews: PreviewProvider {
    static var previews: some View {
        MaterialTranslucencyDemo()
            .frame(maxWidth: 400)
    }
}
#endif
