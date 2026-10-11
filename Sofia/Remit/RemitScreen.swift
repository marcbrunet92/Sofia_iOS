import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/remit/RemitScreen.kt.
struct RemitScreen: View {
    let state: RemitUiState
    let onRefresh: () async -> Void
    let onDismissError: () -> Void
    let onNavigateToDetail: (Int) -> Void

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
        LazyVStack(spacing: 8) {
            if let errorKey = state.errorMessageKey {
                RemitErrorBanner(text: L10n.string(errorKey), onDismiss: onDismissError)
            }
            if state.testMode {
                InfoCard(text: L10n.string("remit_test_mode_info"))
            }
            Text("remit_notices_title")
                .font(SofiaType.headlineMedium)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let units = state.units {
                UnitsAvailabilityCard(data: units)
            }
            InfoCard(text: String(localized: "remit_active_notices \(state.remits.count)"))
            if state.remits.isEmpty {
                InfoCard(text: L10n.string("remit_no_active_notices"))
            } else {
                ForEach(state.remits) { notice in
                    RemitNoticeCard(notice: notice) {
                        onNavigateToDetail(notice.id)
                    }
                }
            }
            InfoCard(text: L10n.format("remit_last_update_format", SofiaDateFormat.timestamp(state.lastFetchTimestamp)))
        }
        .padding(16)
    }
}
