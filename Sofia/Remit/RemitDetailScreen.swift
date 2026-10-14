import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/remit/RemitDetailScreen.kt (barre de titre = BMU, bouton retour natif).
struct RemitDetailScreen: View {
    let notice: RemitNotice

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Spacer().frame(height: 4)

                // ── En-tête ──────────────────────────────────────────────────
                Text(notice.messageHeading.ifBlank(notice.eventType))
                    .font(SofiaType.titleLarge)
                    .fontWeight(.bold)
                FlowLayout(spacing: 8) {
                    SofiaSuggestionChip(text: notice.eventStatus)
                    SofiaSuggestionChip(text: notice.eventType)
                    if !notice.unavailabilityType.isBlank {
                        SofiaSuggestionChip(text: notice.unavailabilityType)
                    }
                    if !notice.fuelType.isBlank {
                        SofiaSuggestionChip(text: notice.fuelType)
                    }
                }

                SofiaDivider()

                // ── Capacités ────────────────────────────────────────────────
                SectionTitle(key: "remit_detail_capacities")
                DetailRow(label: L10n.string("remit_detail_normal"), value: Self.megawatts(notice.normalCapacityMw))
                DetailRow(label: L10n.string("remit_detail_available"), value: Self.megawatts(notice.availableCapacityMw))
                SofiaDivider()

                // ── Dates ────────────────────────────────────────────────────
                SectionTitle(key: "remit_detail_dates")
                DetailRow(label: L10n.string("remit_detail_start"), value: SofiaDateFormat.timestamp(notice.eventStartTime))
                DetailRow(label: L10n.string("remit_detail_end"), value: SofiaDateFormat.timestamp(notice.eventEndTime))
                DetailRow(label: L10n.string("remit_detail_published"), value: SofiaDateFormat.timestamp(notice.publishTime))

                SofiaDivider()

                // ── Actif ────────────────────────────────────────────────────
                SectionTitle(key: "remit_detail_asset_section")
                DetailRow(label: L10n.string("remit_detail_bmu"), value: notice.bmuId)
                DetailRow(label: L10n.string("remit_detail_participant"), value: notice.participantId)
                DetailRow(label: L10n.string("remit_detail_asset"), value: notice.assetId)
                DetailRow(label: L10n.string("remit_detail_revision"), value: String(notice.revisionNumber))
                DetailRow(label: L10n.string("remit_detail_mrid"), value: notice.mrid)

                // ── Cause ────────────────────────────────────────────────────
                if !notice.cause.isBlank {
                    SofiaDivider()
                    SectionTitle(key: "remit_detail_cause")
                    Text(notice.cause)
                        .font(SofiaType.bodyMedium)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                }

                // ── Informations complémentaires ─────────────────────────────
                if !notice.relatedInformation.isBlank {
                    SofiaDivider()
                    SectionTitle(key: "remit_detail_related_info")
                    Text(notice.relatedInformation)
                        .font(SofiaType.bodyMedium)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                }

                // ── Profil d'indisponibilité ─────────────────────────────────
                let profile = parseOutageProfile(notice.outageProfile)
                if !profile.isEmpty {
                    SofiaDivider()
                    SectionTitle(key: "remit_detail_outage_profile")
                    Text("remit_profile_caption")
                        .font(SofiaType.bodySmall)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                    OutageProfileChart(steps: profile, normalMw: notice.normalCapacityMw)
                }

                Spacer().frame(height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
        .foregroundStyle(SofiaColors.onSurface)
        .background(SofiaColors.background.ignoresSafeArea())
        .navigationTitle(Text(verbatim: notice.bmuId))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }

    private static func megawatts(_ value: Double?) -> String {
        guard let value else { return "—" }
        return L10n.format("mw_value_format", Int(value))
    }
}

private struct SectionTitle: View {
    let key: String

    var body: some View {
        Text(LocalizedStringKey(key))
            .font(SofiaType.labelMedium)
            .fontWeight(.semibold)
            .foregroundStyle(SofiaColors.primary)
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        WeightedRow(weights: [0.45, 0.55]) {
            Text(label)
                .font(SofiaType.bodyMedium)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(value)
                .font(SofiaType.bodyMedium)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
