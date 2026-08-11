import SwiftUI
import SofiaCore

struct RemitView: View {

    @EnvironmentObject var vm: SofiaViewModel
    @State private var selectedFilter: RemitFilter = .active

    private var filteredNotices: [RemitResponse] {
        switch selectedFilter {
        case .active:
            return vm.remitNotices.filter { $0.isCurrentlyActive || $0.eventStatus.localizedCaseInsensitiveContains("active") }
        case .historical:
            return vm.remitNotices.filter { !($0.isCurrentlyActive || $0.eventStatus.localizedCaseInsensitiveContains("active")) }
        case .all:
            return vm.remitNotices
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let errorMessage = vm.errorMessage {
                    ErrorBanner(text: errorMessage) {
                        vm.dismissError()
                    }
                    .listRowSeparator(.hidden)
                }

                Picker("Status", selection: $selectedFilter) {
                    ForEach(RemitFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowSeparator(.hidden)

                if filteredNotices.isEmpty {
                    EmptyStateCard()
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredNotices) { notice in
                        NavigationLink {
                            RemitDetailView(notice: notice)
                        } label: {
                            RemitNoticeCard(notice: notice)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .refreshable { await vm.refresh() }
            .navigationTitle("REMIT")
        }
    }
}

private enum RemitFilter: CaseIterable {
    case active
    case historical
    case all

    var title: String {
        switch self {
        case .active: return "Active"
        case .historical: return "History"
        case .all: return "All"
        }
    }
}

private struct RemitNoticeCard: View {
    let notice: RemitResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(notice.messageHeading)
                    .font(.headline)
                    .lineLimit(2)
                Spacer()
                Text(notice.eventStatus)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())
            }

            Text("\(notice.bmuId) • \(notice.eventType)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let publish = notice.publishTime {
                Text("Published: \(publish.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        notice.eventStatus.localizedCaseInsensitiveContains("active") ? .green : .orange
    }
}

private struct RemitDetailView: View {
    let notice: RemitResponse

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DefinitionCard(title: notice.messageHeading, text: notice.eventType)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Capacity")
                        .font(.headline)
                    CapacityText(label: "Normal", valueMw: notice.normalCapacityMw)
                    CapacityText(label: "Available", valueMw: notice.availableCapacityMw)
                    CapacityText(label: "Unavailable", valueMw: notice.unavailableCapacityMw)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Timeline")
                        .font(.headline)
                    Text("Start: \(remitDate(notice.eventStartTime))")
                    Text("End: \(remitDate(notice.eventEndTime))")
                    Text("Published: \(remitDate(notice.publishTime))")
                }
                .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Asset")
                        .font(.headline)
                    Text("BMU ID: \(notice.bmuId)")
                    Text("Participant: \(notice.participantId)")
                    Text("Asset ID: \(notice.assetId)")
                }
                .font(.subheadline)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Cause")
                        .font(.headline)
                    Text(notice.cause.isEmpty ? "—" : notice.cause)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Related information")
                        .font(.headline)
                    Text(notice.relatedInformation.isEmpty ? "—" : notice.relatedInformation)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Outage profile")
                        .font(.headline)
                    Text(notice.outageProfile.isEmpty ? "—" : notice.outageProfile)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle("REMIT #\(notice.id)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private func remitDate(_ date: Date?) -> String {
    guard let date else { return "—" }
    return date.formatted(date: .abbreviated, time: .shortened)
}
