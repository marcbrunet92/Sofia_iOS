import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Point d'entrée (équivalent de MainActivity.kt) : construit les repositories et les view models.
@main
struct SofiaApp: App {
    @State private var graphViewModel: GraphViewModel
    @State private var remitViewModel: RemitViewModel

    init() {
        let api = SofiaApiService.shared
        let store = SofiaLocalStore.shared

        _remitViewModel = State(initialValue: RemitViewModel(
            repository: SofiaRemitRepository(api: api, store: store)
        ))
        _graphViewModel = State(initialValue: GraphViewModel(
            productionRepository: SofiaProductionRepository(api: api, store: store),
            b1610Repository: SofiaB1610Repository(api: api, store: store),
            weatherRepository: SofiaWeatherRepository(api: api, store: store),
            melRepository: SofiaMelRepository(api: api, store: store),
            contextRepository: SofiaContextRepository(api: api, store: store)
        ))

        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some Scene {
        WindowGroup {
            SofiaRootView(graphViewModel: graphViewModel, remitViewModel: remitViewModel)
        }
    }
}

private enum AppTab: Int, CaseIterable, Hashable {
    case graph
    case remit

    var item: TabItem {
        switch self {
        case .graph: return TabItem(labelKey: "tab_graph", systemImage: "chart.xyaxis.line")
        case .remit: return TabItem(labelKey: "tab_remit", systemImage: "exclamationmark.triangle.fill")
        }
    }
}

/// Place réservée sous le contenu pour qu'il défile au-delà de la barre flottante.
private let tabBarSpace: CGFloat = 88

/// Équivalent de ui/SofiaApp.kt : les onglets Graphique et Alertes, qu'on fait défiler d'un
/// balayage, sous une barre d'onglets flottante masquée sur le détail d'une alerte.
struct SofiaRootView: View {
    let graphViewModel: GraphViewModel
    let remitViewModel: RemitViewModel

    /// Hors de la pile de navigation : l'onglet courant est conservé à l'aller-retour vers un détail.
    @State private var selectedTab: AppTab = ScreenshotOptions.opensAlertsTab ? .remit : .graph
    /// Route RemitDetail(key) : identifiant du groupe d'alertes ouvert.
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                GraphPage(viewModel: graphViewModel)
                    .tag(AppTab.graph)
                RemitPage(viewModel: remitViewModel, onOpenAlert: { key in path.append(key) })
                    .tag(AppTab.remit)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(SofiaColors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: String.self) { key in
                RemitDetailRoute(viewModel: remitViewModel, key: key)
            }
        }
        .overlay(alignment: .bottom) {
            if path.isEmpty {
                FloatingTabBar(
                    items: AppTab.allCases.map(\.item),
                    selectedIndex: selectedTab.rawValue,
                    onSelect: { index in
                        withAnimation { selectedTab = AppTab(rawValue: index) ?? .graph }
                    }
                )
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: path.isEmpty)
        .tint(SofiaColors.primary)
        .task {
            await openFirstAlertForScreenshot()
        }
    }

    /// Captures d'écran de l'App Store : ouvre la première alerte dès que la liste est chargée.
    private func openFirstAlertForScreenshot() async {
        guard ScreenshotOptions.opensFirstAlert else { return }
        for _ in 0..<120 {
            let sections = remitViewModel.uiState.sections
            if let first = (sections.current + sections.upcoming).first {
                path = [first.id]
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }
}

private struct GraphPage: View {
    let viewModel: GraphViewModel

    var body: some View {
        GraphScreen(
            state: viewModel.uiState,
            bottomInset: tabBarSpace,
            onRefresh: { await viewModel.refresh().value },
            onSelectWindow: { viewModel.selectWindow($0) },
            onToggleDataset: { viewModel.toggleDataset($0) },
            onDismissError: { viewModel.dismissError() }
        )
    }
}

private struct RemitPage: View {
    let viewModel: RemitViewModel
    let onOpenAlert: (String) -> Void

    var body: some View {
        RemitScreen(
            state: viewModel.uiState,
            bottomInset: tabBarSpace,
            onRefresh: { await viewModel.refresh().value },
            onDismissError: { viewModel.dismissError() },
            onOpenAlert: onOpenAlert
        )
    }
}

/// Détail d'une alerte, retrouvée par sa clé dans les sections courantes.
private struct RemitDetailRoute: View {
    let viewModel: RemitViewModel
    let key: String

    var body: some View {
        let sections = viewModel.uiState.sections
        if let group = (sections.current + sections.upcoming).first(where: { $0.id == key }) {
            RemitDetailScreen(group: group)
        } else {
            // Alerte terminée ou passée « en cours » depuis l'ouverture : on garde le bouton retour
            SofiaColors.background
                .ignoresSafeArea()
                .toolbar(.visible, for: .navigationBar)
        }
    }
}
