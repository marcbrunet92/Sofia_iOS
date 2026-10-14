import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/remit/RemitScreen.kt.
struct RemitScreen: View {
    let state: RemitUiState
    let onRefresh: () async -> Void
    let onDismissError: () -> Void
    let onNavigateToDetail: (Int) -> Void

    /// Groupes dépliés (identifiant du groupe), conservés au retour du détail.
    @State private var expandedGroups: Set<String> = []

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
            let sections = state.sections
            InfoCard(text: String(localized: "remit_active_notices \(sections.noticeCount)"))
            if sections.noticeCount == 0 {
                InfoCard(text: L10n.string("remit_no_active_notices"))
            } else {
                // En vigueur d'abord, puis « À venir »
                ForEach(sections.current) { group in
                    groupView(group)
                }
                if !sections.upcoming.isEmpty {
                    UpcomingDivider()
                    ForEach(sections.upcoming) { group in
                        groupView(group)
                    }
                }
            }
            InfoCard(text: L10n.format("remit_last_update_format", SofiaDateFormat.timestamp(state.lastFetchTimestamp)))
        }
        .padding(16)
    }

    @ViewBuilder
    private func groupView(_ group: RemitGroup) -> some View {
        if group.isFarmWide {
            let expanded = expandedGroups.contains(group.id)
            RemitGroupCard(
                group: group,
                expanded: expanded,
                onToggle: {
                    if expanded {
                        expandedGroups.remove(group.id)
                    } else {
                        expandedGroups.insert(group.id)
                    }
                },
                onOpenNotice: onNavigateToDetail
            )
        } else {
            RemitNoticeCard(notice: group.first, phase: group.phase) {
                onNavigateToDetail(group.first.id)
            }
        }
    }
}
