import Foundation

/// Équivalent de ui/remit/RemitGrouping.kt.

public enum RemitPhase: Sendable {
    case current
    case upcoming
}

/// Un avis seul, ou le même événement déclaré sur toutes les unités du parc
/// (même type, même cause, même fin, et même début pour un avis à venir).
public struct RemitGroup: Identifiable, Sendable {
    public let id: String
    public let phase: RemitPhase
    public let notices: [RemitNotice]
    public let isFarmWide: Bool

    public var first: RemitNotice { notices[0] }

    public var title: String { first.cause.ifBlank(first.messageHeading.ifBlank(first.eventType)) }

    public var start: Date? { notices.compactMap(\.eventStartTime).min() }

    public var end: Date? {
        notices.contains { $0.eventEndTime == nil } ? nil : notices.compactMap(\.eventEndTime).max()
    }

    /// Somme des capacités disponibles ; `nil` si une unité n'en donne pas.
    public var availableMw: Double? { sumOrNil(notices.map(\.effectiveAvailableMw)) }
    public var normalMw: Double? { sumOrNil(notices.map(\.normalCapacityMw)) }
}

public struct RemitSections: Sendable {
    public let current: [RemitGroup]
    public let upcoming: [RemitGroup]

    public init(current: [RemitGroup] = [], upcoming: [RemitGroup] = []) {
        self.current = current
        self.upcoming = upcoming
    }

    public var noticeCount: Int { (current + upcoming).reduce(0) { $0 + $1.notices.count } }
}

extension RemitNotice {
    /// Capacité disponible, ou normale − indisponible si l'avis ne la donne pas.
    public var effectiveAvailableMw: Double? {
        if let availableCapacityMw { return availableCapacityMw }
        if let normal = normalCapacityMw, let unavailable = unavailableCapacityMw { return normal - unavailable }
        return nil
    }
}

/// « T_SOFOW-11 » → « 11 ».
public func unitNumber(_ bmuId: String) -> String {
    let afterDash = bmuId.split(separator: "-", omittingEmptySubsequences: false).last.map(String.init) ?? bmuId
    return afterDash.removingPrefix("T_")
}

extension RemitGroup {
    /// Profil de capacité du groupe : somme des profils de chaque unité, palier par palier.
    /// Vide si une unité n'a pas de profil.
    public func outageProfile() -> [OutageStep] {
        let profiles = notices.map { parseOutageProfile($0.outageProfile) }
        if profiles.isEmpty || profiles.contains(where: \.isEmpty) { return [] }
        if profiles.count == 1 { return profiles[0] }
        let bounds = Set(profiles.flatMap { steps in steps.flatMap { [$0.start, $0.end] } }).sorted()
        return zip(bounds, bounds.dropFirst()).compactMap { from, to in
            let capacities = profiles.map { steps in
                steps.first { $0.start <= from && $0.end > from }?.capacityMw
            }
            return sumOrNil(capacities).map { OutageStep(start: from, end: to, capacityMw: $0) }
        }
    }
}

private func sumOrNil(_ values: [Double?]) -> Double? {
    values.contains { $0 == nil } ? nil : values.reduce(0) { $0 + ($1 ?? 0) }
}

private func truncatedToHour(_ date: Date?) -> String {
    guard let date else { return "-" }
    return String(Int(date.timeIntervalSince1970 / 3_600))
}

