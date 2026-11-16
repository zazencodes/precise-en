// Prints the window number of the open precise//en window, for `screencapture -l`.
import CoreGraphics

let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as! [[String: Any]]
let main = windows.first {
    $0[kCGWindowOwnerName as String] as? String == "precise//en" && $0[kCGWindowLayer as String] as? Int == 0
}
guard let main else { fatalError("no precise//en window is open") }
print(main[kCGWindowNumber as String]!)
