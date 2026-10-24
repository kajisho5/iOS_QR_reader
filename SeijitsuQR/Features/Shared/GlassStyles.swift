import SwiftUI

/// Full-width filled button for the primary action of a screen.
/// iPad pointer: lift effect (small element with an opaque background, HIG Pointing devices).
struct PrimaryButtonStyle: ButtonStyle {
    /// false: as wide as its label (used for bottom buttons on regular width, which must not
    /// stretch across iPhone Duo's fold).
    var fillsWidth = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: 52)
            .padding(.horizontal, fillsWidth ? 16 : 28)
            .background(AppColor.accentFill.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 14, style: .continuous))
            .hoverEffect(.lift)
    }
}

/// Secondary action tile (icon over label) used in result screens. iPad pointer: highlight effect.
struct ActionTileStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.footnote.weight(.semibold))
            .frame(maxWidth: .infinity, minHeight: 66)
            .padding(.horizontal, 6)
            .background(Color(.secondarySystemGroupedBackground).opacity(configuration.isPressed ? 0.7 : 1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: 14, style: .continuous))
            .hoverEffect(.highlight)
    }
}
