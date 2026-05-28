import SwiftUI
import SofiaCore

struct RecordsCardView: View {

    let windows: PnTopProductionWindows?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack {
                Label("Production Records", systemImage: "trophy.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if isLoading {
                    ProgressView().scaleEffect(0.75)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()

            // Rows
            if let w = windows {
                VStack(spacing: 0) {
                    RecordRow(label: "All time",   point: w.allTime,    accent: .yellow)
                    Divider().padding(.leading, 16)
                    RecordRow(label: "Last 90 d",  point: w.last90Days, accent: .orange)
                    Divider().padding(.leading, 16)
                    RecordRow(label: "Last 30 d",  point: w.last30Days, accent: .blue)
                    Divider().padding(.leading, 16)
                    RecordRow(label: "Last 7 d",   point: w.last7Days,  accent: .green)
                }
            } else if !isLoading {
                Text("No data available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                Color.clear.frame(height: 80)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Single row

private struct RecordRow: View {

    let label: String
    let point: PnTopProductionPoint
    let accent: Color

    private var dateText: String {
        guard let d = point.maxDate else { return "–" }
        return d.formatted(.dateTime.day().month(.abbreviated).year().hour().minute())
    }

    var body: some View {
        HStack(spacing: 12) {

            // Accent dot
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)

            // Label
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            Spacer()

            // Value
            VStack(alignment: .trailing, spacing: 2) {
                Text(point.maxMw.formatted(.number.precision(.fractionLength(0))) + " MW")
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.primary)

                Text(dateText)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Preview

#Preview {
    let pt = { (mw: Double, iso: String) in
        PnTopProductionPoint(
            maxMw: mw,
            maxDate: ISO8601DateFormatter().date(from: iso)
        )
    }
    let windows = PnTopProductionWindows(
        allTime:    pt(1398, "2026-04-12T14:00:00Z"),
        last7Days:  pt(1201, "2026-05-22T09:30:00Z"),
        last30Days: pt(1350, "2026-05-01T11:00:00Z"),
        last90Days: pt(1390, "2026-04-15T16:00:00Z")
    )
    return RecordsCardView(windows: windows, isLoading: false)
        .padding()
        .background(Color(.systemGroupedBackground))
}
