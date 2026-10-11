import Foundation

/// Équivalent de util/TimeUtils.kt.
///
/// L'API renvoie des dates UTC sans fuseau (« 2026-10-10T00:30:00 »). Le parseur accepte aussi
/// les secondes fractionnaires et un suffixe « Z » / « ±HH:mm », comme `Instant.parse`.
public enum ApiTime {
    private static let utcCalendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0)!
        return calendar
    }()

    /// `parseApiUtc` : « yyyy-MM-dd'T'HH:mm:ss » interprété en UTC.
    public static func parseUtc(_ value: String) -> Date? {
        parse(value)
    }

    /// `parseApiInstant` : `nil` si vide, sinon instant ISO ou date UTC sans fuseau.
    public static func parseInstant(_ value: String?) -> Date? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        return parse(trimmed)
    }

    /// Format attendu par les paramètres `time_from` / `time_to` (équivalent de `Instant.toString()`).
    public static func format(_ date: Date) -> String {
        date.ISO8601Format()
    }

    private static func parse(_ value: String) -> Date? {
        let chars = Array(value.trimmingCharacters(in: .whitespacesAndNewlines).utf8)
        guard chars.count >= 19 else { return nil }

        func digits(_ start: Int, _ length: Int) -> Int? {
            guard start >= 0, start + length <= chars.count else { return nil }
            var result = 0
            for index in start..<(start + length) {
                let byte = chars[index]
                guard byte >= 48, byte <= 57 else { return nil }
                result = result * 10 + Int(byte - 48)
            }
            return result
        }

        func matches(_ index: Int, _ expected: Character) -> Bool {
            guard index < chars.count, let ascii = expected.asciiValue else { return false }
            return chars[index] == ascii
        }

        guard let year = digits(0, 4), matches(4, "-"),
              let month = digits(5, 2), matches(7, "-"),
              let day = digits(8, 2), matches(10, "T") || matches(10, " "),
              let hour = digits(11, 2), matches(13, ":"),
              let minute = digits(14, 2), matches(16, ":"),
              let second = digits(17, 2)
        else { return nil }

        var index = 19
        var fraction: Double = 0
        if matches(index, ".") {
            index += 1
            var scale = 0.1
            while index < chars.count, chars[index] >= 48, chars[index] <= 57 {
                fraction += Double(chars[index] - 48) * scale
                scale /= 10
                index += 1
            }
        }

        var offsetSeconds = 0
        if index < chars.count {
            if matches(index, "Z") || matches(index, "z") {
                index += 1
            } else if matches(index, "+") || matches(index, "-") {
                let sign = matches(index, "-") ? -1 : 1
                index += 1
                guard let offsetHours = digits(index, 2) else { return nil }
                index += 2
                if matches(index, ":") { index += 1 }
                var offsetMinutes = 0
                if let minutes = digits(index, 2) {
                    offsetMinutes = minutes
                    index += 2
                }
                offsetSeconds = sign * (offsetHours * 3_600 + offsetMinutes * 60)
            } else {
                return nil
            }
        }
        guard index == chars.count else { return nil }

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second
        guard let base = utcCalendar.date(from: components) else { return nil }
        return base.addingTimeInterval(fraction - Double(offsetSeconds))
    }
}
