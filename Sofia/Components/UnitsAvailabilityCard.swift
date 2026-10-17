import Foundation
import SwiftUI
import SofiaCore

/// UnitsAvailabilityCard.kt : puissance disponible maintenant, total du parc puis une jauge par unité.
struct UnitsAvailabilityCard: View {
    let data: UnitsData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("remit_available_now")
                    .font(SofiaType.labelLarge)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(verbatim: L10n.format("mw_value_format", Int(data.totalAvailable.rounded())))
                        .font(SofiaType.headlineMedium)
                        .fontWeight(.bold)
                    if data.totalNormal > 0 {
                        Text(verbatim: L10n.format("remit_out_of_format", Int(data.totalNormal.rounded())))
                            .font(SofiaType.bodyLarge)
                            .foregroundStyle(SofiaColors.onSurfaceVariant)
                    }
                }
            }
            HStack(alignment: .top, spacing: 12) {
                ForEach(data.units, id: \.bmuId) { unit in
                    UnitGauge(unit: unit)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .sofiaCard()
    }
}

private struct UnitGauge: View {
    let unit: UnitStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: L10n.format("remit_unit_format", unit.shortLabel))
                .font(SofiaType.labelMedium)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                .lineLimit(1)
            LinearProgressBar(fraction: unit.fraction, color: unit.level.color)
            Text(verbatim: unit.availableMw.map { L10n.format("mw_value_format", Int($0.rounded())) } ?? "—")
                .font(SofiaType.labelLarge)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

/// `LinearProgressIndicator` déterminé.
struct LinearProgressBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(SofiaColors.surfaceVariant)
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * CGFloat(min(max(fraction, 0), 1)))
            }
        }
        .frame(height: 4)
    }
}

extension AvailabilityLevel {
    /// `UnitStatus.statusColor()`
    var color: Color {
        switch self {
        case .good: return SofiaColors.good
        case .warn: return SofiaColors.warn
        case .bad: return SofiaColors.bad
        }
    }
}
