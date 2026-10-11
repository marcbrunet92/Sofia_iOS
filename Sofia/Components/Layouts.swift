import SwiftUI

/// Équivalent de `FlowRow` : place les vues en ligne et passe à la ligne si nécessaire.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(maxWidth: maxWidth, subviews: subviews)
        let contentWidth = rows.map { $0.width }.max() ?? 0
        let height = rows.reduce(CGFloat(0)) { $0 + $1.height }
            + CGFloat(max(rows.count - 1, 0)) * lineSpacing
        return CGSize(width: min(contentWidth, maxWidth), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            if !current.indices.isEmpty && current.width + spacing + size.width > maxWidth {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty {
            rows.append(current)
        }
        return rows
    }
}

/// Équivalent d'une `Row` dont les enfants ont des `Modifier.weight(…)`.
struct WeightedRow: Layout {
    var weights: [CGFloat]

    private func weight(_ index: Int) -> CGFloat {
        index < weights.count ? weights[index] : 1
    }

    private var totalWeight: CGFloat {
        max(weights.reduce(0, +), 0.0001)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard let width = proposal.width, width.isFinite else {
            var idealWidth: CGFloat = 0
            var idealHeight: CGFloat = 0
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                idealWidth += size.width
                idealHeight = max(idealHeight, size.height)
            }
            return CGSize(width: idealWidth, height: idealHeight)
        }
        var height: CGFloat = 0
        for index in subviews.indices {
            let columnWidth = width * weight(index) / totalWeight
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: columnWidth, height: nil))
            height = max(height, size.height)
        }
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for index in subviews.indices {
            let columnWidth = bounds.width * weight(index) / totalWeight
            subviews[index].place(
                at: CGPoint(x: x, y: bounds.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: columnWidth, height: nil)
            )
            x += columnWidth
        }
    }
}

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
