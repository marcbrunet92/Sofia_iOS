import Foundation
import SofiaCore

/// Mirrors Android's `timestampFormatter` (yyyy-MM-dd HH:mm 'UTC', UTC zone).
let timestampFormatter: DateFormatter = {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd HH:mm 'UTC'"
    fmt.timeZone = TimeZone(identifier: "UTC")
    fmt.locale = Locale(identifier: "en_US_POSIX")
    return fmt
}()

extension Date {
    /// Formats this date using `timestampFormatter`, e.g. "2026-06-13 14:30 UTC".
    func asTimestamp() -> String {
        timestampFormatter.string(from: self)
    }
}

extension Optional where Wrapped == Date {
    /// Returns the formatted timestamp, or "—" if nil.
    func asTimestampOrDash() -> String {
        self?.asTimestamp() ?? "—"
    }
}

/// Mirrors Android's `shortAxisFormatter(tw: TimeWindow)`: returns a DateFormatter
/// using UTC and a pattern depending on the selected time window.
func shortAxisFormatter(for window: TimeWindow) -> DateFormatter {
    let fmt = DateFormatter()
    fmt.dateFormat = window.axisDateFormat
    fmt.timeZone = TimeZone(identifier: "UTC")
    fmt.locale = Locale(identifier: "en_US_POSIX")
    return fmt
}