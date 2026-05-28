import SofiaCore
import SwiftUI

struct RemitDetailView: View {
    let remit: RemitResponse

    var body: some View {
        List {
            Section("Event") {
                row("Heading",    remit.messageHeading)
                row("Type",       remit.eventType)
                row("Status",     remit.eventStatus)
                row("Fuel Type",  remit.fuelType)
            }

            Section("Asset") {
                row("BMU ID",          remit.bmuId)
                row("Participant",     remit.participantId)
                row("Asset ID",        remit.assetId)
            }

            Section("Capacity (MW)") {
                if let v = remit.normalCapacityMw      { row("Normal",      String(format: "%.1f MW", v)) }
                if let v = remit.availableCapacityMw   { row("Available",   String(format: "%.1f MW", v)) }
                if let v = remit.unavailableCapacityMw { row("Unavailable", String(format: "%.1f MW", v)) }
                if let v = remit.capacityReductionMw   { row("Reduction",   String(format: "%.1f MW", v)) }
            }

            Section("Timeline") {
                if let d = remit.eventStartTime { row("Start",     formatted(d)) }
                if let d = remit.eventEndTime   { row("End",       formatted(d)) }
                if let d = remit.publishTime    { row("Published", formatted(d)) }
                row("Revision", String(remit.revisionNumber))
            }

            if !remit.cause.isEmpty {
                Section("Cause") {
                    Text(remit.cause).font(.subheadline)
                }
            }

            if !remit.relatedInformation.isEmpty {
                Section("Related Information") {
                    Text(remit.relatedInformation).font(.subheadline)
                }
            }
        }
        .navigationTitle("REMIT #\(remit.id)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ label: String, _ value: String) -> some View {
        LabeledContent(label, value: value)
    }

    private func formatted(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }
}
