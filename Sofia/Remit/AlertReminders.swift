import Foundation
import UserNotifications
import SofiaCore

/// Rappels locaux des alertes : une notification au début de chaque indisponibilité à venir et
/// une à la fin de chaque indisponibilité datée. Programmés sur l'appareil à chaque mise à jour
/// des alertes, sans serveur de notifications.
enum AlertReminders {
    /// Préfixe des identifiants de nos notifications programmées.
    private static let prefix = "alert-reminder."

    /// Demande l'autorisation d'afficher des notifications ; `false` si elle est refusée.
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            print("AlertReminders: authorization failed: \(error)")
            return false
        }
    }

    /// `true` si l'utilisateur a refusé les notifications de l'app dans les réglages d'iOS.
    static func isDenied() async -> Bool {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus == .denied
    }

    /// Remplace les rappels programmés par ceux des alertes de `sections`.
    /// Désactivé (`enabled` faux) ou sans autorisation : les rappels programmés sont supprimés.
    static func sync(sections: RemitSections, enabled: Bool, now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let obsolete = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        if !obsolete.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: obsolete)
        }
        guard enabled else { return }

        let settings = await center.notificationSettings()
        let status = settings.authorizationStatus
        guard status == .authorized || status == .provisional else { return }

        for reminder in planAlertReminders(sections, now: now) {
            let content = UNMutableNotificationContent()
            content.title = title(reminder)
            content.body = body(reminder)
            content.sound = .default
            let delay = Swift.max(reminder.fireDate.timeIntervalSince(Date()), 1)
            let request = UNNotificationRequest(
                identifier: prefix + reminder.id,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
            )
            do {
                try await center.add(request)
            } catch {
                print("AlertReminders: scheduling failed: \(error)")
            }
        }
    }

    private static func title(_ reminder: AlertReminder) -> String {
        switch reminder.kind {
        case .start: return L10n.format("reminder_start_title_format", reminder.group.title)
        case .end: return L10n.format("reminder_end_title_format", reminder.group.title)
        }
    }

    /// « Toutes les unités · 0 / 1400 MW disponibles » au début, « Toutes les unités » à la fin.
    private static func body(_ reminder: AlertReminder) -> String {
        let group = reminder.group
        let scope = AlertFormat.scopeText(group)
        switch reminder.kind {
        case .start:
            return scope + " · " + AlertFormat.availabilityText(available: group.availableMw, normal: group.normalMw)
        case .end:
            return scope
        }
    }
}
