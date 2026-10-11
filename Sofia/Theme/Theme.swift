import Foundation
import SwiftUI
import UIKit

/// Équivalent de ui/theme/Color.kt + Theme.kt : palette Material 3 de l'app Android
/// (couleurs Sofia surchargées, valeurs Material par défaut pour le reste), claire et sombre.
enum SofiaColors {
    // Color.kt
    static let cyan = fixed(0x4DD0E1)
    static let blue = fixed(0x1E88E5)
    static let indigo = fixed(0x3949AB)
    static let yellow = fixed(0xFFF3CD)
    static let yellowText = fixed(0x6A4F00)
    static let errorContainer = fixed(0xFFDAD6)

    // Theme.kt (lightColorScheme / darkColorScheme)
    static let primary = blue
    static let secondary = cyan
    static let tertiary = indigo
    static let background = dynamic(light: 0xF5F7FA, dark: 0x0F1724)
    static let surface = dynamic(light: 0xFFFFFF, dark: 0x182233)
    static let surfaceContainer = dynamic(light: 0xF0F4FA, dark: 0x1D2A3D)
    static let surfaceContainerLow = dynamic(light: 0xF7F9FC, dark: 0x172131)
    static let surfaceContainerHigh = dynamic(light: 0xE7EDF7, dark: 0x243248)
    static let surfaceVariant = dynamic(light: 0xE3E8F2, dark: 0x2C3B52)
    static let outline = dynamic(light: 0xD0D7E2, dark: 0x3A4A63)

    // Valeurs Material 3 par défaut (non surchargées dans Theme.kt)
    static let surfaceContainerHighest = dynamic(light: 0xE6E0E9, dark: 0x36343B)
    static let outlineVariant = dynamic(light: 0xCAC4D0, dark: 0x49454F)
    static let onSurface = dynamic(light: 0x1D1B20, dark: 0xE6E0E9)
    static let onSurfaceVariant = dynamic(light: 0x49454F, dark: 0xCAC4D0)
    static let error = dynamic(light: 0xB3261E, dark: 0xF2B8B5)
    static let secondaryContainer = dynamic(light: 0xE8DEF8, dark: 0x4A4458)
    static let onSecondaryContainer = dynamic(light: 0x1D192B, dark: 0xE8DEF8)

    // Statuts de disponibilité (WidgetPalette)
    static let good = fixed(0x4CAF50)
    static let warn = fixed(0xFFB300)
    static let bad = fixed(0xEF5350)

    nonisolated static func fixed(_ hex: UInt32) -> Color {
        Color(uiColor: uiColor(hex))
    }

    nonisolated static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? SofiaColors.uiColor(dark) : SofiaColors.uiColor(light)
        })
    }

    nonisolated static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Équivalent de ui/theme/Type.kt : échelle typographique Material 3.
enum SofiaType {
    static let headlineMedium = Font.system(size: 28)
    static let headlineSmall = Font.system(size: 24)
    static let titleLarge = Font.system(size: 22)
    static let titleMedium = Font.system(size: 16, weight: .medium)
    static let titleSmall = Font.system(size: 14, weight: .medium)
    static let bodyLarge = Font.system(size: 16)
    static let bodyMedium = Font.system(size: 14)
    static let bodySmall = Font.system(size: 12)
    static let labelLarge = Font.system(size: 14, weight: .medium)
    static let labelMedium = Font.system(size: 12, weight: .medium)
    static let labelSmall = Font.system(size: 11, weight: .medium)
}

extension View {
    /// Fond d'une `Card` Material 3 (coins de 12 dp, pleine largeur).
    func sofiaCard(_ color: Color = SofiaColors.surfaceContainerHighest, cornerRadius: CGFloat = 12) -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// `ElevatedCard` Material 3 : surfaceContainerLow et légère ombre.
    func sofiaElevatedCard() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .background(SofiaColors.surfaceContainerLow, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 1.5, x: 0, y: 1)
    }
}
