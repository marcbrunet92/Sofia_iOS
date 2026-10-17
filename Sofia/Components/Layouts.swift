import SwiftUI

/// `PullToRefreshBox` : tirer pour rafraîchir, et indicateur en haut pendant les
/// rafraîchissements automatiques (comme l'indicateur Material piloté par `isRefreshing`).
struct PullToRefreshContainer<Content: View>: View {
    private let isRefreshing: Bool
    private let onRefresh: () async -> Void
    private let content: Content

    @State private var userRefreshing = false

    init(isRefreshing: Bool, onRefresh: @escaping () async -> Void, @ViewBuilder content: () -> Content) {
        self.isRefreshing = isRefreshing
        self.onRefresh = onRefresh
        self.content = content()
    }

    var body: some View {
        let showsIndicator = isRefreshing && !userRefreshing
        ScrollView {
            content
        }
        .refreshable {
            await refreshFromPull()
        }
        .overlay(alignment: .top) {
            ZStack {
                if showsIndicator {
                    ProgressView()
                        .padding(10)
                        .background(SofiaColors.surfaceContainerLow, in: Circle())
                        .shadow(color: .black.opacity(0.2), radius: 3, x: 0, y: 1)
                        .padding(.top, 8)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showsIndicator)
        }
    }

    private func refreshFromPull() async {
        userRefreshing = true
        await onRefresh()
        userRefreshing = false
    }
}
