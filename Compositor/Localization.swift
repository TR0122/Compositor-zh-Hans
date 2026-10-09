import Foundation

/// This local build deliberately uses Simplified Chinese, including AppKit controls and dynamic enum labels.
nonisolated func L(_ key: String) -> String {
    Bundle.main.localizedString(forKey: key, value: key, table: nil)
}

nonisolated extension String {
    var localized: String { L(self) }
}
