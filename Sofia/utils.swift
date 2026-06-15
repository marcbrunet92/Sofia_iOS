import Foundation
import SofiaCore

func shortAxisFormatter(for window: TimeWindow) -> DateFormatter {
    let fmt = DateFormatter()
    fmt.dateFormat = window.axisDateFormat
    fmt.timeZone = TimeZone(identifier: "UTC")
    fmt.locale = Locale(identifier: "en_US_POSIX")
    return fmt
}
