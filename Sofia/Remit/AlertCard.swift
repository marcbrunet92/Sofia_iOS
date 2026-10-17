import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/remit/AlertCard.kt : une alerte (une unité, ou le même événement sur tout le
/// parc), et les libellés partagés avec son détail.
struct AlertCard: View {
    let group: RemitGroup
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(alignment: .top, spacing: 12) {
                Circle()
                    .fill(AlertFormat.typeColor(group))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: group.title)
                        .font(SofiaType.titleMedium)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    Text(verbatim: AlertFormat.scopeText(group) + " · "
                        + AlertFormat.availabilityText(available: group.availableMw, normal: group.normalMw))
                        .font(SofiaType.bodyMedium)
                    Text(verbatim: [AlertFormat.typeLabel(group), AlertFormat.whenText(group)]
                        .compactMap { $0 }
                        .joined(separator: " · "))
                        .font(SofiaType.bodySmall)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if group.phase == .upcoming, let start = group.start {
                    StartsInBadge(start: start)
                }
            }
            .foregroundStyle(SofiaColors.onSurface)
            .multilineTextAlignment(.leading)
            .padding(16)
            .sofiaCard()
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(CardButtonStyle())
    }
}

/// « dans 3 jours » / « dans 5 h », en pastille jaune.
private struct StartsInBadge: View {
    let start: Date

    var body: some View {
        Text(verbatim: Self.text(start))
            .font(SofiaType.labelMedium)
            .fontWeight(.bold)
            .foregroundStyle(SofiaColors.yellowText)
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(SofiaColors.yellow, in: Capsule())
    }

    private static func text(_ start: Date) -> String {
        switch startsIn(start, now: Date()) {
        case .hours(let hours):
            return String(localized: "remit_in_hours \(hours)")
        case .days(let days):
            return String(localized: "remit_in_days \(days)")
        }
    }
}

enum AlertFormat {
    private static let plannedAmber = SofiaColors.fixed(0xF2A900)

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM HH:mm")
        return formatter
    }()

    /// « mer. 22 oct. 18:00 », dans le fuseau de l'appareil.
    static func alertDate(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// En cours : la fin. À venir : le début.
    static func whenText(_ group: RemitGroup) -> String {
        if group.phase == .upcoming, let start = group.start {
            return L10n.format("remit_starts_format", alertDate(start))
        }
        return group.end.map { L10n.format("remit_until_format", alertDate($0)) } ?? L10n.string("remit_no_end")
    }

    /// « Toutes les unités » ou « Unité 11 ».
    static func scopeText(_ group: RemitGroup) -> String {
        group.isFarmWide
            ? L10n.string("remit_all_units")
            : L10n.format("remit_unit_format", unitNumber(group.first.bmuId))
    }

    /// « Planifié » / « Imprévu » (texte d'origine pour un autre type), `nil` si absent.
    static func typeLabel(_ group: RemitGroup) -> String? {
        switch group.first.unavailabilityType {
        case "Planned": return L10n.string("remit_type_planned")
        case "Unplanned": return L10n.string("remit_type_unplanned")
        case let other: return other.isBlank ? nil : other
        }
    }

    static func typeColor(_ group: RemitGroup) -> Color {
        switch group.first.unavailabilityType {
        case "Planned": return plannedAmber
        case "Unplanned": return SofiaColors.error
        default: return SofiaColors.outline
        }
    }

    static func availabilityText(available: Double?, normal: Double?) -> String {
        guard let available else { return L10n.string("remit_available_unknown") }
        guard let normal else { return L10n.format("remit_available_format", Int(available.rounded())) }
        return L10n.format("remit_available_of_format", Int(available.rounded()), Int(normal.rounded()))
    }
}

/// Retour visuel au toucher d'une carte cliquable (équivalent de l'effet « ripple »).
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SofiaColors.onSurface.opacity(configuration.isPressed ? 0.1 : 0))
            }
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
