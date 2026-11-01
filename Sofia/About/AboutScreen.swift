import Foundation
import MapKit
import SwiftUI

/// Feuille « À propos », ouverte par le bouton (i) de l'écran Graphique : le parc, les données
/// affichées, leurs sources (attributions exigées par les licences Elexon et Open-Meteo),
/// l'avertissement d'app indépendante et la confidentialité.
struct AboutScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    farmCard
                    dataCard
                    sourcesCard
                    AboutCard(titleKey: "settings_disclaimer_title") {
                        BodyText(key: "settings_disclaimer_description")
                    }
                    AboutCard(titleKey: "about_privacy_title") {
                        BodyText(key: "about_privacy_text")
                        Link(destination: AboutLinks.privacyPolicy) {
                            Text("about_privacy_link")
                                .font(SofiaType.labelLarge)
                        }
                    }
                    Text(verbatim: Self.versionText)
                        .font(SofiaType.bodySmall)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 16)
                }
                .padding(16)
            }
            .foregroundStyle(SofiaColors.onSurface)
            .background(SofiaColors.background.ignoresSafeArea())
            .navigationTitle(Text("about_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button { dismiss() } label: { Text("about_done") }
                }
            }
        }
        .tint(SofiaColors.primary)
    }

    private var farmCard: some View {
        AboutCard(titleKey: "sofia_about_title") {
            BodyText(key: "about_app_text")
            Map(initialPosition: .region(Self.farmRegion), interactionModes: []) {
                Marker(L10n.string("title_sofia"), systemImage: "wind", coordinate: Self.farmCenter)
                    .tint(SofiaColors.primary)
            }
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .accessibilityLabel(Text("sofia_location_image_desc"))
            Text("sofia_location_caption")
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
            BodyText(key: "sofia_about_description")
        }
    }

    private var dataCard: some View {
        AboutCard(titleKey: "data_info_title") {
            DataRow(labelKey: "dataset_pn", textKey: "data_info_pn")
            DataRow(labelKey: "dataset_b1610", textKey: "data_info_b1610")
            DataRow(labelKey: "dataset_mel", textKey: "data_info_mel")
            DataRow(labelKey: "dataset_weather", textKey: "data_info_wind")
            DataRow(labelKey: "next_days_title", textKey: "data_info_uou")
            DataRow(labelKey: "tab_remit", textKey: "data_info_remit")
            DataRow(labelKey: "gb_offshore_label", textKey: "data_info_agws")
        }
    }

    private var sourcesCard: some View {
        AboutCard(titleKey: "about_sources_title") {
            Text(verbatim: L10n.format("about_source_elexon", Self.currentYear))
                .font(SofiaType.bodyMedium)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
            Link(destination: AboutLinks.elexon) {
                Text("about_source_elexon_link")
                    .font(SofiaType.labelLarge)
            }
            BodyText(key: "about_source_weather")
            HStack(spacing: 16) {
                Link(destination: AboutLinks.openMeteo) {
                    Text("about_source_weather_link")
                        .font(SofiaType.labelLarge)
                }
                Link(destination: AboutLinks.ccBy) {
                    Text(verbatim: "CC BY 4.0")
                        .font(SofiaType.labelLarge)
                }
            }
        }
    }

    /// Centre approximatif du parc, sur le Dogger Bank.
    private static let farmCenter = CLLocationCoordinate2D(latitude: 54.97, longitude: 2.23)

    /// Assez large pour voir la côte nord-est de l'Angleterre.
    private static let farmRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 54.8, longitude: 0.6),
        span: MKCoordinateSpan(latitudeDelta: 4.5, longitudeDelta: 7.5)
    )

    private static var currentYear: String {
        String(Calendar(identifier: .gregorian).component(.year, from: Date()))
    }

    private static var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return L10n.format("about_version_format", version, build)
    }
}

enum AboutLinks {
    static let privacyPolicy = URL(string: "https://sofia.lemarc.fr/privacy")!
    static let elexon = URL(string: "https://bmrs.elexon.co.uk/")!
    static let openMeteo = URL(string: "https://open-meteo.com/")!
    static let ccBy = URL(string: "https://creativecommons.org/licenses/by/4.0/")!
}

/// Bouton (i) qui ouvre la feuille « À propos ».
struct AboutButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("about_open"))
    }
}

private struct AboutCard<Content: View>: View {
    let titleKey: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStringKey(titleKey))
                .font(SofiaType.titleMedium)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sofiaCard()
    }
}

private struct BodyText: View {
    let key: String

    var body: some View {
        Text(LocalizedStringKey(key))
            .font(SofiaType.bodyMedium)
            .foregroundStyle(SofiaColors.onSurfaceVariant)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct DataRow: View {
    let labelKey: String
    let textKey: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(labelKey))
                .font(SofiaType.titleSmall)
            BodyText(key: textKey)
        }
    }
}
