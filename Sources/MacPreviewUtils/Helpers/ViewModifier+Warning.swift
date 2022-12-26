import SwiftUI
import OSLog

extension ViewModifier {
    @inline(__always)
    static func warnImproperUse() {
        #if DEBUG
        os_log(.fault,
               dso: rw.dso,
               log: rw.log,
               """
                %{public}@ should only be used in Xcode previews,
                do not apply it to views outside of a preview provider.
               """,
               String(describing: self)
        )
        #endif
    }
}
