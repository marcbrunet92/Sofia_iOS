import SwiftUI

/// EmptyChartPlaceHolder.kt : faux graphique en filigrane et message « Aucune donnée ».
struct EmptyChartPlaceholder: View {
    /// `nil` = toute la hauteur disponible.
    var height: CGFloat? = 280

    var body: some View {
        let lineColor = SofiaColors.outlineVariant
        let containerColor = SofiaColors.surfaceContainerLow
        ZStack {
            Canvas { context, size in
                let dash: [CGFloat] = [5, 5]

                // Grille horizontale
                for index in 0..<4 {
                    let y = size.height * CGFloat(index + 1) / 5
                    var line = Path()
                    line.move(to: CGPoint(x: 0, y: y))
                    line.addLine(to: CGPoint(x: size.width, y: y))
                    context.stroke(
                        line,
                        with: .color(lineColor.opacity(0.4)),
                        style: StrokeStyle(lineWidth: 1, dash: dash)
                    )
                }

                // Courbe fantôme
                var curve = Path()
                curve.move(to: CGPoint(x: 0, y: size.height * 0.7))
                curve.addCurve(
                    to: CGPoint(x: size.width * 0.65, y: size.height * 0.5),
                    control1: CGPoint(x: size.width * 0.25, y: size.height * 0.3),
                    control2: CGPoint(x: size.width * 0.45, y: size.height * 0.9)
                )
                curve.addCurve(
                    to: CGPoint(x: size.width, y: size.height * 0.2),
                    control1: CGPoint(x: size.width * 0.8, y: size.height * 0.25),
                    control2: CGPoint(x: size.width * 0.9, y: size.height * 0.4)
                )
                context.stroke(
                    curve,
                    with: .color(lineColor),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: dash)
                )
            }
            .padding(24)

            VStack(spacing: 4) {
                Text("chart_empty_title")
                    .font(SofiaType.titleMedium)
                    .foregroundStyle(SofiaColors.onSurface)
                Text("chart_empty_message")
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(containerColor.opacity(0.9), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(maxWidth: .infinity)
        .chartHeight(height)
        .background(containerColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
