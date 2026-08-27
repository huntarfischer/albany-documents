import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader
import JJWWPagesReader

@MainActor
public struct JJWWBookView: View {
    @StateObject private var session: BookShellSession

    public init(session: BookShellSession) {
        _session = StateObject(wrappedValue: session)
    }

    public var body: some View {
        Group {
            switch session.phase {
            case .cover:
                BookCoverThresholdView(
                    gallery: session.gallery,
                    canContinue: session.hasResumeLocation,
                    onOpen: { session.openBook(preferredMode: .scroll) },
                    onContinue: { session.continueReading() }
                )
            case .reading:
                boundReader
            }
        }
        .sheet(isPresented: $session.galleryPresented) {
            NavigationStack {
                EditorialGalleryView(store: session.gallery)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { session.galleryPresented = false }
                        }
                    }
            }
        }
    }

    private var boundReader: some View {
        ZStack(alignment: .topTrailing) {
            SynchronizedReaderView(
                edition: session.edition,
                materialStore: session.materialStore,
                coordinator: session.coordinator
            )

            BookProgressOverlay(
                reader: session.coordinator.scrollSession,
                model: session.progressSpine
            )
            .frame(width: 12)
            .padding(.top, 58)
            .padding(.bottom, 12)
            .padding(.trailing, 5)

            if session.chromeVisible {
                BookShellChrome(
                    edition: session.edition,
                    reader: session.coordinator.scrollSession,
                    coordinator: session.coordinator,
                    onCover: { session.returnToCover() },
                    onGallery: { session.galleryPresented = true },
                    onHide: { session.toggleChrome() }
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            } else {
                Button {
                    withAnimation(.easeOut(duration: 0.18)) { session.toggleChrome() }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(JJWWEditorialPalette.cream)
                        .frame(width: 38, height: 38)
                        .background(JJWWEditorialPalette.ink.opacity(0.92), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Show reading controls")
                .padding(.top, 12)
                .padding(.trailing, 22)
            }
        }
        .background(JJWWEditorialPalette.ink)
    }
}

public struct BookCoverThresholdView: View {
    public let gallery: EditorialGalleryStore
    public let canContinue: Bool
    public let onOpen: () -> Void
    public let onContinue: () -> Void

    @GestureState private var dragY: CGFloat = 0

    public init(
        gallery: EditorialGalleryStore,
        canContinue: Bool,
        onOpen: @escaping () -> Void,
        onContinue: @escaping () -> Void
    ) {
        self.gallery = gallery
        self.canContinue = canContinue
        self.onOpen = onOpen
        self.onContinue = onContinue
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                JJWWEditorialPalette.ink.ignoresSafeArea()

                VStack(spacing: 18) {
                    Spacer(minLength: 18)

                    cover
                        .frame(maxWidth: min(geometry.size.width - 42, 430))
                        .frame(maxHeight: geometry.size.height * 0.76)
                        .scaleEffect(1 - min(0.018, abs(dragY) / 8500))
                        .offset(y: dragY * 0.09)
                        .shadow(color: .black.opacity(0.46), radius: 20, y: 10)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onOpen)
                        .gesture(
                            DragGesture(minimumDistance: 8)
                                .updating($dragY) { value, state, _ in
                                    state = value.translation.height
                                }
                                .onEnded { value in
                                    if value.translation.height < -58 || value.predictedEndTranslation.height < -105 {
                                        onOpen()
                                    }
                                }
                        )

                    HStack(spacing: 10) {
                        Button("OPEN BOOK", action: onOpen)
                            .buttonStyle(CoverActionButtonStyle(primary: true))

                        if canContinue {
                            Button("CONTINUE", action: onContinue)
                                .buttonStyle(CoverActionButtonStyle(primary: false))
                        }
                    }
                    .accessibilityElement(children: .contain)

                    publisherMark
                        .frame(height: 28)
                        .opacity(0.84)

                    Spacer(minLength: 14)
                }
                .padding(.horizontal, 20)
            }
        }
    }

    @ViewBuilder
    private var cover: some View {
        if let asset = gallery.asset(id: "jjww-cover-current"), asset.isAvailable {
            EditorialAssetImage(asset: asset, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .accessibilityHint("Double tap to open the book")
        } else {
            fallbackCover
                .aspectRatio(0.675, contentMode: .fit)
                .accessibilityLabel("Jesse James and the Widow Whipple cover placeholder")
                .accessibilityHint("Add JJWW UPDATED COVER copy.jpeg to the Gallery folder to use the supplied cover")
        }
    }

    private var fallbackCover: some View {
        ZStack {
            JJWWCoverClothTexture(seed: 1985)

            CreamArchFrameShape()
                .fill(JJWWEditorialPalette.cream)
                .padding(14)

            CreamArchFrameShape()
                .stroke(JJWWEditorialPalette.ink.opacity(0.36), lineWidth: 1)
                .padding(22)

            VStack(spacing: 10) {
                Spacer().frame(height: 48)

                JJWWTitleArt(color: JJWWEditorialPalette.ink)
                    .frame(maxWidth: 310)
                    .padding(.horizontal, 4)

                Spacer()

                Text("EAN WESLYNN")
                    .font(.system(size: 30, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.34), radius: 1, y: 1)
                    .padding(.bottom, 46)
            }
            .padding(.horizontal, 34)
        }
        .overlay(Rectangle().stroke(JJWWEditorialPalette.cream.opacity(0.5), lineWidth: 1))
    }

    @ViewBuilder
    private var publisherMark: some View {
        if let asset = gallery.asset(id: "real-good-stories-symbol"), asset.isAvailable {
            EditorialAssetImage(asset: asset, contentMode: .fit)
        } else {
            Text("REAL GOOD stories + stuff")
                .font(.system(size: 10, weight: .bold, design: .serif))
                .tracking(0.8)
                .foregroundStyle(JJWWEditorialPalette.cream.opacity(0.74))
        }
    }
}

