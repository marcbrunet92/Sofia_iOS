import Foundation
import SwiftUI
import WidgetKit
import SofiaCore

/// Point d'entrée (équivalent de MainActivity.kt) : construit les réglages, les repositories et
/// les view models.
@main
struct SofiaApp: App {
    @State private var settings: AppSettings
    @State private var graphViewModel: GraphViewModel
    @State private var remitViewModel: RemitViewModel
    @State private var statsViewModel: StatsViewModel

    init() {
        let api = SofiaApiService.shared
        let store = SofiaLocalStore.shared
        let settings = AppSettings()

        let remitViewModel = RemitViewModel(
            repository: SofiaRemitRepository(api: api, store: store)
        )
        // Les rappels suivent les alertes : reprogrammés à chaque mise à jour
        remitViewModel.onSectionsChanged = { sections in
            let enabled = settings.outageReminders
            Task {
                await AlertReminders.sync(sections: sections, enabled: enabled)
            }
        }

        _settings = State(initialValue: settings)
        _remitViewModel = State(initialValue: remitViewModel)
        _graphViewModel = State(initialValue: GraphViewModel(
            productionRepository: SofiaProductionRepository(api: api, store: store),
            b1610Repository: SofiaB1610Repository(api: api, store: store),
            weatherRepository: SofiaWeatherRepository(api: api, store: store),
            melRepository: SofiaMelRepository(api: api, store: store),
            contextRepository: SofiaContextRepository(api: api, store: store),
            initialWindow: settings.defaultWindow
        ))
        _statsViewModel = State(initialValue: StatsViewModel(
            unitsRepository: SofiaUnitsRepository(api: api)
        ))

        WidgetCenter.shared.reloadAllTimelines()
    }

    var body: some Scene {
        WindowGroup {
            SofiaRootView(
                settings: settings,
                graphViewModel: graphViewModel,
                remitViewModel: remitViewModel,
                statsViewModel: statsViewModel
            )
        }
    }
}

private enum AppTab: Int, CaseIterable, Hashable {
    case graph
    case remit
    case stats
    case settings

    var item: TabItem {
        switch self {
        case .graph: return TabItem(labelKey: "tab_graph", systemImage: "chart.xyaxis.line")
        case .remit: return TabItem(labelKey: "tab_remit", systemImage: "exclamationmark.triangle.fill")
        case .stats: return TabItem(labelKey: "tab_stats", systemImage: "chart.bar.fill")
        case .settings: return TabItem(labelKey: "tab_settings", systemImage: "gearshape.fill")
        }
    }
}

/// Écrans ouverts par-dessus les onglets.
nonisolated enum AlertRoute: Hashable {
    /// Détail d'une alerte : identifiant du groupe d'avis.
    case group(String)
    /// Avis REMIT complet d'une unité : identifiant de l'avis.
    case notice(Int)
}

/// Place réservée sous le contenu pour qu'il défile au-delà de la barre flottante.
private let tabBarSpace: CGFloat = 88

/// Les onglets Graphique, Alertes, Statistiques et Réglages, qu'on fait défiler d'un balayage,
/// sous une barre d'onglets flottante masquée sur le détail d'une alerte.
struct SofiaRootView: View {
    let settings: AppSettings
    let graphViewModel: GraphViewModel
    let remitViewModel: RemitViewModel
    let statsViewModel: StatsViewModel

    /// Hors de la pile de navigation : l'onglet courant est conservé à l'aller-retour vers un détail.
    @State private var selectedTab: AppTab = Self.screenshotTab
    /// Détail d'alerte puis avis d'unité ouverts.
    @State private var path: [AlertRoute] = []
    @State private var showsAbout = ScreenshotOptions.showsAbout
    /// Rappels demandés mais notifications refusées dans les réglages d'iOS.
    @State private var notificationsDenied = false

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                GraphPage(viewModel: graphViewModel, settings: settings, onShowAbout: { showsAbout = true })
                    .tag(AppTab.graph)
                RemitPage(viewModel: remitViewModel, onOpenAlert: { key in path.append(.group(key)) })
                    .tag(AppTab.remit)
                StatsPage(viewModel: statsViewModel, graphViewModel: graphViewModel, settings: settings)
                    .tag(AppTab.stats)
                SettingsScreen(
                    settings: settings,
                    notificationsDenied: notificationsDenied,
                    bottomInset: tabBarSpace,
                    onSetReminders: { enabled in setReminders(enabled) },
                    onShowAbout: { showsAbout = true }
                )
                .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .background(SofiaColors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AlertRoute.self) { route in
                switch route {
                case .group(let key):
                    RemitDetailRoute(viewModel: remitViewModel, key: key)
                case .notice(let id):
                    RemitNoticeRoute(viewModel: remitViewModel, id: id)
                }
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
        .preferredColorScheme(settings.appearance.colorScheme)
        .sheet(isPresented: $showsAbout) {
            AboutScreen()
                .preferredColorScheme(settings.appearance.colorScheme)
        }
        .task {
            // Rappels activés lors d'un lancement précédent, puis notifications coupées dans iOS
            if settings.outageReminders {
                notificationsDenied = await AlertReminders.isDenied()
            }
            await openFirstAlertForScreenshot()
            await playDemoTour()
        }
    }

