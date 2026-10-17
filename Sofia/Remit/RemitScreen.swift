import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/remit/RemitScreen.kt : l'écran Alertes.
struct RemitScreen: View {
    let state: RemitUiState
    /// Hauteur réservée sous le contenu (barre d'onglets flottante).
    var bottomInset: CGFloat = 0
    let onRefresh: () async -> Void
    let onDismissError: () -> Void
    let onOpenAlert: (String) -> Void

    private static let clockFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        ZStack {
            SofiaColors.background
                .ignoresSafeArea()

            if state.isLoading && state.remits.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PullToRefreshContainer(isRefreshing: state.isRefreshing, onRefresh: onRefresh) {
                    content
                }
            }
        }
        .foregroundStyle(SofiaColors.onSurface)
    }

    private var content: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("tab_remit")
                    .font(SofiaType.headlineMedium)
                    .fontWeight(.bold)
                if let lastFetch = state.lastFetchTimestamp {
                    Text(verbatim: L10n.format("remit_last_update_format", Self.clockFormatter.string(from: lastFetch)))
                        .font(SofiaType.bodySmall)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 8)
            if let errorKey = state.errorMessageKey {
                RemitErrorBanner(text: L10n.string(errorKey), onDismiss: onDismissError)
            }
            if let units = state.units {
                UnitsAvailabilityCard(data: units)
            }
            if state.sections.noticeCount == 0 {
                AllClearCard()
            }
            alertSection(titleKey: "remit_section_current", groups: state.sections.current)
            alertSection(titleKey: "remit_section_upcoming", groups: state.sections.upcoming)
        }
        .padding(16)
        .padding(.bottom, bottomInset)
    }

    @ViewBuilder
    private func alertSection(titleKey: String, groups: [RemitGroup]) -> some View {
        if !groups.isEmpty {
            Text(LocalizedStringKey(titleKey))
                .font(SofiaType.titleMedium)
                .fontWeight(.semibold)
                .padding(.leading, 4)
                .padding(.top, 12)
            ForEach(groups) { group in
                AlertCard(group: group) { onOpenAlert(group.id) }
            }
        }
    }
}

private struct AllClearCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(AvailabilityColors.available)
            Text("remit_no_alerts")
                .font(SofiaType.titleMedium)
        }
        .padding(16)
        .sofiaCard()
    }
}
