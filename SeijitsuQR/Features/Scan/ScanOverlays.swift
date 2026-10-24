import SwiftUI

/// Dims the camera outside the framing guide and shows the guide corners. Purely decorative.
struct ReticleOverlay: View {
    var isActive = false

    var body: some View {
        GeometryReader { proxy in
            let side = min(260, proxy.size.width * 0.66, proxy.size.height * 0.5)
            let rect = CGRect(x: (proxy.size.width - side) / 2, y: (proxy.size.height - side) / 2 - 20, width: side, height: side)
            ZStack {
                Path { path in
                    path.addRect(CGRect(origin: .zero, size: proxy.size))
                    path.addRoundedRect(in: rect, cornerSize: CGSize(width: 24, height: 24))
                }
                .fill(Color.black.opacity(0.45), style: FillStyle(eoFill: true))

                ReticleCorners()
                    .stroke(isActive ? AppColor.accentOnCamera : .white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ReticleCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let length = min(38, rect.width * 0.16)
        let radius: CGFloat = 24
        var path = Path()
        // top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + length))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(to: CGPoint(x: rect.minX + radius, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + length, y: rect.minY))
        // top-right
        path.move(to: CGPoint(x: rect.maxX - length, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY + radius), control: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + length))
        // bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - length))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - radius, y: rect.maxY), control: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - length, y: rect.maxY))
        // bottom-left
        path.move(to: CGPoint(x: rect.minX + length, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - radius), control: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - length))
        return path
    }
}

/// Small capsule with an icon and text, used for the privacy note and the scan toast.
struct NoticeCapsule: View {
    let text: String
    let systemImage: String
    var prominent = false

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(prominent ? .footnote.weight(.semibold) : .caption.weight(.medium))
            .foregroundStyle(prominent ? Color.primary : Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background {
                Capsule().fill(prominent ? AnyShapeStyle(.regularMaterial) : AnyShapeStyle(Color.black.opacity(0.45)))
            }
    }
}

/// Codes read during the current continuous-scan session.
struct ContinuousTray: View {
    let results: [ScanResult]
    let onSelect: (ScanResult) -> Void
    let onEnd: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.scanTrayTitle)
                    .font(.headline)
                Text(results.count, format: .number)
                    .font(.footnote.weight(.bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(.white.opacity(0.18)))
                Spacer()
                Button(L10n.scanTrayEnd, action: onEnd)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppColor.accentOnCamera)
                    .frame(minHeight: 44)
            }
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(results) { result in
                        Button {
                            onSelect(result)
                        } label: {
                            TrayRow(result: result, isNew: result.id == results.first?.id)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxHeight: 156)
        }
        .padding(16)
        .foregroundStyle(.white)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color.black.opacity(0.78)))
    }
}

private struct TrayRow: View {
    let result: ScanResult
    let isNew: Bool

    var body: some View {
        HStack(spacing: 12) {
            KindTile(kind: result.payload.kind, symbology: result.code.symbology, size: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(result.code.content)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text([result.payload.kind.title, result.code.symbology.title].joined(separator: L10n.metaSeparator))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            Spacer(minLength: 8)
            if isNew {
                Text(L10n.scanTrayNew)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppColor.accentOnCamera))
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.5))
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
