import SwiftUI

struct GraphView: View {

    @EnvironmentObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            Text("Graphes")
                .navigationTitle("Graphes")
        }
    }
}
