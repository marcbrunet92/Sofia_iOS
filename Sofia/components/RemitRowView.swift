import SwiftUI
import SofiaCore

struct RemitRowView: View {
    let remit: RemitResponse

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Status dot
            Circle()
                .fill(remit.isCurrentlyActive ? .orange : .secondary)
                .frame(width: 10, height: 10)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(remit.messageHeading)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(2)
                    Spacer()
                    statusBadge
                }

                Text(remit.bmuId)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let start = remit.eventStartTime {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(eventWindow(start: start, end: remit.eventEndTime))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                if let available = remit.availableCapacityMw {
                    Label("\(Int(available)) MW available", systemImage: "arrow.down.circle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusBadge: some View {
        Text(remit.eventStatus)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15), in: Capsule())
            .foregroundStyle(badgeColor)
    }

    private var badgeColor: Color {
        switch remit.eventStatus.lowercased() {
        case "active":    return .orange
        case "dismissed": return .secondary
        default:          return .blue
        }
    }

    private func eventWindow(start: Date, end: Date?) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        let startStr = fmt.string(from: start)
        let endStr = end.map { fmt.string(from: $0) } ?? "ongoing"
        return "\(startStr) → \(endStr)"
    }
}
