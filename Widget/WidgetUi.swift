import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de widget/modern/SofiaWidgetUi.kt.

/// Palette sombre fixe, alignée sur le thème de l'app.
enum WidgetPalette {
    static let surface = Color(widgetHex: 0x141B2B)
    static let tile = Color(widgetHex: 0x1F2A3F)
    static let onSurface = Color.white
    static let muted = Color(widgetHex: 0x9FB0C8)
    static let track = Color(widgetHex: 0x2C3B52)
    static let committed = Color(widgetHex: 0x1E88E5)
    static let actual = Color(widgetHex: 0xFF9800)
    static let good = Color(widgetHex: 0x4CAF50)
    static let warn = Color(widgetHex: 0xFFB300)
    static let bad = Color(widgetHex: 0xEF5350)
    // Dégradé de la jauge (SofiaCyan, SofiaBlue, SofiaIndigo)
    static let cyan = Color(widgetHex: 0x4DD0E1)
    static let blue = Color(widgetHex: 0x1E88E5)
    static let indigo = Color(widgetHex: 0x3949AB)
}

extension Color {
    init(widgetHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension AvailabilityLevel {
    /// `UnitStatus.statusColor()`
    var widgetColor: Color {
        switch self {
        case .good: return WidgetPalette.good
        case .warn: return WidgetPalette.warn
        case .bad: return WidgetPalette.bad
        }
    }
}

enum L10n {
    static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), locale: Locale.current, arguments: arguments)
    }
}

/// `formatClock` : « HH:mm » dans le fuseau de l'appareil.
func formatClock(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current
    formatter.dateFormat = "HH:mm"
    return formatter.string(from: date)
}

/// Préfixe « Mis à jour » / « Hors-ligne · » suivi de l'heure.
func updatedLabel(fromCache: Bool, at date: Date) -> String {
    L10n.string(fromCache ? "widget_prefix_offline" : "widget_prefix_updated") + formatClock(date)
}

/// `WText` : texte d'une ligne, taille en points, gras optionnel.
struct WText: View {
    private let text: String
    private let size: CGFloat
    private let color: Color
    private let bold: Bool

    init(_ text: String, _ size: CGFloat, _ color: Color = WidgetPalette.onSurface, bold: Bool = false) {
        self.text = text
        self.size = size
        self.color = color
        self.bold = bold
    }

    var body: some View {
        Text(verbatim: text)
            .font(.system(size: size, weight: bold ? .bold : .regular))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

/// `Dot` : pastille de couleur.
struct Dot: View {
    private let color: Color
    private let size: CGFloat

    init(_ color: Color, size: CGFloat = 8) {
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

/// Barre de progression (LinearProgressIndicator du widget).
struct WidgetProgressBar: View {
    let fraction: Double
    let color: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(WidgetPalette.track)
                Capsule()
                    .fill(color)
                    .frame(width: proxy.size.width * CGFloat(min(max(fraction, 0), 1)))
            }
        }
        .frame(height: 4)
    }
}
