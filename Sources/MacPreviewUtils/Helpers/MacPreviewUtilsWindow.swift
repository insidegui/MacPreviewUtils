#if DEBUG
import SwiftUI

protocol MacPreviewUtilsWindow: AnyObject {
    var isMacPreviewUtilsWindow: Bool { get }
}

extension MacPreviewUtilsWindow {
    var isMacPreviewUtilsWindow: Bool { true }
}

extension NSWindow {
    func constrainPreview(to frameRect: NSRect, on screen: NSScreen?) -> NSRect {
        guard let screen else {
            return frame
        }

        var f = frameRect

        if f.origin.x > screen.frame.maxX - f.width {
            f.origin.x = screen.frame.maxX - f.width
        } else if f.origin.x < screen.frame.minX {
            f.origin.x = screen.frame.minX
        }

        if f.origin.y > screen.frame.maxY - f.height {
            f.origin.y = screen.frame.maxY - f.height
        } else if f.origin.y < screen.frame.minY {
            f.origin.y = screen.frame.minY
        }

        return f
    }
}
#endif