    /// Active ou coupe les rappels : demande l'autorisation d'iOS, puis (re)programme les rappels.
    private func setReminders(_ enabled: Bool) {
        Task {
            var granted = false
            if enabled {
                granted = await AlertReminders.requestAuthorization()
            }
            notificationsDenied = enabled && !granted
            settings.setOutageReminders(granted)
            await AlertReminders.sync(sections: remitViewModel.uiState.sections, enabled: granted)
        }
    }

    /// Vidéo de démonstration (.github/scripts/demo-video.sh) : parcourt l'app comme le ferait un
    /// utilisateur, sans toucher l'écran (simctl ne sait pas taper).
    private func playDemoTour() async {
        guard ScreenshotOptions.playsDemoTour else { return }
        func pause(_ seconds: Double) async {
            try? await Task.sleep(for: .seconds(seconds))
        }
        for _ in 0..<240 {
            if graphViewModel.uiState.hasData { break }
            await pause(0.25)
        }
        await pause(3)

        for window in [TimeWindow.hours24, .days7, .month1, .month6, .all] {
            withAnimation { graphViewModel.selectWindow(window) }
            await pause(2.5)
        }
        for dataset in [GraphDataset.weather, .b1610, .mel] {
            withAnimation { graphViewModel.toggleDataset(dataset) }
            await pause(3.5)
            withAnimation { graphViewModel.toggleDataset(dataset) }
            await pause(1)
        }

        showsAbout = true
        await pause(6)
        showsAbout = false
        await pause(2)

        withAnimation { selectedTab = .remit }
        await pause(4)
        let sections = remitViewModel.uiState.sections
        if let first = (sections.current + sections.upcoming).first {
            path = [.group(first.id)]
            await pause(5)
            // Avis REMIT complet de la première unité
            path = [.group(first.id), .notice(first.first.id)]
            await pause(5)
            path = []
            await pause(2)
        }

        withAnimation { selectedTab = .stats }
        await pause(4)
        for period in [StatsPeriod.day, .month, .all] {
            withAnimation { statsViewModel.selectPeriod(period) }
            await pause(3)
        }
        withAnimation { statsViewModel.selectPeriod(.week) }

        withAnimation { selectedTab = .settings }
        await pause(4)
        withAnimation { selectedTab = .graph }
    }

    /// Captures d'écran de l'App Store : onglet demandé au lancement.
    private static var screenshotTab: AppTab {
        switch ScreenshotOptions.tab {
        case "remit": return .remit
        case "stats": return .stats
        case "settings": return .settings
        default: return .graph
        }
    }

    /// Captures d'écran de l'App Store : ouvre la première alerte (et l'avis de sa première unité)
    /// dès que la liste est chargée.
    private func openFirstAlertForScreenshot() async {
        guard ScreenshotOptions.opensFirstAlert || ScreenshotOptions.opensFirstNotice else { return }
        for _ in 0..<120 {
            let sections = remitViewModel.uiState.sections
            if let first = (sections.current + sections.upcoming).first {
                path = ScreenshotOptions.opensFirstNotice
                    ? [.group(first.id), .notice(first.first.id)]
                    : [.group(first.id)]
                return
            }
            try? await Task.sleep(for: .milliseconds(250))
        }
    }
}

private struct GraphPage: View {
    let viewModel: GraphViewModel
    let settings: AppSettings
    let onShowAbout: () -> Void

    var body: some View {
        GraphScreen(
            state: viewModel.uiState,
            windUnit: settings.windUnit,
            bottomInset: tabBarSpace,
            onRefresh: { await viewModel.refresh().value },
            onSelectWindow: { viewModel.selectWindow($0) },
            onToggleDataset: { viewModel.toggleDataset($0) },
            onDismissError: { viewModel.dismissError() },
            onShowAbout: onShowAbout
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

private struct StatsPage: View {
    let viewModel: StatsViewModel
    let graphViewModel: GraphViewModel
    let settings: AppSettings

    var body: some View {
        StatsScreen(
            graph: graphViewModel.uiState,
            state: viewModel.uiState,
            windUnit: settings.windUnit,
            bottomInset: tabBarSpace,
            onRefresh: {
                // Les séries du graphique et la production par unité, en parallèle
                let units = viewModel.refresh()
                await graphViewModel.refresh().value
                await units.value
            },
            onSelectPeriod: { viewModel.selectPeriod($0) }
        )
    }
}

/// Avis REMIT complet d'une unité, retrouvé par son identifiant dans les avis en cache.
private struct RemitNoticeRoute: View {
    let viewModel: RemitViewModel
    let id: Int

    var body: some View {
        if let notice = viewModel.uiState.remits.first(where: { $0.id == id }) {
            RemitNoticeDetailScreen(notice: notice)
        } else {
            // Avis retiré depuis l'ouverture : on garde le bouton retour
            SofiaColors.background
                .ignoresSafeArea()
                .toolbar(.visible, for: .navigationBar)
        }
    }
}
