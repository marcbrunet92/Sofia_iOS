import SwiftUI

struct RemitView: View {

    @EnvironmentObject var vm: SofiaViewModel

    var body: some View {
        NavigationStack {
            Text("Remit")
                .navigationTitle("Remit")
        }
    }
}
