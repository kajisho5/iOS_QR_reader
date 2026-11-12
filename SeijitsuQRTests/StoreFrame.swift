import SwiftUI
import UIKit

/// An App Store screenshot: a headline and its supporting line above a captured screen in a device outline,
/// on the app icon's green gradient (docs/design/appstore/SCREENSHOTS.md §4). Used only by the screenshot test.
struct StoreFrame: View {
    enum Device {
        case iphone, ipad
    }

    let headline: String
    let subline: String
    let screen: UIImage
    let device: Device
    /// The frame's size in points: the simulator's screen (440x956 on the 6.9" iPhone, 1032x1376 on the 13" iPad).
    let size: CGSize

    /// Sizes in points on the design canvas (SCREENSHOTS.md §4), scaled to `size.width`.
    private struct Metrics {
        let canvasWidth: CGFloat
        let screenWidth: CGFloat
        let screenTop: CGFloat
        let cornerRadius: CGFloat
        let bezel: CGFloat
        let island: CGSize?
        let islandTop: CGFloat
        let headlineSize: CGFloat
        let headlineLineSpacing: CGFloat
        let sublineSize: CGFloat
        let sublineLineSpacing: CGFloat
        let textTop: CGFloat
        let textGap: CGFloat
        let sideMargin: CGFloat
    }

    private var metrics: Metrics {
        switch device {
        case .iphone:
            Metrics(canvasWidth: 440, screenWidth: 318, screenTop: 240, cornerRadius: 45, bezel: 8,
                    island: CGSize(width: 91, height: 27), islandTop: 8,
                    headlineSize: 34, headlineLineSpacing: 2, sublineSize: 15.5, sublineLineSpacing: 2,
                    textTop: 58, textGap: 14, sideMargin: 20)
        case .ipad:
            Metrics(canvasWidth: 1032, screenWidth: 836, screenTop: 214, cornerRadius: 15, bezel: 14,
                    island: nil, islandTop: 0,
                    headlineSize: 52, headlineLineSpacing: 4, sublineSize: 24, sublineLineSpacing: 4,
                    textTop: 64, textGap: 16, sideMargin: 40)
        }
    }

    var body: some View {
        let m = metrics
        let k = size.width / m.canvasWidth
        let screenWidth = m.screenWidth * k
        let screenHeight = screenWidth * screen.size.height / max(screen.size.width, 1)
        let radius = m.cornerRadius * k
        let bezel = m.bezel * k

        ZStack(alignment: .top) {
            LinearGradient(colors: [Self.top, Self.bottom], startPoint: .top, endPoint: .bottom)

            VStack(spacing: m.textGap * k) {
                Text(headline)
                    .font(.system(size: m.headlineSize * k, weight: .heavy))
                    .lineSpacing(m.headlineLineSpacing * k)
                Text(subline)
                    .font(.system(size: m.sublineSize * k, weight: .medium))
                    .lineSpacing(m.sublineLineSpacing * k)
                    .opacity(0.88)
            }
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, m.sideMargin * k)
            .padding(.top, m.textTop * k)

            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: radius + bezel, style: .continuous)
                    .fill(Self.bezelFill)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius + bezel - 1.5 * k, style: .continuous)
                            .strokeBorder(Self.bezelEdge, lineWidth: 1.5 * k)
                    }
                    .shadow(color: Self.shadow.opacity(0.45), radius: m.canvasWidth * 0.03 * k, y: m.canvasWidth * 0.02 * k)
                Image(uiImage: screen)
                    .resizable()
                    .frame(width: screenWidth, height: screenHeight)
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .padding(bezel)
                if let island = m.island {
                    Capsule()
                        .fill(.black)
                        .frame(width: island.width * k, height: island.height * k)
                        .padding(.top, bezel + m.islandTop * k)
                }
            }
            .frame(width: screenWidth + 2 * bezel, height: screenHeight + 2 * bezel)
            .padding(.top, m.screenTop * k - bezel)
        }
        .frame(width: size.width, height: size.height)
        .ignoresSafeArea()
        .environment(\.colorScheme, .light)
    }

    // The app icon's gradient, also used by the App Store video (docs/design/appstore/VIDEO.md).
    private static let top = Color(red: 0x16 / 255, green: 0xA3 / 255, blue: 0x86 / 255)
    private static let bottom = Color(red: 0x0A / 255, green: 0x5F / 255, blue: 0x4E / 255)
    private static let bezelFill = Color(red: 0x10 / 255, green: 0x13 / 255, blue: 0x12 / 255)
    private static let bezelEdge = Color(red: 0x3A / 255, green: 0x3F / 255, blue: 0x3D / 255)
    private static let shadow = Color(red: 0x00 / 255, green: 0x2A / 255, blue: 0x20 / 255)
}
