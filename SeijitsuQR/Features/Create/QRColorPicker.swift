import SwiftUI

/// "色" under a created code (docs/design/24_qr_color.svg): pattern and background swatches (Pro). A swatch that
/// would make the code hard to read with the other color is dimmed; tapping it explains why instead of choosing it.
struct QRColorPicker: View {
    @Binding var foreground: QRColor
    @Binding var background: QRColor
    let isPro: Bool
    let onLocked: () -> Void

    @State private var showsRefusal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(L10n.createColorTitle, systemImage: "paintpalette")
                    .font(.headline)
                Spacer()
                if isPro {
                    if foreground != .black || background != .white {
                        Button(L10n.createColorReset) {
                            foreground = .black
                            background = .white
                        }
                        .font(.footnote.weight(.semibold))
                    }
                } else {
                    Label(L10n.createBadgePro, systemImage: "lock.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColor.accentOnSoft)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(AppColor.accentSoft))
                }
            }
            if isPro {
                row(L10n.createColorForeground, colors: QRColorPalette.foregrounds, selection: $foreground) {
                    QRColorPalette.isReadable(foreground: $0, background: background)
                }
                row(L10n.createColorBackground, colors: QRColorPalette.backgrounds, selection: $background) {
                    QRColorPalette.isReadable(foreground: foreground, background: $0)
                }
                if showsRefusal {
                    Label(L10n.createColorRefused, systemImage: "exclamationmark.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text(L10n.createColorLockedMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button(L10n.createColorSeePro, action: onLocked)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func row(_ title: String, colors: [QRColor], selection: Binding<QRColor>, readable: @escaping (QRColor) -> Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 10) {
                ForEach(colors, id: \.self) { color in
                    let usable = readable(color)
                    Button {
                        if usable {
                            selection.wrappedValue = color
                            showsRefusal = false
                        } else {
                            showsRefusal = true
                        }
                    } label: {
                        Circle()
                            .fill(Color(color.uiColor))
                            .frame(width: 28, height: 28)
                            .overlay { Circle().strokeBorder(Color(.separator)) }
                            .overlay {
                                if !usable { Image(systemName: "line.diagonal").foregroundStyle(.secondary) }
                            }
                            .opacity(usable ? 1 : 0.3)
                            .padding(3)
                            .overlay {
                                if selection.wrappedValue == color { Circle().strokeBorder(Color.accentColor, lineWidth: 2.5) }
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.createColorSwatch(colors.firstIndex(of: color).map { $0 + 1 } ?? 0))
                    .accessibilityAddTraits(selection.wrappedValue == color ? .isSelected : [])
                }
            }
        }
    }
}
