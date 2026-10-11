import Foundation
import SwiftUI

/// Équivalent de ui/settings/SettingsScreen.kt.
struct SettingsScreen: View {
    let state: SettingsUiState
    let onToggleTestMode: (Bool) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SettingsCard {
                    SettingsListItem(
                        headlineKey: "settings_test_mode_title",
                        supportingKey: "settings_test_mode_description"
                    ) {
                        SettingsSwitch(isOn: state.testMode, onCheckedChange: onToggleTestMode)
                    }
                }
                SettingsCard {
                    SettingsListItem(
                        headlineKey: "settings_disclaimer_title",
                        supportingKey: "settings_disclaimer_description"
                    ) {
                        EmptyView()
                    }
                }
            }
            .padding(16)
        }
        .background(SofiaColors.background.ignoresSafeArea())
        .foregroundStyle(SofiaColors.onSurface)
    }
}

/// `Switch(checked, onCheckedChange)` : l'état affiché suit toujours la valeur persistée.
private struct SettingsSwitch: View {
    private let isOn: Bool
    private let onCheckedChange: (Bool) -> Void

    @State private var value: Bool

    init(isOn: Bool, onCheckedChange: @escaping (Bool) -> Void) {
        self.isOn = isOn
        self.onCheckedChange = onCheckedChange
        _value = State(initialValue: isOn)
    }

    var body: some View {
        Toggle(isOn: $value) {
            Text("settings_test_mode_title")
        }
        .labelsHidden()
        .tint(SofiaColors.primary)
        .onChange(of: value) { _, newValue in
            if newValue != isOn {
                onCheckedChange(newValue)
            }
        }
        .onChange(of: isOn) { _, newValue in
            value = newValue
        }
    }
}

/// `Card` (surfaceContainerHigh, élévation 4 dp, coins 24 dp) contenant un `ListItem`.
private struct SettingsCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(SofiaColors.surfaceContainerHigh)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

/// `ListItem` Material 3 : titre, texte secondaire et contenu à droite, sur fond `surface`.
private struct SettingsListItem<Trailing: View>: View {
    private let headlineKey: String
    private let supportingKey: String
    private let trailing: Trailing

    init(headlineKey: String, supportingKey: String, @ViewBuilder trailing: () -> Trailing) {
        self.headlineKey = headlineKey
        self.supportingKey = supportingKey
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(LocalizedStringKey(headlineKey))
                    .font(SofiaType.bodyLarge)
                    .foregroundStyle(SofiaColors.onSurface)
                Text(LocalizedStringKey(supportingKey))
                    .font(SofiaType.bodyMedium)
                    .foregroundStyle(SofiaColors.onSurfaceVariant)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
        .padding(.leading, 16)
        .padding(.trailing, 24)
        .padding(.vertical, 8)
        .frame(minHeight: 72)
        .background(SofiaColors.surface)
    }
}
