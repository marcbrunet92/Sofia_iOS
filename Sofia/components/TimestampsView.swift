import SwiftUI

struct TimestampsView: View {
    @ObservedObject var vm: SofiaViewModel

    var body: some View {
        VStack(spacing: 10) {
            timestampRow(icon: "antenna.radiowaves.left.and.right",
                         label: "API data up to", date: vm.lastAPIUpdate)
            Divider()
            timestampRow(icon: "clock.arrow.circlepath",
                         label: "Last fetch", date: vm.lastFetch)

            HStack {
                Circle().fill(Color.green).frame(width: 6, height: 6)
                Text("Auto-refresh every 60 s")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func timestampRow(icon: String, label: String, date: Date?) -> some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.blue)
            Text(label).font(.caption).foregroundStyle(.secondary)
            Spacer()
            Text(date.map {
                $0.formatted(.dateTime.day().month(.abbreviated).hour().minute().second())
            } ?? "—")
            .font(.system(.caption, design: .monospaced))
        }
    }
}
