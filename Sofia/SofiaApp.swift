import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Point d'entrée (équivalent de MainActivity.kt) : construit les repositories et les view models.
@main
struct SofiaApp: App {
    @State private var graphViewModel: GraphViewModel
    @State private var remitViewModel: RemitViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var sofiaViewModel: SofiaViewModel

    init() {
        let api = SofiaApiService.shared
        let store = SofiaLocalStore.shared
        let settingsRepository = SettingsRepository.shared

        _settingsViewModel = State(initialValue: SettingsViewModel(settingsRepository: settingsRepository))
        _remitViewModel = State(initialValue: RemitViewModel(
            repository: SofiaRemitRepository(api: api, store: store),
            settingsRepository: settingsRepository
        ))
        _graphViewModel = State(initialValue: GraphViewModel(
            productionRepository: SofiaProductionRepository(api: api, store: store),
            b1610Repository: SofiaB1610Repository(api: api, store: store),
            weatherRepository: SofiaWeatherRepository(api: api, store: store),
            melRepository: SofiaMelRepository(api: api, store: store),
            contextRepository: SofiaContextRepository(api: api, store: store),
            settingsRepository: settingsRepository
        ))
        _sofiaViewModel = State(initialValue: SofiaViewModel())

        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some Scene {
        WindowGroup {
            SofiaRootView(
                graphViewModel: graphViewModel,
                remitViewModel: remitViewModel,
                settingsViewModel: settingsViewModel,
                sofiaViewModel: sofiaViewModel
            )
        }
    }
}

private enum AppTab: Hashable {
    case graph
    case remit
    case sofia
    case settings
}

/// Équivalent de ui/SofiaApp.kt : barre de navigation du bas (Graphique, Alertes, Sofia, Réglages).
struct SofiaRootView: View {
    private let graphViewModel: GraphViewModel
    private let remitViewModel: RemitViewModel
    private let settingsViewModel: SettingsViewModel
    private let sofiaViewModel: SofiaViewModel

    @State private var selectedTab: AppTab = .graph

    init(
        graphViewModel: GraphViewModel,
        remitViewModel: RemitViewModel,
        settingsViewModel: SettingsViewModel,
        sofiaViewModel: SofiaViewModel
    ) {
        self.graphViewModel = graphViewModel
        self.remitViewModel = remitViewModel
        self.settingsViewModel = settingsViewModel
        self.sofiaViewModel = sofiaViewModel
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            GraphTab(viewModel: graphViewModel)
                .tabItem { Label("tab_graph", systemImage: "chart.xyaxis.line") }
                .tag(AppTab.graph)
            RemitTab(viewModel: remitViewModel)
                .tabItem { Label("tab_remit", systemImage: "exclamationmark.triangle.fill") }
                .tag(AppTab.remit)
            SofiaTab(viewModel: sofiaViewModel)
                .tabItem { Label("tab_sofia", systemImage: "house.fill") }
                .tag(AppTab.sofia)
            SettingsTab(viewModel: settingsViewModel)
                .tabItem { Label("tab_settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(SofiaColors.primary)
    }
}

private struct GraphTab: View {
    let viewModel: GraphViewModel

    var body: some View {
        GraphScreen(
            state: viewModel.uiState,
            onRefresh: { await viewModel.refresh().value },
            onSelectWindow: { viewModel.selectWindow($0) },
            onToggleDataset: { viewModel.toggleDataset($0) },
            onDismissError: { viewModel.dismissError() }
        )
    }
}

/// Liste des avis et navigation vers le détail (route RemitDetail(id)).
private struct RemitTab: View {
    private let viewModel: RemitViewModel

    @State private var path: [Int] = []

    init(viewModel: RemitViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        NavigationStack(path: $path) {
            RemitScreen(
                state: viewModel.uiState,
                onRefresh: { await viewModel.refresh().value },
                onDismissError: { viewModel.dismissError() },
                onNavigateToDetail: { id in path.append(id) }
            )
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Int.self) { id in
                if let notice = viewModel.uiState.remits.first(where: { $0.id == id }) {
                    RemitDetailScreen(notice: notice)
                }
            }
        }
    }
}

private struct SofiaTab: View {
    let viewModel: SofiaViewModel

    var body: some View {
        SofiaScreen(
            state: viewModel.state,
            onDismissError: { viewModel.onDismissError() }
        )
    }
}

private struct SettingsTab: View {
    let viewModel: SettingsViewModel

    var body: some View {
        SettingsScreen(
            state: viewModel.uiState,
            onToggleTestMode: { viewModel.setTestMode($0) }
        )
    }
}
