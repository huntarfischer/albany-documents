import SwiftUI

public struct MaterialSurfaceView<Content: View>: View {
    public let recipe: MaterialResolvedRecipe
    private let scanImage: Image?
    private let content: Content

    public init(
        recipe: MaterialResolvedRecipe,
        scanImage: Image? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.recipe = recipe
        self.scanImage = scanImage
        self.content = content()
    }

    public var body: some View {
        ZStack {
            Rectangle().fill(recipe.baseTone.swiftUIColor)

            Canvas { context, size in
                drawMottledWashes(recipe.mottles, in: &context, size: size)
            }
            .blendMode(.multiply)

            if recipe.grain.enabled,
               let cgImage = MaterialGrainCache.shared.image(for: recipe.grain) {
                Rectangle()
                    .fill(
                        ImagePaint(
                            image: Image(decorative: cgImage, scale: 1, orientation: .up),
                            scale: recipe.grain.scale
                        )
                    )
                    .opacity(recipe.grain.amount)
                    .blendMode(.overlay)
            }

            Canvas { context, size in
                drawFibers(recipe.fibers, in: &context, size: size)
                drawSpots(recipe.flecks, in: &context, size: size, foxing: false)
                drawSpots(recipe.foxing, in: &context, size: size, foxing: true)
                drawThreads(recipe.clothThreads, in: &context, size: size)
            }
            .blendMode(.multiply)

            EdgeVariationLayer(recipe: recipe.edge)

            if let scanImage, recipe.scanOverlay.opacity > 0 {
                scanImage
                    .resizable()
                    .scaledToFill()
                    .scaleEffect(recipe.scanOverlay.scale)
                    .offset(
                        x: recipe.scanOverlay.offsetX,
                        y: recipe.scanOverlay.offsetY
                    )
                    .opacity(recipe.scanOverlay.opacity)
                    .blendMode(.multiply)
            }

            content
        }
        .clipped()
    }

    private func drawMottledWashes(
        _ spots: [MaterialSpot],
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        let minDimension = min(size.width, size.height)
        context.addFilter(.blur(radius: max(8, minDimension * 0.035)))

        for spot in spots {
            let radius = max(1, CGFloat(spot.radius) * minDimension)
            let aspect = 2.2 + abs(spot.tone) * 2.4
            let width = radius * aspect
            let height = radius * (0.48 + abs(spot.tone) * 0.42)
            let xOffset = CGFloat(spot.tone) * radius * 0.55
            let rect = CGRect(
                x: CGFloat(spot.x) * size.width - width / 2 + xOffset,
                y: CGFloat(spot.y) * size.height - height / 2,
                width: width,
                height: height
            )

            let color = spot.tone >= 0
                ? Color.white.opacity(spot.opacity * 0.22)
                : Color.black.opacity(spot.opacity * 0.14)

            context.fill(
                Path(roundedRect: rect, cornerRadius: height * 0.44),
                with: .color(color)
            )
        }
    }

    private func drawSpots(
        _ spots: [MaterialSpot],
        in context: inout GraphicsContext,
        size: CGSize,
        foxing: Bool
    ) {
        let minDimension = min(size.width, size.height)
        for spot in spots {
            let radius = max(0.5, CGFloat(spot.radius) * minDimension)
            let rect = CGRect(
                x: CGFloat(spot.x) * size.width - radius,
                y: CGFloat(spot.y) * size.height - radius,
                width: radius * 2,
                height: radius * 2
            )
            let color: Color
            if foxing {
                color = Color(red: 0.38, green: 0.18, blue: 0.07).opacity(spot.opacity)
            } else if spot.tone >= 0 {
                color = Color.white.opacity(spot.opacity * 0.35)
            } else {
                color = Color.black.opacity(spot.opacity * 0.28)
            }
            context.fill(Path(ellipseIn: rect), with: .color(color))
        }
    }

    private func drawFibers(
        _ fibers: [MaterialFiber],
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        for fiber in fibers {
            var path = Path()
            path.move(to: CGPoint(x: CGFloat(fiber.x1) * size.width, y: CGFloat(fiber.y1) * size.height))
            path.addLine(to: CGPoint(x: CGFloat(fiber.x2) * size.width, y: CGFloat(fiber.y2) * size.height))
            context.stroke(
                path,
                with: .color(Color.black.opacity(fiber.opacity)),
                lineWidth: max(0.25, fiber.width)
            )
        }
    }

    private func drawThreads(
        _ threads: [MaterialThread],
        in context: inout GraphicsContext,
        size: CGSize
    ) {
        for thread in threads {
            var path = Path()
            switch thread.axis {
            case .vertical:
                let x = CGFloat(thread.position) * size.width
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            case .horizontal:
                let y = CGFloat(thread.position) * size.height
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            let color = thread.tone > 0
                ? Color.white.opacity(thread.opacity * 0.55)
                : Color.black.opacity(thread.opacity)
            context.stroke(path, with: .color(color), lineWidth: max(0.25, thread.width))
        }
    }
}

private struct EdgeVariationLayer: View {
    let recipe: EdgeRecipe

    var body: some View {
        GeometryReader { proxy in
            let edgeWidth = max(1, proxy.size.width * recipe.width)
            let edgeHeight = max(1, proxy.size.height * recipe.width)

            ZStack {
                HStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.black.opacity(recipe.amount), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: edgeWidth)
                    Spacer(minLength: 0)
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(recipe.amount)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: edgeWidth)
                }

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.black.opacity(recipe.amount * 0.72), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: edgeHeight)
                    Spacer(minLength: 0)
                    LinearGradient(
                        colors: [.clear, Color.black.opacity(recipe.amount * 0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: edgeHeight)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

private extension MaterialRGBA {
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }
}
