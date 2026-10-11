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

/// `formatTimestamp` (RemitScreen.kt) : « yyyy-MM-dd HH:mm » dans le fuseau de l'appareil, « — » si absent.
enum SofiaDateFormat {
    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()

    static func timestamp(_ date: Date?) -> String {
        guard let date else { return "—" }
        return timestampFormatter.string(from: date)
    }
}

/// Une annulation (nouveau rafraîchissement, changement de mode) n'est pas une erreur à afficher.
func isCancellation(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    if let urlError = error as? URLError, urlError.code == .cancelled { return true }
    return false
}
