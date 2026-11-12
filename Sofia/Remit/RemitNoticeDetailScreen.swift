import Foundation
import SwiftUI
import SofiaCore

/// Avis REMIT complet d'une unité : statut, capacités, dates, identifiants, cause et profil.
/// Ouvert depuis le détail d'une alerte (barre de titre = BMU, bouton retour natif).
struct RemitNoticeDetailScreen: View {
    let notice: RemitNotice

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Spacer().frame(height: 4)

                // ── En-tête ──────────────────────────────────────────────────
                Text(verbatim: notice.messageHeading.ifBlank(notice.eventType))
                    .font(SofiaType.titleLarge)
                    .fontWeight(.bold)
                FlowLayout(spacing: 8) {
                    if !notice.eventStatus.isBlank {
                        SofiaSuggestionChip(text: notice.eventStatus)
                    }
                    if !notice.eventType.isBlank {
                        SofiaSuggestionChip(text: notice.eventType)
                    }
                    if !notice.unavailabilityType.isBlank {
                        SofiaSuggestionChip(text: notice.unavailabilityType)
                    }
                    if !notice.fuelType.isBlank {
                        SofiaSuggestionChip(text: notice.fuelType)
                    }
                }

                SofiaDivider()

                // ── Capacités ────────────────────────────────────────────────
                NoticeSectionTitle(key: "remit_detail_capacities")
                NoticeRow(label: L10n.string("remit_detail_normal"), value: Self.megawatts(notice.normalCapacityMw))
                NoticeRow(label: L10n.string("remit_capacity_available"), value: Self.megawatts(notice.effectiveAvailableMw))
                NoticeRow(label: L10n.string("remit_capacity_unavailable"), value: Self.megawatts(notice.unavailableCapacityMw))

                SofiaDivider()

                // ── Dates ────────────────────────────────────────────────────
                NoticeSectionTitle(key: "remit_detail_dates")
                NoticeRow(label: L10n.string("remit_detail_start"), value: SofiaDateFormat.timestamp(notice.eventStartTime))
                NoticeRow(label: L10n.string("remit_detail_end"), value: SofiaDateFormat.timestamp(notice.eventEndTime))
                NoticeRow(label: L10n.string("remit_detail_published"), value: SofiaDateFormat.timestamp(notice.publishTime))

                SofiaDivider()

                // ── Actif ────────────────────────────────────────────────────
                NoticeSectionTitle(key: "remit_detail_asset_section")
                NoticeRow(label: L10n.string("remit_detail_bmu"), value: notice.bmuId)
                NoticeRow(label: L10n.string("remit_detail_participant"), value: notice.participantId.ifBlank("—"))
                NoticeRow(label: L10n.string("remit_detail_asset"), value: notice.assetId.ifBlank("—"))
                NoticeRow(label: L10n.string("remit_detail_revision"), value: String(notice.revisionNumber))
                NoticeRow(label: L10n.string("remit_detail_mrid"), value: notice.mrid.ifBlank("—"))

                // ── Cause ────────────────────────────────────────────────────
                if !notice.cause.isBlank {
                    SofiaDivider()
                    NoticeSectionTitle(key: "remit_detail_cause")
                    Text(verbatim: notice.cause)
                        .font(SofiaType.bodyMedium)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                }

                // ── Informations complémentaires ─────────────────────────────
                if !notice.relatedInformation.isBlank {
                    SofiaDivider()
                    NoticeSectionTitle(key: "remit_detail_related_info")
                    Text(verbatim: notice.relatedInformation)
                        .font(SofiaType.bodyMedium)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                }

                NoticeProfileSection(notice: notice)

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
        return L10n.format("mw_value_format", Int(value.rounded()))
    }
}

/// Profil d'indisponibilité de l'avis, s'il en a un.
private struct NoticeProfileSection: View {
    let notice: RemitNotice

    var body: some View {
        let profile = parseOutageProfile(notice.outageProfile)
        if !profile.isEmpty {
            SofiaDivider()
            NoticeSectionTitle(key: "remit_detail_outage_profile")
            Text("remit_profile_caption")
                .font(SofiaType.bodySmall)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
            OutageProfileChart(steps: profile, normalMw: notice.normalCapacityMw)
        }
    }
}

private struct NoticeSectionTitle: View {
    let key: String

    var body: some View {
        Text(LocalizedStringKey(key))
            .font(SofiaType.labelMedium)
            .fontWeight(.semibold)
            .foregroundStyle(SofiaColors.primary)
    }
}

private struct NoticeRow: View {
    let label: String
    let value: String

    var body: some View {
        WeightedRow(weights: [0.45, 0.55]) {
            Text(verbatim: label)
                .font(SofiaType.bodyMedium)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: value)
                .font(SofiaType.bodyMedium)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
    }
}
