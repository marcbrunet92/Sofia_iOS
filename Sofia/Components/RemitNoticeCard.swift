import Foundation
import SwiftUI
import SofiaCore

/// RemitNoticeCard.kt : cartes de l'écran Alertes.

private enum RemitCardFormat {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM HH:mm")
        return formatter
    }()

    static func date(_ date: Date) -> String {
        dateFormatter.string(from: date)
    }

    /// « T_SOFOW-11 » → « SOFOW-11 »
    static func unitLabel(_ bmuId: String) -> String {
        bmuId.hasPrefix("T_") ? String(bmuId.dropFirst(2)) : bmuId
    }

    static func title(_ notice: RemitNotice) -> String {
        notice.cause.ifBlank(notice.messageHeading.ifBlank(notice.eventType))
    }

    static func availability(available: Double?, normal: Double?) -> String {
        guard let available else { return L10n.string("remit_available_unknown") }
        guard let normal else { return L10n.format("remit_available_format", Int(available.rounded())) }
        return L10n.format("remit_available_of_format", Int(available.rounded()), Int(normal.rounded()))
    }
}

/// Événement déclaré sur tout le parc : une carte qui se déplie en une carte cliquable par unité.
struct RemitGroupCard: View {
    let group: RemitGroup
    let expanded: Bool
    let onToggle: () -> Void
    let onOpenNotice: (Int) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: onToggle) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TypeChip(unavailabilityType: group.first.unavailabilityType)
                        Spacer()
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 15, weight: .semibold))
                            .accessibilityLabel(Text(LocalizedStringKey(expanded ? "remit_hide_units" : "remit_show_units")))
                    }
                    Text(verbatim: RemitCardFormat.title(group.first))
                        .font(SofiaType.titleMedium)
                        .fontWeight(.semibold)
                    Text(verbatim: L10n.format("remit_all_units_format", group.notices.count) + " · "
                        + RemitCardFormat.availability(available: group.availableMw, normal: group.normalMw))
                        .font(SofiaType.bodyMedium)
                    DatesBlock(phase: group.phase, start: group.start, end: group.end)
                }
                .foregroundStyle(SofiaColors.onSurface)
                .multilineTextAlignment(.leading)
                .padding(16)
                .sofiaCard()
                .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(CardButtonStyle())

            if expanded {
                VStack(spacing: 6) {
                    ForEach(group.notices) { notice in
                        UnitNoticeCard(notice: notice) { onOpenNotice(notice.id) }
                    }
                }
                .padding(.leading, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: expanded)
    }
}

/// Avis d'une seule unité (perturbation partielle du parc, ou mode test).
struct RemitNoticeCard: View {
    let notice: RemitNotice
    let phase: RemitPhase
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    TypeChip(unavailabilityType: notice.unavailabilityType)
                    Text(verbatim: L10n.format("remit_unit_format", RemitCardFormat.unitLabel(notice.bmuId)))
                        .font(SofiaType.labelLarge)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .semibold))
                }
                Text(verbatim: RemitCardFormat.title(notice))
                    .font(SofiaType.titleMedium)
                    .fontWeight(.semibold)
                Text(verbatim: RemitCardFormat.availability(
                    available: notice.effectiveAvailableMw,
                    normal: notice.normalCapacityMw
                ))
                .font(SofiaType.bodyMedium)
                DatesBlock(phase: phase, start: notice.eventStartTime, end: notice.eventEndTime)
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

/// Carte compacte d'une unité dans un groupe déplié.
private struct UnitNoticeCard: View {
    let notice: RemitNotice
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: L10n.format("remit_unit_format", RemitCardFormat.unitLabel(notice.bmuId)))
                        .font(SofiaType.titleSmall)
                        .fontWeight(.semibold)
                    Text(verbatim: RemitCardFormat.availability(
                        available: notice.effectiveAvailableMw,
                        normal: notice.normalCapacityMw
                    ))
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(SofiaColors.onSurface)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .sofiaCard(SofiaColors.surfaceContainer)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(CardButtonStyle())
    }
}

/// « ──── À venir ──── » entre les avis en vigueur et les avis à venir.
struct UpcomingDivider: View {
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(SofiaColors.primary).frame(height: 1)
            Text("remit_section_upcoming")
                .font(SofiaType.labelLarge)
                .fontWeight(.bold)
                .foregroundStyle(SofiaColors.primary)
                .fixedSize()
            Rectangle().fill(SofiaColors.primary).frame(height: 1)
        }
        .padding(.vertical, 8)
    }
}

/// En vigueur : la fin. À venir : le début mis en avant, « dans X jours », puis la fin.
private struct DatesBlock: View {
    let phase: RemitPhase
    let start: Date?
    let end: Date?

    var body: some View {
        if phase == .upcoming, let start {
            HStack(spacing: 8) {
                Text(verbatim: L10n.format("remit_starts_format", RemitCardFormat.date(start)))
                    .font(SofiaType.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(SofiaColors.primary)
                Text(verbatim: Self.delay(start))
                    .font(SofiaType.labelMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(SofiaColors.yellowText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(SofiaColors.yellow, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        Text(verbatim: end.map { L10n.format("remit_until_format", RemitCardFormat.date($0)) }
            ?? L10n.string("remit_no_end"))
            .font(SofiaType.bodySmall)
            .foregroundStyle(SofiaColors.onSurfaceVariant)
    }

    private static func delay(_ start: Date) -> String {
        switch startsIn(start, now: Date()) {
        case .hours(let hours):
            return String(localized: "remit_in_hours \(hours)")
        case .days(let days):
            return String(localized: "remit_in_days \(days)")
        }
    }
}

/// « Planifié » / « Imprévu » (texte Elexon tel quel pour un autre type).
private struct TypeChip: View {
    let unavailabilityType: String

    var body: some View {
        let style: (label: String, background: Color, foreground: Color) = {
            switch unavailabilityType {
            case "Planned":
                return (L10n.string("remit_type_planned"), SofiaColors.yellow, SofiaColors.yellowText)
            case "Unplanned":
                return (L10n.string("remit_type_unplanned"), SofiaColors.materialErrorContainer, SofiaColors.onErrorContainer)
            default:
                return (unavailabilityType, SofiaColors.surfaceContainer, SofiaColors.onSurfaceVariant)
            }
        }()
        if !style.label.isBlank {
            Text(verbatim: style.label)
                .font(SofiaType.labelSmall)
                .fontWeight(.bold)
                .foregroundStyle(style.foreground)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(style.background, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
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
