import SwiftUI

@main
struct SofiaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {

    @StateObject private var vm = SofiaViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "speedometer")
                }

            GraphView()
                .tabItem {
                    Label("Graphes", systemImage: "chart.xyaxis.line")
                }

            RemitView()
                .tabItem {
                    Label("Remit", systemImage: "doc.text")
                }

            WeatherView()
                .tabItem {
                    Label("Météo", systemImage: "cloud.sun")
                }

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gear")
                }
        }
        .environmentObject(vm)
    }
}
