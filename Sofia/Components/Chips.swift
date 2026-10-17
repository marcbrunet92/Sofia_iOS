import SwiftUI

/// `FilterChip` Material 3 : contour quand il n'est pas sélectionné, fond secondaryContainer sinon.
struct SofiaFilterChip: View {
    let label: String
    let selected: Bool
    /// Petit carré de couleur affiché en tête (leadingIcon des jeux de données).
    var leadingColor: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let leadingColor {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(leadingColor)
                        .frame(width: 12, height: 12)
                        .frame(width: 18, height: 18)
                }
                Text(label)
                    .font(SofiaType.labelLarge)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.leading, leadingColor == nil ? 16 : 8)
            .padding(.trailing, 16)
            .frame(height: 32)
            .foregroundStyle(selected ? SofiaColors.onSecondaryContainer : SofiaColors.onSurfaceVariant)
            .background(
                selected ? SofiaColors.secondaryContainer : Color.clear,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .overlay {
                if !selected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(SofiaColors.outlineVariant, lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
