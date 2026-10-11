import Foundation
import SwiftUI

/// TitleBanner.kt
struct TitleBanner: View {
    var titleKey: String = "title_sofia_live_generation"

    var body: some View {
        Text(LocalizedStringKey(titleKey))
            .font(SofiaType.headlineMedium)
            .fontWeight(.bold)
            .foregroundStyle(SofiaColors.onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
    }
}

/// ErrorBanner.kt
struct ErrorBanner: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text(text)
                .font(SofiaType.bodyLarge)
                .fontWeight(.medium)
                .foregroundStyle(SofiaColors.error)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 8)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(SofiaColors.error)
                    .frame(width: 48, height: 48)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("dismiss_error"))
        }
        .padding(8)
        .sofiaCard(SofiaColors.errorContainer)
    }
}

/// RemitErrorBanner.kt (identique à ErrorBanner)
struct RemitErrorBanner: View {
    let text: String
    let onDismiss: () -> Void

    var body: some View {
        ErrorBanner(text: text, onDismiss: onDismiss)
    }
}

/// WarningBanner.kt
struct WarningBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SofiaType.bodyLarge)
            .fontWeight(.semibold)
            .foregroundStyle(SofiaColors.yellowText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .sofiaCard(SofiaColors.yellow)
    }
}

/// InfoCard.kt
struct InfoCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(SofiaType.bodyMedium)
            .foregroundStyle(SofiaColors.onSurface)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .sofiaCard()
    }
}

/// Capacity Text.kt
struct CapacityText: View {
    let label: String
    let valueMw: Double?

    var body: some View {
        Text(L10n.format("capacity_format", label, valueMw.map { String(Int($0.rounded())) } ?? "—"))
            .font(SofiaType.bodySmall)
    }
}

/// HorizontalDivider Material 3.
struct SofiaDivider: View {
    var body: some View {
        Rectangle()
            .fill(SofiaColors.outlineVariant)
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }
}
