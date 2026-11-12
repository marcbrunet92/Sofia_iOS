import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/components/GraphInfoCards.kt : cartes sous le graphique.

/// Barre d'un jour disponible / jour à 0 MW (mêmes couleurs que la maquette).
enum AvailabilityColors {
    static let available = SofiaColors.fixed(0x1D9E75)
    static let unavailable = SofiaColors.fixed(0xD85A30)
}

struct InfoCardContainer<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sofiaCard()
    }
}

struct CardTitle: View {
    let titleKey: String
    var subtitleKey: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(titleKey))
                .font(SofiaType.titleMedium)
            if let subtitleKey {
                Text(LocalizedStringKey(subtitleKey))
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
    }
}

/// « 14 prochains jours » : puissance utilisable prévue (UOU2T14D), une barre par jour.
/// `capacityMw` sert d'échelle (1 400 MW pour Sofia) ; `nil` = la plus grande valeur (mode test).
struct NextDaysCard: View {
    let days: [UouDay]
    let capacityMw: Double?

    private static let barAreaHeight: CGFloat = 44

    var body: some View {
        let today = UouDay.today()
        let shown = Array(days.filter { $0.date >= today }.prefix(14))
        InfoCardContainer {
            CardTitle(titleKey: "next_days_title")
            if shown.isEmpty {
                Text("next_days_empty")
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            } else {
                let scale = Swift.max(capacityMw ?? shown.map(\.outputUsableMw).max() ?? 1, 1)
                HStack(alignment: .bottom, spacing: 2) {
                    ForEach(shown, id: \.date) { day in
                        let fraction = Swift.min(Swift.max(day.outputUsableMw / scale, 0), 1)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(fraction > 0 ? AvailabilityColors.available : AvailabilityColors.unavailable)
                            .frame(height: fraction > 0 ? Self.barAreaHeight * Swift.max(fraction, 0.07) : 2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: Self.barAreaHeight, alignment: .bottom)
                HStack {
                    Text(verbatim: Self.label(shown[0]))
                    Spacer()
                    if shown.count > 1, let last = shown.last {
                        Text(verbatim: Self.label(last))
                    }
                }
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("d MMM")
        return formatter
    }()

    private static func label(_ day: UouDay) -> String {
        let date = day.localDate.map { dayFormatter.string(from: $0) } ?? day.date
        return L10n.format("next_days_label_format", date, Int(day.outputUsableMw.rounded()))
    }
}

/// Contexte national (AGWS) : part de Sofia dans l'éolien GB, en une phrase.
struct GbContextCard: View {
    let context: GbContext?
    let pnPoints: [GraphPoint]

    var body: some View {
        InfoCardContainer {
            if context == nil {
                Text("gb_empty")
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            } else {
                Text(verbatim: L10n.format("gb_context_title", formatGbShare(gbSharePercent(context, pnPoints: pnPoints))))
                    .font(SofiaType.bodyMedium)
            }
        }
    }
}

/// Part de Sofia (PN) dans l'éolien GB (en mer + terrestre) au même créneau, en %. `nil` si incalculable.
func gbSharePercent(_ context: GbContext?, pnPoints: [GraphPoint]) -> Double? {
    guard let context, let offshore = context.windOffshoreMw else { return nil }
    let wind = offshore + (context.windOnshoreMw ?? 0)
    guard wind > 0, let sofiaMw = pnPoints.last(where: { $0.timeFrom == context.timeFrom })?.quantity else { return nil }
    return sofiaMw / wind * 100
}

func formatGbShare(_ share: Double?) -> String {
    share.map { String(format: "%.1f %%", locale: Locale.current, $0) } ?? "—"
}

/// Contexte national en détail (onglet Statistiques) : éolien en mer GB, part de Sofia dans
/// l'éolien en mer puis dans tout l'éolien, éolien terrestre et solaire.
struct GbContextDetailCard: View {
    let context: GbContext?
    let pnPoints: [GraphPoint]

    var body: some View {
        InfoCardContainer {
            CardTitle(titleKey: "gb_detail_title")
            if let context {
                let offshore = context.windOffshoreMw
                let sofiaMw = pnPoints.last { $0.timeFrom == context.timeFrom }?.quantity
                HStack(alignment: .top, spacing: 8) {
                    StatTile(
                        label: L10n.string("gb_offshore_label"),
                        value: offshore.map { L10n.format("gb_gw_format", Self.gigawatts($0)) } ?? "—",
                        caption: L10n.format("gb_source_format", Self.time(context.timeFrom))
                    )
                    StatTile(
                        label: L10n.string("gb_share_offshore_label"),
                        value: Self.share(sofiaMw, of: offshore),
                        caption: L10n.string("gb_share_caption")
                    )
                }
                Text(verbatim: L10n.format(
                    "gb_others_format",
                    context.windOnshoreMw.map(Self.gigawatts) ?? "—",
                    context.solarMw.map(Self.gigawatts) ?? "—"
                ))
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                Text(verbatim: L10n.format("gb_share_all_wind_format", formatGbShare(gbSharePercent(context, pnPoints: pnPoints))))
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            } else {
                Text("gb_empty")
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
    }

    /// « 12,3 % », ou « — » sans donnée.
    private static func share(_ sofiaMw: Double?, of totalMw: Double?) -> String {
        guard let sofiaMw, let totalMw, totalMw > 0 else { return "—" }
        return formatGbShare(sofiaMw / totalMw * 100)
    }

    private static func gigawatts(_ mw: Double) -> String {
        String(format: "%.1f", locale: Locale.current, mw / 1_000)
    }

    /// « HH:mm » aujourd'hui, « dd/MM HH:mm » sinon, dans le fuseau de l'appareil.
    private static func time(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = Calendar.current.isDateInToday(date) ? "HH:mm" : "dd/MM HH:mm"
        return formatter.string(from: date)
    }
}

/// Tuile « libellé, valeur, précision » (contexte GB, statistiques).
struct StatTile: View {
    let label: String
    let value: String
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(verbatim: label)
                .font(SofiaType.labelSmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
            Text(verbatim: value)
                .font(SofiaType.titleLarge)
                .fontWeight(.medium)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let caption {
                Text(verbatim: caption)
                    .font(SofiaType.labelSmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(SofiaColors.surfaceContainer, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
