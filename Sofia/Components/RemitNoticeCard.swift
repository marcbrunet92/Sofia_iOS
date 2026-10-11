import Foundation
import SwiftUI
import SofiaCore

/// RemitNoticeCard.kt
struct RemitNoticeCard: View {
    let notice: RemitNotice
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading, spacing: 8) {
                Text(verbatim: "\(notice.bmuId) · \(notice.eventStatus)")
                    .font(SofiaType.titleMedium)
                    .fontWeight(.semibold)
                Text(notice.messageHeading.ifBlank(notice.eventType))
                    .font(SofiaType.bodyMedium)
                if !notice.cause.isBlank {
                    Text(L10n.format("remit_cause_format", notice.cause))
                        .font(SofiaType.bodyMedium)
                }
                SofiaDivider()
                CapacityText(label: L10n.string("remit_capacity_unavailable"), valueMw: notice.unavailableCapacityMw)
                CapacityText(label: L10n.string("remit_capacity_available"), valueMw: notice.availableCapacityMw)
                CapacityText(label: L10n.string("remit_capacity_normal"), valueMw: notice.normalCapacityMw)
                Text(L10n.format("remit_published_format", SofiaDateFormat.timestamp(notice.publishTime)))
                    .font(SofiaType.bodySmall)
                Text(L10n.format("remit_end_format", SofiaDateFormat.timestamp(notice.eventEndTime)))
                    .font(SofiaType.bodySmall)
            }
            .foregroundStyle(SofiaColors.onSurface)
            .multilineTextAlignment(.leading)
            .padding(16)
            .sofiaCard()
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(CardButtonStyle())
    }
}

/// Retour visuel au toucher d'une carte cliquable (équivalent de l'effet « ripple »).
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(SofiaColors.onSurface.opacity(configuration.isPressed ? 0.1 : 0))
            }
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
