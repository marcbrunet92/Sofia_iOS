import SwiftUI

struct TabItem {
    let labelKey: String
    let systemImage: String
}

/// FloatingTabBar.kt : barre d'onglets flottante, pilule translucide posée au-dessus du contenu,
/// qui défile dessous.
struct FloatingTabBar: View {
    let items: [TabItem]
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                let item = items[index]
                let selected = index == selectedIndex
                Button {
                    onSelect(index)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                        Text(LocalizedStringKey(item.labelKey))
                            .font(SofiaType.labelLarge)
                            .fontWeight(selected ? .semibold : .medium)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .foregroundStyle(selected ? SofiaColors.primary : SofiaColors.onSurfaceVariant)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(selected ? SofiaColors.primary.opacity(0.16) : Color.clear, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .background(SofiaColors.surfaceContainerHigh.opacity(0.88), in: Capsule())
        .overlay {
            Capsule().strokeBorder(SofiaColors.onSurface.opacity(0.10), lineWidth: 0.5)
        }
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
    }
}
