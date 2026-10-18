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
        // L'arc (270°) est ouvert en bas : ~32 pt vides sous le dessin dans le carré de 240 pt.
        // On décale de la moitié pour que la jauge paraisse centrée dans la carte.
        .offset(y: 16)
        .animation(.spring(response: 0.5, dampingFraction: 1), value: progress)
        .animation(.spring(response: 0.5, dampingFraction: 1), value: currentMw)
        .frame(maxWidth: .infinity)
        .padding(20)
        .sofiaCard()
    }
}

/// Variante compacte (écran Graphique sans défilement) : jauge à gauche, part de Sofia dans
/// l'éolien GB à droite (anciennement GbContextCard).
struct ProductionGaugeCompactCard: View {
    let currentMw: Double
    let maxCapacityMw: Double
    let dataTimestamp: Date?
    let gbSharePercent: Double?

    var body: some View {
        let progress = min(max(currentMw / max(maxCapacityMw, 1), 0), 1)
        // Deux moitiés de même largeur : jauge (production) | part de l'éolien GB.
        // fixedSize vertical donne au séparateur la hauteur du contenu.
        HStack(spacing: 16) {
            ZStack {
                GaugeArc(progress: progress, stroke: 12)
                CompactGaugeLabels(mw: currentMw, dataTimestamp: dataTimestamp)
            }
            .frame(width: 140, height: 140)
            .frame(maxWidth: .infinity)
            Rectangle()
                .fill(SofiaColors.outlineVariant)
                .frame(width: 1)
                .padding(.vertical, 12)
            VStack(spacing: 0) {
                // Même taille que « XX MW » ; plus grand, « 1400 MW » ne tient plus dans l'arc
                Text(verbatim: formatGbShare(gbSharePercent))
                    .font(SofiaType.headlineSmall)
                    .fontWeight(.bold)
                    .lineLimit(1)
                Text("gb_share_subtitle")
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
        .animation(.spring(response: 0.5, dampingFraction: 1), value: progress)
        .animation(.spring(response: 0.5, dampingFraction: 1), value: currentMw)
        .padding(16)
        .sofiaCard()
    }
}

/// Production au centre de la jauge compacte, animée comme `animateFloatAsState`.
private struct CompactGaugeLabels: View, Animatable {
    var mw: Double
    let dataTimestamp: Date?

    var animatableData: Double {
        get { mw }
        set { mw = newValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.format("mw_value_format", Int(mw.rounded())))
                .font(SofiaType.headlineSmall)
                .fontWeight(.bold)
                .foregroundStyle(SofiaColors.onSurface)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(L10n.format("gauge_data_timestamp_format", GaugeTimestamp.format(dataTimestamp)))
                .font(SofiaType.labelSmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
        }
        .multilineTextAlignment(.center)
    }
}

/// Arc de fond (270°, ouvert en bas) puis arc de progression en dégradé.
private struct GaugeArc: View {
    let progress: Double
    var stroke: CGFloat = 24

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .rotation(.degrees(135))
                .stroke(
                    SofiaColors.outline.opacity(0.2),
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                )
            Circle()
                .trim(from: 0, to: 0.75 * progress)
                .rotation(.degrees(135))
                .stroke(
                    AngularGradient(
                        colors: [SofiaColors.cyan, SofiaColors.blue, SofiaColors.indigo, SofiaColors.cyan],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: stroke, lineCap: .round)
                )
        }
        .padding(stroke / 2)
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
            Text(L10n.format("gauge_data_timestamp_format", GaugeTimestamp.format(dataTimestamp)))
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
        }
        .multilineTextAlignment(.center)
    }
}

/// « today at 2 PM CET » si la donnée date d'aujourd'hui, sinon « 17/10 14:30 CET », en heure de Paris.
///
/// « CET » est écrit en dur, comme sur l'axe du graphique : en heure d'été (fin mars → fin octobre)
/// l'heure de Paris est en réalité du CEST (UTC+2), comme sur Android.
private enum GaugeTimestamp {
    private static let zone = AxisTimeFormat.zone

    private static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.dateFormat = "h a 'CET'"
        return formatter
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = zone
        formatter.dateFormat = "dd/MM HH:mm 'CET'"
        return formatter
    }()

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return calendar
    }()

    static func format(_ date: Date?) -> String {
        guard let date else { return "—" }
        if calendar.isDateInToday(date) {
            return L10n.format("timestamp_today_format", hourFormatter.string(from: date))
        }
        return dateTimeFormatter.string(from: date)
    }
}
