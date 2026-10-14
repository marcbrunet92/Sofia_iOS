import SwiftUI
import WidgetKit

/// Les widgets de l'app Android : production en direct, disponibilité par unité, graphique,
/// 14 prochains jours (UOU2T14D) et part de l'éolien GB (AGWS).
@main
struct SofiaWidgetBundle: WidgetBundle {
    var body: some Widget {
        SofiaLiveWidget()
        SofiaUnitsWidget()
        SofiaGraphWidget()
        SofiaNextDaysWidget()
        SofiaGbShareWidget()
    }
}
