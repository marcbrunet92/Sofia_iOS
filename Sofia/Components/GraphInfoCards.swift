import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/components/GraphInfoCards.kt : cartes sous le graphique.

/// Barre d'un jour disponible / jour à 0 MW (mêmes couleurs que la maquette).
enum AvailabilityColors {
    static let available = SofiaColors.fixed(0x1D9E75)
    static let unavailable = SofiaColors.fixed(0xD85A30)
}

private struct InfoCardContainer<Content: View>: View {
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

private struct CardTitle: View {
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
            CardTitle(titleKey: "next_days_title", subtitleKey: "next_days_subtitle")
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

/// Contexte national (AGWS) : part de Sofia dans l'éolien GB (PN ÷ éolien en mer + terrestre), en pourcentage.
struct GbContextCard: View {
    let context: GbContext?
    let pnPoints: [GraphPoint]

    var body: some View {
        InfoCardContainer {
            CardTitle(titleKey: "gb_context_title")
            if let context {
                let wind = context.windOffshoreMw.map { $0 + (context.windOnshoreMw ?? 0) }
                let sofiaMw = pnPoints.last { $0.timeFrom == context.timeFrom }?.quantity
                let share: Double? = {
                    guard let wind, wind > 0, let sofiaMw else { return nil }
                    return sofiaMw / wind * 100
                }()
                Text(verbatim: share.map { String(format: "%.1f %%", locale: Locale.current, $0) } ?? "—")
                    .font(SofiaType.headlineMedium)
                Text("gb_share_label")
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            } else {
                Text("gb_empty")
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
    }
}
