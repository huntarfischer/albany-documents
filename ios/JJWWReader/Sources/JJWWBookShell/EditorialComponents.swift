import SwiftUI
import JJWWReaderCore

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

public enum JJWWEditorialPalette {
    public static let orange = Color(red: 0.91, green: 0.235, blue: 0.045)
    public static let orangeDark = Color(red: 0.67, green: 0.13, blue: 0.025)
    public static let cream = Color(red: 0.92, green: 0.88, blue: 0.78)
    public static let ink = Color(red: 0.055, green: 0.047, blue: 0.038)
    public static let navy = Color(red: 0.06, green: 0.10, blue: 0.17)
}

/// The cream architectural arch derived from the supplied cover.
public struct CreamArchFrameShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let shoulder = rect.minY + rect.height * 0.16
        let crown = rect.minY + rect.height * 0.035
        let inset = rect.width * 0.09

        path.move(to: CGPoint(x: rect.minX + inset, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + inset, y: shoulder))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: crown),
            control1: CGPoint(x: rect.minX + inset, y: rect.minY + rect.height * 0.08),
            control2: CGPoint(x: rect.midX - rect.width * 0.18, y: crown)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX - inset, y: shoulder),
            control1: CGPoint(x: rect.midX + rect.width * 0.18, y: crown),
            control2: CGPoint(x: rect.maxX - inset, y: rect.minY + rect.height * 0.08)
        )
        path.addLine(to: CGPoint(x: rect.maxX - inset, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// Procedural orange cloth used for binding and progress UI. It is intentionally
/// graphic rather than a fake photographic texture, so a real scan can replace it later.
public struct OrangeClothField: View {
    public let seed: UInt64

    public init(seed: UInt64 = 1827) {
        self.seed = seed
    }

    public var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(JJWWEditorialPalette.orange))

            var rng = EditorialSplitMix64(seed: seed)
            let verticalCount = max(6, Int(size.width / 4))
            for index in 0...verticalCount {
                let x = size.width * CGFloat(index) / CGFloat(max(1, verticalCount))
                let alpha = 0.07 + rng.unit() * 0.10
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + CGFloat((rng.unit() - 0.5) * 1.2), y: size.height))
                context.stroke(path, with: .color(JJWWEditorialPalette.orangeDark.opacity(alpha)), lineWidth: 0.7)
            }

            let horizontalCount = max(8, Int(size.height / 5))
            for index in 0...horizontalCount {
                let y = size.height * CGFloat(index) / CGFloat(max(1, horizontalCount))
                let alpha = 0.04 + rng.unit() * 0.07
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y + CGFloat((rng.unit() - 0.5) * 0.8)))
                context.stroke(path, with: .color(Color.white.opacity(alpha)), lineWidth: 0.45)
            }
        }
        .accessibilityHidden(true)
    }
}

public struct CutPaperLabel: View {
    public let text: String
    public let rotationDegrees: Double

    public init(_ text: String, rotationDegrees: Double = 0) {
        self.text = text
        self.rotationDegrees = rotationDegrees
    }

    public var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .black, design: .serif))
            .tracking(0.7)
            .foregroundStyle(JJWWEditorialPalette.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(JJWWEditorialPalette.cream)
            .overlay(Rectangle().stroke(Color.black.opacity(0.12), lineWidth: 0.5))
            .rotationEffect(.degrees(rotationDegrees))
            .accessibilityLabel(Text(text))
    }
}

public struct ProgressSpineMilestone: Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let normalizedPosition: Double

    public init(id: String, label: String, normalizedPosition: Double) {
        self.id = id
        self.label = label
        self.normalizedPosition = normalizedPosition
    }
}

public struct ProgressSpineModel: Equatable, Sendable {
    public let milestones: [ProgressSpineMilestone]
    private let orderedLineNumbers: [Int]

    public init(edition: Edition) {
        let units = edition.orderedReadingUnits.filter { $0.kind != .cover }
        let lines = units.flatMap(\.blocks).flatMap(\.lines).map(\.number)
        self.orderedLineNumbers = lines

        self.milestones = units.compactMap { unit in
            guard let index = lines.firstIndex(of: unit.canonicalAnchor.startLine) else { return nil }
            let denominator = max(1, lines.count - 1)
            let position = Double(index) / Double(denominator)
            return ProgressSpineMilestone(
                id: unit.id,
                label: unit.sourcePresentation?.displayTitle ?? unit.id,
                normalizedPosition: min(1, max(0, position))
            )
        }
    }