private struct CoverActionButtonStyle: ButtonStyle {
    let primary: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .black, design: .monospaced))
            .tracking(0.8)
            .foregroundStyle(primary ? JJWWEditorialPalette.ink : JJWWEditorialPalette.cream)
            .padding(.horizontal, 16)
            .frame(height: 38)
            .background(primary ? JJWWEditorialPalette.cream : Color.clear)
            .overlay(Rectangle().stroke(JJWWEditorialPalette.cream.opacity(0.68), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.72 : 1)
    }
}

private struct BookProgressOverlay: View {
    @ObservedObject var reader: ScrollReaderSession
    let model: ProgressSpineModel

    var body: some View {
        ClothProgressSpine(
            model: model,
            progress: model.progress(for: reader.location)
        )
    }
}

private struct BookShellChrome: View {
    let edition: Edition
    @ObservedObject var reader: ScrollReaderSession
    @ObservedObject var coordinator: ReaderLocationCoordinator
    let onCover: () -> Void
    let onGallery: () -> Void
    let onHide: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 11) {
                Button(action: onCover) {
                    Text("JJWW")
                        .font(.system(size: 10, weight: .black, design: .serif))
                        .tracking(0.6)
                }
                .accessibilityLabel("Return to cover")

                Rectangle()
                    .fill(JJWWEditorialPalette.orange)
                    .frame(width: 2, height: 19)

                Text(currentLabel)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .lineLimit(1)
                    .foregroundStyle(JJWWEditorialPalette.cream.opacity(0.78))

                Spacer(minLength: 6)

                Menu {
                    ForEach(ReaderTextScale.allCases, id: \.self) { scale in
                        Button(scale.rawValue.capitalized) {
                            if reader.displayMode == .pages {
                                try? coordinator.repaginate(textScale: scale)
                            } else {
                                reader.changingTextScale(to: scale)
                            }
                        }
                    }
                } label: {
                    Text("Aa")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                }
                .accessibilityLabel("Text size")

                Menu {
                    ForEach(ReaderMaterialSetting.allCases, id: \.self) { setting in
                        Button(setting.rawValue.capitalized) {
                            reader.changingMaterial(to: setting)
                        }
                    }
                } label: {
                    Text(reader.materialSetting.rawValue.uppercased())
                        .font(.system(size: 8, weight: .black, design: .monospaced))
                }
                .accessibilityLabel("Material appearance")
                .accessibilityValue(reader.materialSetting.rawValue.capitalized)

                modeButton(.scroll)
                modeButton(.pages)

                #if DEBUG
                Button(action: onGallery) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 12, weight: .bold))
                }
                .accessibilityLabel("Editorial Gallery")
                #endif

                Button(action: onHide) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 10, weight: .black))
                }
                .accessibilityLabel("Hide reading controls")
            }
            .buttonStyle(.plain)
            .foregroundStyle(JJWWEditorialPalette.cream)
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(JJWWEditorialPalette.ink.opacity(0.97))

            HStack(spacing: 0) {
                Rectangle()
                    .fill(JJWWEditorialPalette.orange)
                    .frame(width: max(1, progressWidth), height: 3)
                Rectangle()
                    .fill(JJWWEditorialPalette.cream.opacity(0.16))
                    .frame(height: 3)
            }
            .accessibilityHidden(true)
        }
        .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
    }

    private var currentLabel: String {
        guard let unit = edition.readingUnit(id: reader.location.readingUnitID) else { return "" }
        return unit.sourcePresentation?.displayTitle ?? unit.id
    }

    private var progressWidth: CGFloat {
        CGFloat(min(1, max(0, reader.progress))) * 390
    }

    @ViewBuilder
    private func modeButton(_ mode: ReaderDisplayMode) -> some View {
        let selected = reader.displayMode == mode
        Button {
            switch mode {
            case .scroll:
                if reader.displayMode == .pages { coordinator.enterScroll() }
            case .pages:
                if reader.displayMode != .pages { coordinator.enterPages() }
            }
        } label: {
            Text(mode.rawValue.uppercased())
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(selected ? JJWWEditorialPalette.orange : Color.clear)
                .overlay(Rectangle().stroke(selected ? Color.clear : JJWWEditorialPalette.cream.opacity(0.34), lineWidth: 0.5))
        }
        .accessibilityValue(selected ? "Selected" : "Not selected")
    }
}
