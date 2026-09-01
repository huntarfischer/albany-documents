import Foundation
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// TextKit-backed rendering for justified historical matter using the exact
/// attributes pagination measures. This removes the former system-serif proxy.
public struct ResolvedJustifiedTypographicText: View {
    private let text: String
    private let resolved: ResolvedReaderTypography
    private let snapshotLayoutWidth: Double?

    public init(
        _ text: String,
        resolved: ResolvedReaderTypography,
        snapshotLayoutWidth: Double? = nil
    ) {
        self.text = text
        self.resolved = resolved
        self.snapshotLayoutWidth = snapshotLayoutWidth
    }

    @ViewBuilder
    public var body: some View {
        #if canImport(UIKit)
        UIKitResolvedText(text: text, resolved: resolved)
        #elseif canImport(AppKit)
        if let snapshotLayoutWidth, snapshotLayoutWidth > 1 {
            AppKitResolvedRasterizedText(
                text: text,
                resolved: resolved,
                width: CGFloat(snapshotLayoutWidth)
            )
        } else {
            AppKitResolvedText(text: text, resolved: resolved)
        }
        #else
        Text(text).font(resolved.swiftUIFont)
        #endif
    }
}

#if canImport(UIKit)
private struct UIKitResolvedText: UIViewRepresentable {
    let text: String
    let resolved: ResolvedReaderTypography

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.backgroundColor = .clear
        view.isEditable = false
        view.isSelectable = true
        view.isScrollEnabled = false
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.adjustsFontForContentSizeCategory = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.isAccessibilityElement = true
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        var attributes = resolved.renderingAttributedStringAttributes
        attributes[.foregroundColor] = UIColor.label.withAlphaComponent(0.90)
        uiView.attributedText = NSAttributedString(string: text, attributes: attributes)
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
}
#endif

#if canImport(AppKit)
private struct AppKitResolvedRasterizedText: View {
    let image: NSImage
    let size: CGSize

    init(text: String, resolved: ResolvedReaderTypography, width: CGFloat) {
        let storage = NSTextStorage(
            attributedString: attributedString(text: text, resolved: resolved)
        )
        let manager = NSLayoutManager()
        manager.usesFontLeading = true
        let container = NSTextContainer(
            size: CGSize(width: max(1, width), height: CGFloat.greatestFiniteMagnitude)
        )
        container.lineFragmentPadding = 0
        storage.addLayoutManager(manager)
        manager.addTextContainer(container)
        manager.ensureLayout(for: container)

        let glyphRange = manager.glyphRange(for: container)
        let used = manager.usedRect(for: container)
        let measured = CGSize(width: max(1, width), height: max(1, ceil(used.maxY)))
        let image = NSImage(size: measured)
        image.lockFocusFlipped(true)
        manager.drawBackground(forGlyphRange: glyphRange, at: .zero)
        manager.drawGlyphs(forGlyphRange: glyphRange, at: .zero)
        image.unlockFocus()

        self.image = image
        self.size = measured
    }

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .interpolation(.high)
            .frame(width: size.width, height: size.height)
            .fixedSize()
            .accessibilityHidden(true)
    }
}

private struct AppKitResolvedText: NSViewRepresentable {
    let text: String
    let resolved: ResolvedReaderTypography

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
        nsView.textStorage?.setAttributedString(
            attributedString(text: text, resolved: resolved)
        )
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
        container.containerSize = CGSize(
            width: width,
            height: CGFloat.greatestFiniteMagnitude
        )
        container.widthTracksTextView = false
        manager.ensureLayout(for: container)
        let used = manager.usedRect(for: container)
        return CGSize(width: width, height: ceil(used.height))
    }
}

private func attributedString(
    text: String,
    resolved: ResolvedReaderTypography
) -> NSAttributedString {
    var attributes = resolved.renderingAttributedStringAttributes
    attributes[.foregroundColor] = NSColor.labelColor.withAlphaComponent(0.90)
    return NSAttributedString(string: text, attributes: attributes)
}
#endif
