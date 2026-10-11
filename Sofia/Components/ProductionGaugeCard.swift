import Foundation
import SwiftUI

/// ProductionGaugeCard.kt : jauge 270° (dégradé cyan → bleu → indigo) et production courante.
struct ProductionGaugeCard: View {
    let currentMw: Double
    let maxCapacityMw: Double
    let dataTimestamp: Date?

    var body: some View {
        let safeMaxCapacity = max(maxCapacityMw, 1)
        let progress = min(max(currentMw / safeMaxCapacity, 0), 1)
        ZStack {
            GaugeArc(progress: progress)
                .frame(width: 240, height: 240)
            GaugeLabels(
                mw: currentMw,
                progress: progress,
                maxCapacityMw: safeMaxCapacity,
                dataTimestamp: dataTimestamp
            )
        }
        .animation(.spring(response: 0.5, dampingFraction: 1), value: progress)
        .animation(.spring(response: 0.5, dampingFraction: 1), value: currentMw)
        .frame(maxWidth: .infinity)
        .padding(20)
        .sofiaCard()
    }
}

private struct GaugeArc: View {
    let progress: Double

    private static let stroke: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .rotation(.degrees(135))
                .stroke(
                    SofiaColors.outline.opacity(0.2),
                    style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round)
                )
            Circle()
                .trim(from: 0, to: 0.75 * progress)
                .rotation(.degrees(135))
                .stroke(
                    AngularGradient(
                        colors: [SofiaColors.cyan, SofiaColors.blue, SofiaColors.indigo, SofiaColors.cyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: Self.stroke, lineCap: .round)
                )
        }
        .padding(Self.stroke / 2)
    }
}

/// Valeurs animées comme `animateFloatAsState` (le nombre défile jusqu'à la nouvelle valeur).
private struct GaugeLabels: View, Animatable {
    var mw: Double
    var progress: Double
    let maxCapacityMw: Double
    let dataTimestamp: Date?

    var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(mw, progress) }
        set {
            mw = newValue.first
            progress = newValue.second
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.format("mw_value_format", Int(mw.rounded())))
                .font(SofiaType.headlineSmall)
                .fontWeight(.bold)
                .foregroundStyle(SofiaColors.onSurface)
                .monospacedDigit()
            Spacer().frame(height: 8)
            Text(L10n.format("gauge_capacity_format", Int((progress * 100).rounded()), Int(maxCapacityMw.rounded())))
                .font(SofiaType.bodyMedium)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
            Spacer().frame(height: 4)
            Text(L10n.format("gauge_data_timestamp_format", SofiaDateFormat.timestamp(dataTimestamp)))
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
        }
        .multilineTextAlignment(.center)
    }
}