    public func progress(for location: ReaderLocation) -> Double {
        guard !orderedLineNumbers.isEmpty else { return 0 }
        guard let index = orderedLineNumbers.firstIndex(of: location.canonicalLine) else {
            return location.canonicalLine <= (orderedLineNumbers.first ?? 0) ? 0 : 1
        }
        if orderedLineNumbers.count == 1 { return 1 }
        return Double(index) / Double(orderedLineNumbers.count - 1)
    }
}

public struct ClothProgressSpine: View {
    public let model: ProgressSpineModel
    public let progress: Double

    public init(model: ProgressSpineModel, progress: Double) {
        self.model = model
        self.progress = min(1, max(0, progress))
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                OrangeClothField(seed: 0x4A4A5757)

                Rectangle()
                    .fill(JJWWEditorialPalette.cream.opacity(0.46))
                    .frame(width: 1)
                    .padding(.vertical, 9)

                Rectangle()
                    .fill(JJWWEditorialPalette.cream.opacity(0.92))
                    .frame(width: 3, height: max(3, geometry.size.height * progress))
                    .frame(maxHeight: .infinity, alignment: .top)

                ForEach(model.milestones) { milestone in
                    Circle()
                        .fill(JJWWEditorialPalette.cream)
                        .overlay(Circle().stroke(JJWWEditorialPalette.ink.opacity(0.32), lineWidth: 0.5))
                        .frame(width: 7, height: 7)
                        .position(
                            x: geometry.size.width / 2,
                            y: max(8, min(geometry.size.height - 8, geometry.size.height * milestone.normalizedPosition))
                        )
                        .accessibilityLabel(Text(milestone.label))
                        .accessibilityValue(Text("\(Int((milestone.normalizedPosition * 100).rounded())) percent"))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.24), lineWidth: 0.5))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("Reading progress"))
        .accessibilityValue(Text("\(Int((progress * 100).rounded())) percent"))
    }
}

public struct EditorialAssetImage: View {
    public let asset: ResolvedEditorialAsset
    public let contentMode: ContentMode

    public init(asset: ResolvedEditorialAsset, contentMode: ContentMode = .fit) {
        self.asset = asset
        self.contentMode = contentMode
    }

    @ViewBuilder
    public var body: some View {
        if let url = asset.resourceURL {
            #if canImport(UIKit)
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .accessibilityLabel(Text(accessibilityText))
            } else {
                missing
            }
            #elseif canImport(AppKit)
            if let image = NSImage(contentsOf: url) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .accessibilityLabel(Text(accessibilityText))
            } else {
                missing
            }
            #else
            missing
            #endif
        } else {
            missing
        }
    }

    private var accessibilityText: String {
        asset.descriptor.altText.isEmpty ? asset.descriptor.title : asset.descriptor.altText
    }

    private var missing: some View {
        ZStack {
            JJWWEditorialPalette.cream
            VStack(spacing: 8) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 28, weight: .medium))
                Text(asset.descriptor.title)
                    .font(.system(size: 13, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                Text(asset.descriptor.filename)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .opacity(0.58)
            }
            .foregroundStyle(JJWWEditorialPalette.ink)
            .padding(18)
        }
        .overlay(Rectangle().strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4])).opacity(0.24))
        .accessibilityLabel(Text("Missing asset: \(accessibilityText)"))
    }
}

public struct EditorialGalleryView: View {
    public let store: EditorialGalleryStore

    public init(store: EditorialGalleryStore) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                ForEach(store.assets) { asset in
                    VStack(alignment: .leading, spacing: 7) {
                        EditorialAssetImage(asset: asset, contentMode: .fill)
                            .frame(height: 170)
                            .clipped()

                        Text(asset.descriptor.title)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Text(asset.descriptor.role.rawValue.uppercased())
                            Spacer(minLength: 4)
                            Text(statusText(asset))
                        }
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                        .foregroundStyle(JJWWEditorialPalette.ink.opacity(0.58))
                    }
                    .padding(8)
                    .background(JJWWEditorialPalette.cream.opacity(0.94))
                    .overlay(Rectangle().stroke(Color.black.opacity(0.10), lineWidth: 0.5))
                }
            }
            .padding(16)
        }
        .background(JJWWEditorialPalette.ink)
        .navigationTitle("Editorial Gallery")
    }

    private func statusText(_ asset: ResolvedEditorialAsset) -> String {
        if !asset.isAvailable { return "MISSING" }
        if let placement = asset.descriptor.placement {
            return "L\(placement.canonicalLine) \(placement.edge.rawValue.uppercased())"
        }
        return asset.discoveredAutomatically ? "NEW · UNPLACED" : "UNPLACED"
    }
}

private struct EditorialSplitMix64 {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
