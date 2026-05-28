import SwiftUI

struct ProductionRingCard: View {
    @ObservedObject var vm: SofiaViewModel

    var body: some View {
        VStack(spacing: 20) {

            // Ring gauge
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.blue.opacity(0.12), lineWidth: 22)
                    .frame(width: 200, height: 200)

                // Progress ring
                Circle()
                    .trim(from: 0, to: vm.capacityFactor)
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .blue, .indigo],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 22, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.0), value: vm.capacityFactor)

                // Center text
                VStack(spacing: 2) {
                    Text(vm.totalMW, format: .number.precision(.fractionLength(1)))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .contentTransition(.numericText())
                    Text("MW")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text(vm.capacityFactor, format: .percent.precision(.fractionLength(1)))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }

            // Capacity label
            Text("of \(Int(vm.capacityMW)) MW capacity")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}
