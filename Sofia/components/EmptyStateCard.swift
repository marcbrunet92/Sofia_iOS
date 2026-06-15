import SwiftUI

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("🌬️")
                .font(.system(size: 48))

            Text("No production data available yet.")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            Text("Pull to refresh and try again once the API returns data.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
}