import SwiftUI
import WidgetKit

/// Les trois widgets de l'app Android : production en direct, disponibilité par unité, graphique.
@main
struct SofiaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SofiaLiveWidget()
        SofiaUnitsWidget()
        SofiaGraphWidget()
    }
}
