import Foundation
import SwiftUI

/// Équivalent de ui/sofia/SofiaScreen.kt : présentation du parc et carte de localisation.
struct SofiaScreen: View {
    let state: SofiaUiState
    let onDismissError: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TitleBanner(titleKey: "title_sofia")
                if let errorMessage = state.errorMessage {
                    ErrorBanner(text: errorMessage, onDismiss: onDismissError)
                }
                SofiaDescriptionCard()
                SofiaLocationCard()
            }
            .padding(16)
        }
        .background(SofiaColors.background.ignoresSafeArea())
        .foregroundStyle(SofiaColors.onSurface)
    }
}

private struct SofiaDescriptionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("sofia_about_title")
                .font(SofiaType.titleMedium)
            Text("sofia_about_description")
                .font(SofiaType.bodyMedium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sofiaElevatedCard()
    }
}

private struct SofiaLocationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .overlay {
                    Image("SofiaMaps")
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .accessibilityElement()
                .accessibilityLabel(Text("sofia_location_image_desc"))
                .accessibilityAddTraits(.isImage)
            Text("sofia_location_caption")
                .font(SofiaType.labelMedium)
                .padding(12)
        }
        .sofiaElevatedCard()
    }
}
