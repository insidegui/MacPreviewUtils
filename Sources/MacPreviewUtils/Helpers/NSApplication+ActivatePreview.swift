#if DEBUG
import SwiftUI

extension NSApplication {

    func activateForPreview(then block: (() -> Void)? = nil) {
        setActivationPolicy(.accessory)
        unhide(nil)

        DispatchQueue.main.async {
            block?()

            DispatchQueue.main.async {
                ProcessInfo.activateXcode()
            }
        }
    }

}
#endif
