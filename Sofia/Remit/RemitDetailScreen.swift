import Foundation
import SwiftUI
import SofiaCore

/// Équivalent de ui/remit/RemitDetailScreen.kt : détail d'une alerte (bouton retour natif).
struct RemitDetailScreen: View {
    let group: RemitGroup

    var body: some View {
        let profile = group.outageProfile()
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    if let type = AlertFormat.typeLabel(group) {
                        Text(verbatim: type)
                            .font(SofiaType.labelLarge)
                            .fontWeight(.bold)
                            .foregroundStyle(AlertFormat.typeColor(group))
                    }
                    Text(verbatim: group.title)
                        .font(SofiaType.headlineSmall)
                        .fontWeight(.bold)
                    Text(verbatim: AlertFormat.scopeText(group))
                        .font(SofiaType.bodyLarge)
                        .foregroundStyle(SofiaColors.onSurfaceVariant)
                }

                DetailCard {
                    DetailRow(
                        label: L10n.string("remit_detail_available"),
                        value: AlertFormat.availabilityText(available: group.availableMw, normal: group.normalMw)
                    )
                    DetailRow(
                        label: L10n.string("remit_detail_start"),
                        value: group.start.map { AlertFormat.alertDate($0) } ?? "—"
                    )
                    DetailRow(
                        label: L10n.string("remit_detail_end"),
                        value: group.end.map { AlertFormat.alertDate($0) } ?? L10n.string("remit_no_end")
                    )
                }

                if group.notices.count > 1 {
                    DetailCard {
                        ForEach(group.notices) { notice in
                            DetailRow(
                                label: L10n.format("remit_unit_format", unitNumber(notice.bmuId)),
                                value: AlertFormat.availabilityText(
                                    available: notice.effectiveAvailableMw,
                                    normal: notice.normalCapacityMw
                                )
                            )
                        }
                    }
                }

                if !profile.isEmpty {
                    DetailCard {
                        Text("remit_profile_caption")
                            .font(SofiaType.titleSmall)
                        OutageProfileChart(steps: profile, normalMw: group.normalMw)
                    }
                }

                let info = group.first.relatedInformation
                if !info.isBlank {
                    DetailCard {
                        Text("remit_detail_related_info")
                            .font(SofiaType.titleSmall)
                        Text(verbatim: info)
                            .font(SofiaType.bodyMedium)
                            .foregroundStyle(SofiaColors.onSurfaceVariant)
                    }
                }

                Spacer().frame(height: 16)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        }
        .foregroundStyle(SofiaColors.onSurface)
        .background(SofiaColors.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
    }
}

private struct DetailCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .sofiaCard()
    }
}

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(verbatim: label)
                .font(SofiaType.bodyMedium)
                .foregroundStyle(SofiaColors.onSurfaceVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(verbatim: value)
                .font(SofiaType.bodyMedium)
                .fontWeight(.medium)
                .layoutPriority(1)
        }
    }
}
