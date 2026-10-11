import Foundation
import Observation

struct SofiaUiState {
    var isLoading = false
    var errorMessage: String?
}

/// Équivalent de ui/sofia/SofiaViewModel.kt.
@Observable
final class SofiaViewModel {
    private(set) var state = SofiaUiState()

    func onDismissError() {
        state.errorMessage = nil
    }
}
