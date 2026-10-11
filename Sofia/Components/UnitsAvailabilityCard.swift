import Foundation
import SwiftUI
import SofiaCore

/// UnitsAvailabilityCard.kt : même contenu que le widget « disponibilité par unité » (format large),
/// disponibilité REMIT par unité + total.
struct UnitsAvailabilityCard: View {
    let data: UnitsData

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text("widget_units_header")
                    .font(SofiaType.labelMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(totalText)
                    .font(SofiaType.titleSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(SofiaColors.onSurface)
            }
            HStack(spacing: 8) {
                ForEach(data.units, id: \.bmuId) { unit in
                    UnitTile(unit: unit)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .sofiaCard()
    }

    private var totalText: String {
        let available = Int(data.totalAvailable.rounded())
        if data.totalNormal > 0 {
            return "\(available) / \(Int(data.totalNormal.rounded())) MW"
        }
        return "\(available) MW"
    }
}

private struct UnitTile: View {
    let unit: UnitStatus

    var body: some View {
        let color = unit.level.color
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                Text(unit.label)
                    .font(SofiaType.labelSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Text(unit.availableMw.map { String(Int($0.rounded())) } ?? "—")
                .font(SofiaType.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("unit_mw")
                .font(SofiaType.labelSmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
            Spacer().frame(height: 6)
            LinearProgressBar(fraction: unit.fraction, color: color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(SofiaColors.surfaceContainer, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
