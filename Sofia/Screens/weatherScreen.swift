import SwiftUI

struct WeatherView: View {

    @EnvironmentObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            Text("Météo")
                .navigationTitle("Météo")
        }
    }
}
