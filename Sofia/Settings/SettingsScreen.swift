import Foundation
import SwiftUI
import UIKit
import SofiaCore

/// Onglet Réglages : affichage, rappels des alertes, et accès à la feuille « À propos »
/// (sources des données, avertissement, confidentialité).
struct SettingsScreen: View {
    let settings: AppSettings
    /// Les notifications sont refusées dans les réglages d'iOS : on explique comment les rétablir.
    let notificationsDenied: Bool
    /// Hauteur réservée sous le contenu (barre d'onglets flottante).
    var bottomInset: CGFloat = 0
    let onSetReminders: (Bool) -> Void
    let onShowAbout: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TitleBanner(titleKey: "tab_settings")
                displayCard
                remindersCard
                aboutCard
            }
            .padding(16)
            .padding(.bottom, bottomInset)
        }
        .background(SofiaColors.background.ignoresSafeArea())
        .foregroundStyle(SofiaColors.onSurface)
    }

    // MARK: - Affichage

    private var displayCard: some View {
        InfoCardContainer {
            CardTitle(titleKey: "settings_display_title")

            SettingLabel(titleKey: "settings_appearance_title")
            Picker("settings_appearance_title", selection: appearanceBinding) {
                ForEach(AppAppearance.allCases, id: \.self) { appearance in
                    Text(LocalizedStringKey(appearance.labelKey)).tag(appearance)
                }
            }
            .pickerStyle(.segmented)

            SettingLabel(titleKey: "settings_wind_unit_title", descriptionKey: "settings_wind_unit_description")
            Picker("settings_wind_unit_title", selection: windUnitBinding) {
                ForEach(WindSpeedUnit.allCases, id: \.self) { unit in
                    Text(verbatim: unit.symbol).tag(unit)
                }
            }
            .pickerStyle(.segmented)

            HStack(alignment: .center, spacing: 12) {
                SettingLabel(titleKey: "settings_default_window_title", descriptionKey: "settings_default_window_description")
                Picker("settings_default_window_title", selection: defaultWindowBinding) {
                    ForEach(TimeWindow.allCases, id: \.self) { window in
                        Text(LocalizedStringKey(window.longLabelKey)).tag(window)
                    }
                }
                .pickerStyle(.menu)
                .tint(SofiaColors.primary)
            }
        }
    }

    private var appearanceBinding: Binding<AppAppearance> {
        Binding(get: { settings.appearance }, set: { settings.setAppearance($0) })
    }

    private var windUnitBinding: Binding<WindSpeedUnit> {
        Binding(get: { settings.windUnit }, set: { settings.setWindUnit($0) })
    }

    private var defaultWindowBinding: Binding<TimeWindow> {
        Binding(get: { settings.defaultWindow }, set: { settings.setDefaultWindow($0) })
    }

    // MARK: - Rappels

    private var remindersCard: some View {
        InfoCardContainer {
            CardTitle(titleKey: "settings_notifications_title")
            Toggle(isOn: Binding(get: { settings.outageReminders }, set: { onSetReminders($0) })) {
                SettingLabel(titleKey: "settings_reminders_title", descriptionKey: "settings_reminders_description")
            }
            .tint(SofiaColors.primary)
            if notificationsDenied {
                Text("settings_reminders_denied")
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.error)
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: url) {
                        Text("settings_open_ios_settings")
                            .font(SofiaType.labelLarge)
                    }
                    .tint(SofiaColors.primary)
                }
            }
        }
    }

    // MARK: - À propos

    private var aboutCard: some View {
        InfoCardContainer {
            CardTitle(titleKey: "about_title")
            Button(action: onShowAbout) {
                SettingsRow(titleKey: "settings_about_row", systemImage: "info.circle")
            }
            .buttonStyle(.plain)
            Link(destination: AboutLinks.privacyPolicy) {
                SettingsRow(titleKey: "about_privacy_link", systemImage: "hand.raised", external: true)
            }
            .buttonStyle(.plain)
            if let url = URL(string: SofiaConstants.webURL) {
                Link(destination: url) {
                    SettingsRow(titleKey: "settings_link_web", systemImage: "globe", external: true)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Titre d'un réglage et sa description.
private struct SettingLabel: View {
    let titleKey: String
    var descriptionKey: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(LocalizedStringKey(titleKey))
                .font(SofiaType.bodyLarge)
                .foregroundStyle(SofiaColors.onSurface)
            if let descriptionKey {
                Text(LocalizedStringKey(descriptionKey))
                    .font(SofiaType.bodySmall)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Ligne cliquable : icône, titre, chevron (ou flèche pour un lien externe).
private struct SettingsRow: View {
    let titleKey: String
    let systemImage: String
    var external = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 17))
                .foregroundStyle(SofiaColors.primary)
                .frame(width: 24)
            Text(LocalizedStringKey(titleKey))
                .font(SofiaType.bodyLarge)
                .foregroundStyle(SofiaColors.onSurface)
            Spacer()
            Image(systemName: external ? "arrow.up.right" : "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(SofiaColors.onSurfaceVariant)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
