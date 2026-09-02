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
    }

    private var boundReader: some View {
        ZStack(alignment: .topTrailing) {
            BookReaderHost(
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
            .padding(.leading, 5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .allowsHitTesting(false)

            if session.chromeVisible {
                BookShellChrome(
                    edition: session.edition,
                    reader: session.coordinator.scrollSession,
                    coordinator: session.coordinator,
                    onCover: { session.returnToCover() },
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
                        .frame(height: 36)
                        .opacity(0.96)

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

private struct BookReaderHost: View {
    let edition: Edition
    let materialStore: MaterialProfileStore
    @ObservedObject var coordinator: ReaderLocationCoordinator
    @ObservedObject private var reader: ScrollReaderSession

    init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        coordinator: ReaderLocationCoordinator
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.coordinator = coordinator
        _reader = ObservedObject(wrappedValue: coordinator.scrollSession)
    }

    var body: some View {
        switch reader.displayMode {
        case .scroll:
            ScrollReaderView(
                edition: edition,
                materialStore: materialStore,
                session: reader,
                pagesEnabled: true,
                onRequestPages: { coordinator.enterPages() },
                showsChrome: false
            )
        case .pages:
            PagesReaderView(
                edition: edition,
                materialStore: materialStore,
                coordinator: coordinator,
                showsChrome: false
            )
        }
    }
}

private struct BookProgressOverlay: View {
    @ObservedObject var reader: ScrollReaderSession
    let model: ProgressSpineModel

    @ViewBuilder
    var body: some View {
        if reader.displayMode == .scroll {
            ClothProgressSpine(
                model: model,
                progress: model.progress(for: reader.location)
            )
        }
    }
}

private struct BookShellChrome: View {
    let edition: Edition
    @ObservedObject var reader: ScrollReaderSession
    @ObservedObject var coordinator: ReaderLocationCoordinator
    let onCover: () -> Void
    let onHide: () -> Void

    var body: some View {
        HStack(spacing: 10) {
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
                .truncationMode(.tail)
                .foregroundStyle(JJWWEditorialPalette.cream.opacity(0.78))
                .frame(maxWidth: .infinity, alignment: .leading)

            textScaleMenu
            modeToggle
            overflowMenu
        }
        .buttonStyle(.plain)
        .foregroundStyle(JJWWEditorialPalette.cream)
        .padding(.horizontal, 12)
        .frame(height: 52)
        .background(JJWWEditorialPalette.ink.opacity(0.97))
        .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
    }

    private var currentLabel: String {
        guard let unit = edition.readingUnit(id: reader.location.readingUnitID) else { return "" }
        return unit.displayTitle
    }

    private var textScaleMenu: some View {
        Menu {
            ForEach(ReaderTextScale.allCases, id: \.self) { scale in
                Button {
                    if reader.displayMode == .pages {
                        try? coordinator.repaginate(textScale: scale)
                    } else {
                        reader.changingTextScale(to: scale)
                    }
                } label: {
                    if scale == reader.textScale {
                        Label(scale.rawValue.capitalized, systemImage: "checkmark")
                    } else {
                        Text(scale.rawValue.capitalized)
                    }
                }
            }
        } label: {
            Text("Aa")
                .font(.system(size: 15, weight: .bold, design: .serif))
                .frame(minWidth: 28)
        }
        .accessibilityLabel("Text size")
        .accessibilityValue(reader.textScale.rawValue.capitalized)
    }

    private var modeToggle: some View {
        Button(action: toggleDisplayMode) {
            Text(reader.displayMode.rawValue.uppercased())
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(JJWWEditorialPalette.orange)
        }
        .accessibilityLabel("Reading mode")
        .accessibilityValue(reader.displayMode.rawValue.capitalized)
        .accessibilityHint(
            reader.displayMode == .scroll
                ? "Switch to Pages"
                : "Switch to Scroll"
        )
    }

    private var overflowMenu: some View {
        Menu {
            Section("Material") {
                ForEach(ReaderMaterialSetting.allCases, id: \.self) { setting in
                    Button {
                        reader.changingMaterial(to: setting)
                    } label: {
                        if setting == reader.materialSetting {
                            Label(setting.rawValue.capitalized, systemImage: "checkmark")
                        } else {
                            Text(setting.rawValue.capitalized)
                        }
                    }
                }
            }

            Divider()

            Button(action: onHide) {
                Label("Hide Controls", systemImage: "chevron.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 14, weight: .bold))
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("More reading controls")
    }

    private func toggleDisplayMode() {
        switch reader.displayMode {
        case .scroll:
            coordinator.enterPages()
        case .pages:
            coordinator.enterScroll()
        }
    }
}