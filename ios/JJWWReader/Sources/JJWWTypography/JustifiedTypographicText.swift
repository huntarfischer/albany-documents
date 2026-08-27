import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Platform text layout for the historical source families that genuinely use
/// full justification. The canonical string remains semantic text; justification
/// and hyphenation are layout instructions only.
public struct JustifiedTypographicText: View {
    private let text: String
    private let token: TypographyToken
    private let pointScale: Double
    private let trackingDelta: Double
    private let lineSpacingMultiplier: Double

    public init(
        _ text: String,
        token: TypographyToken,
        pointScale: Double = 1,
        trackingDelta: Double = 0,
        lineSpacingMultiplier: Double = 1
    ) {
        self.text = text
        self.token = token
        self.pointScale = pointScale
        self.trackingDelta = trackingDelta
        self.lineSpacingMultiplier = lineSpacingMultiplier
    }

    @ViewBuilder
    public var body: some View {
        #if canImport(UIKit)
        UIKitJustifiedText(
            text: token.uppercase ? text.uppercased() : text,
            token: token,
            pointScale: pointScale,
            trackingDelta: trackingDelta,
            lineSpacingMultiplier: lineSpacingMultiplier
        )
        #elseif canImport(AppKit)
        AppKitJustifiedText(
            text: token.uppercase ? text.uppercased() : text,
            token: token,
            pointScale: pointScale,
            trackingDelta: trackingDelta,
            lineSpacingMultiplier: lineSpacingMultiplier
        )
        #else
        Text(token.uppercase ? text.uppercased() : text)
            .font(token.font)
        #endif
    }
}

#if canImport(UIKit)
private struct UIKitJustifiedText: UIViewRepresentable {
    let text: String
    let token: TypographyToken
    let pointScale: Double
    let trackingDelta: Double
    let lineSpacingMultiplier: Double

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.isAccessibilityElement = true
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.attributedText = attributedString
        uiView.accessibilityLabel = text
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: UITextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let fitted = uiView.sizeThatFits(
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )
        return CGSize(width: width, height: ceil(fitted.height))
    }

    private var attributedString: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .justified
        paragraph.hyphenationFactor = Float(token.hyphenationFactor)
        paragraph.lineSpacing = CGFloat(token.lineSpacing * lineSpacingMultiplier)

        return NSAttributedString(
            string: text,
            attributes: [
                .font: platformFont,
                .foregroundColor: UIColor.label.withAlphaComponent(0.84),
                .kern: CGFloat(token.tracking + trackingDelta),
                .paragraphStyle: paragraph
            ]
        )
    }

    private var platformFont: UIFont {
        let size = basePointSize(for: token.textStyle) * CGFloat(max(0.75, pointScale))
        let weight: UIFont.Weight
        switch token.weight {
        case .regular: weight = .regular
        case .medium: weight = .medium
        case .semibold: weight = .semibold
        case .bold: weight = .bold
        case .black: weight = .black
        }
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        let design: UIFontDescriptor.SystemDesign
        switch token.design {
        case .serif: design = .serif
        case .rounded: design = .rounded
        case .monospaced: design = .monospaced
        case .system: design = .default
        }
        guard let descriptor = base.fontDescriptor.withDesign(design) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
#endif

#if canImport(AppKit)
private struct AppKitJustifiedText: NSViewRepresentable {
    let text: String
    let token: TypographyToken
    let pointScale: Double
    let trackingDelta: Double
    let lineSpacingMultiplier: Double

    func makeNSView(context: Context) -> NSTextView {
        let view = NSTextView()
        view.drawsBackground = false
        view.isEditable = false
        view.isSelectable = true
        view.textContainerInset = .zero
        view.textContainer?.lineFragmentPadding = 0
        view.isVerticallyResizable = true
        view.isHorizontallyResizable = false
        view.textContainer?.widthTracksTextView = true
        return view
    }

    func updateNSView(_ nsView: NSTextView, context: Context) {
        nsView.textStorage?.setAttributedString(attributedString)
        nsView.setAccessibilityLabel(text)
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        nsView: NSTextView,
        context: Context
    ) -> CGSize? {
        guard let width = proposal.width, width > 0,
              let container = nsView.textContainer,
              let manager = nsView.layoutManager else { return nil }
        container.containerSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        container.widthTracksTextView = false
        manager.ensureLayout(for: container)
        let used = manager.usedRect(for: container)
        return CGSize(width: width, height: ceil(used.height))
    }

    private var attributedString: NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .justified
        paragraph.hyphenationFactor = Float(token.hyphenationFactor)
        paragraph.lineSpacing = CGFloat(token.lineSpacing * lineSpacingMultiplier)

        return NSAttributedString(
            string: text,
            attributes: [
                .font: platformFont,
                .foregroundColor: NSColor.labelColor.withAlphaComponent(0.84),
                .kern: CGFloat(token.tracking + trackingDelta),
                .paragraphStyle: paragraph
            ]
        )
    }

    private var platformFont: NSFont {
        let size = basePointSize(for: token.textStyle) * CGFloat(max(0.75, pointScale))
        if token.design == .serif {
            let name: String
            switch token.weight {
            case .bold, .black, .semibold: name = "Times New Roman Bold"
            default: name = "Times New Roman"
            }
            return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
        }
        let weight: NSFont.Weight
        switch token.weight {
        case .regular: weight = .regular
        case .medium: weight = .medium
        case .semibold: weight = .semibold
        case .bold: weight = .bold
        case .black: weight = .black
        }
        return NSFont.systemFont(ofSize: size, weight: weight)
    }
}
#endif

private func basePointSize(for style: TypographyDynamicTextStyle) -> CGFloat {
    switch style {
    case .largeTitle: return 34
    case .title: return 28
    case .title2: return 22
    case .title3: return 20
    case .headline: return 17
    case .body: return 17
    case .callout: return 16
    case .subheadline: return 15
    case .footnote: return 13
    }
}
