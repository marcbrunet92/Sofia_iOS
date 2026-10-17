import Foundation

/// Accès aux chaînes de Localizable.xcstrings (mêmes clés que les strings.xml Android).
enum L10n {
    nonisolated static func string(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    /// Format positionnel (`%1$@`, `%1$ld`…) comme `stringResource(id, args)`.
    nonisolated static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: NSLocalizedString(key, comment: ""), locale: Locale.current, arguments: arguments)
    }
}

/// Une annulation (nouveau rafraîchissement) n'est pas une erreur à afficher.
func isCancellation(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    if let urlError = error as? URLError, urlError.code == .cancelled { return true }
    return false
}