/// Avis en vigueur d'abord, puis avis à venir (du plus proche au plus lointain). Les avis terminés
/// (fin passée) sont écartés. Un événement présent sur toutes les `units` devient un seul groupe ;
/// une perturbation partielle du parc garde un avis par carte.
public func groupRemits(_ notices: [RemitNotice], units: [String], now: Date) -> RemitSections {
    let inScope = notices.filter { notice in
        guard let end = notice.eventEndTime else { return true }
        return end >= now
    }

    var order: [String] = []
    var buckets: [String: (phase: RemitPhase, notices: [RemitNotice])] = [:]
    for notice in inScope {
        let phase: RemitPhase = (notice.eventStartTime.map { $0 > now } ?? false) ? .upcoming : .current
        let key = [
            phase == .upcoming ? "upcoming" : "current",
            notice.unavailabilityType,
            notice.cause,
            truncatedToHour(notice.eventEndTime),
            phase == .upcoming ? truncatedToHour(notice.eventStartTime) : "-",
        ].joined(separator: "|")
        if buckets[key] == nil {
            order.append(key)
            buckets[key] = (phase, [])
        }
        buckets[key]?.notices.append(notice)
    }

    var groups: [RemitGroup] = []
    for key in order {
        guard let bucket = buckets[key] else { continue }
        let sorted = bucket.notices.sorted { $0.bmuId < $1.bmuId }
        let farmWide = units.count > 1 && Set(units).isSubset(of: Set(sorted.map(\.bmuId)))
        if farmWide {
            groups.append(RemitGroup(id: key, phase: bucket.phase, notices: sorted, isFarmWide: true))
        } else {
            groups += sorted.map { RemitGroup(id: String($0.id), phase: bucket.phase, notices: [$0], isFarmWide: false) }
        }
    }

    let current = groups.filter { $0.phase == .current }.sorted { lhs, rhs in
        if lhs.isFarmWide != rhs.isFarmWide { return lhs.isFarmWide }
        if lhs.first.bmuId != rhs.first.bmuId { return lhs.first.bmuId < rhs.first.bmuId }
        return (lhs.end ?? .distantFuture) < (rhs.end ?? .distantFuture)
    }
    let upcoming = groups.filter { $0.phase == .upcoming }.sorted { lhs, rhs in
        let left = lhs.start ?? .distantFuture
        let right = rhs.start ?? .distantFuture
        if left != right { return left < right }
        if lhs.isFarmWide != rhs.isFarmWide { return lhs.isFarmWide }
        return lhs.first.bmuId < rhs.first.bmuId
    }
    return RemitSections(current: current, upcoming: upcoming)
}

/// Délai avant le début d'un avis : en heures sous 24 h, sinon en jours calendaires.
public enum StartsIn: Equatable, Sendable {
    case hours(Int)
    case days(Int)
}

public func startsIn(_ start: Date, now: Date, calendar: Calendar = .current) -> StartsIn {
    let seconds = start.timeIntervalSince(now)
    if seconds < 86_400 {
        return .hours(max(Int((seconds / 3_600).rounded(.up)), 1))
    }
    let days = calendar.dateComponents(
        [.day],
        from: calendar.startOfDay(for: now),
        to: calendar.startOfDay(for: start)
    ).day ?? 1
    return .days(max(days, 1))
}

// MARK: - Profil d'un avis

/// Un palier du profil d'un avis REMIT : capacité disponible (MW) entre `start` et `end`.
public struct OutageStep: Hashable, Sendable {
    public let start: Date
    public let end: Date
    public let capacityMw: Double
}

private struct OutageStepDto: Decodable {
    let startTime: String?
    let endTime: String?
    let capacity: Double?
}

/// `outage_profile` (JSON `[{startTime, endTime, capacity}]`) ; liste vide si absent ou illisible.
public func parseOutageProfile(_ json: String) -> [OutageStep] {
    guard !json.isBlank, let data = json.data(using: .utf8),
          let items = try? JSONDecoder().decode([OutageStepDto].self, from: data)
    else { return [] }
    let steps: [OutageStep] = items.compactMap { item in
        guard let start = ApiTime.parseInstant(item.startTime),
              let end = ApiTime.parseInstant(item.endTime),
              let capacity = item.capacity
        else { return nil }
        return OutageStep(start: start, end: end, capacityMw: capacity)
    }
    // Tri stable par début, comme `sortedBy` en Kotlin
    return steps.enumerated()
        .sorted { ($0.element.start, $0.offset) < ($1.element.start, $1.offset) }
        .map(\.element)
}
