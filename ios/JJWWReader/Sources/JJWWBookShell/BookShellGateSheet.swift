import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography
import JJWWScrollReader
import JJWWPagination
import JJWWPagesReader

public struct BookShellGateSheet: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    public let gallery: EditorialGalleryStore
    public let pagination: PaginationResult

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        gallery: EditorialGalleryStore,
        pagination: PaginationResult
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.gallery = gallery
        self.pagination = pagination
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JJWW · STAGE 7")
                        .font(.system(size: 32, weight: .black, design: .serif))
                    Text("COVER · EDITORIAL BINDING · PROGRESS SPINE · GALLERY")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.1)
                        .opacity(0.58)
                }
                Spacer()
                Text("390 × 844 · FOUR PHONE STATES")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.54)
            }
            .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 18) {
                phone(label: "COVER · EXTERIOR") {
                    BookCoverThresholdView(
                        gallery: gallery,
                        canContinue: true,
                        onOpen: {},
                        onContinue: {}
                    )
                }

                phone(label: "SCROLL · BOUND") {
                    boundScrollPreview
                }

                phone(label: "PAGES · BOUND") {
                    boundPagePreview
                }

                phone(label: "GALLERY · DROP + PLACE") {
                    StaticGalleryPreview(store: gallery)
                }
            }

            HStack {
                Text("COVER IS EXTERIOR · ALBANY MAP REMAINS A DELAYED TITLE PLATE")
                Spacer()
                Text("gallery auto-discovers new image files; placement remains explicit")
            }
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.50))

            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(width: 1726, height: 1010, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
    }

    @ViewBuilder
    private func phone<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 7) {
            HStack {
                Text(label)
                Spacer()
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.62))
            .frame(width: 390)

            content()
                .frame(width: 390, height: 844, alignment: .top)
                .clipped()
                .overlay(Rectangle().stroke(.white.opacity(0.18), lineWidth: 1))
        }
    }

    @ViewBuilder
    private var boundScrollPreview: some View {
        if let unit = edition.readingUnit(id: "argus-may-8-9-1827") {
            ZStack(alignment: .topTrailing) {
                SnapshotSafeScrollUnitPreview(
                    unit: unit,
                    materialStore: materialStore
                )

                StaticBindingChrome(title: unit.sourcePresentation?.displayTitle ?? unit.id, mode: .scroll)

                ClothProgressSpine(
                    model: ProgressSpineModel(edition: edition),
                    progress: 0.04
                )
                .frame(width: 12)
                .padding(.top, 58)
                .padding(.bottom, 12)
                .padding(.trailing, 5)
            }
        } else {
            Color.red.opacity(0.2)
        }
    }

    @ViewBuilder
    private var boundPagePreview: some View {
        if let page = pagination.pages(representing: "farewell-address").first {
            ZStack(alignment: .topTrailing) {
                PagesLeafView(page: page, edition: edition, materialStore: materialStore)
                StaticBindingChrome(title: "Farewell Address", mode: .pages)
                ClothProgressSpine(
                    model: ProgressSpineModel(edition: edition),
                    progress: 0.95
                )
                .frame(width: 12)
                .padding(.top, 58)
                .padding(.bottom, 12)
                .padding(.trailing, 5)
            }
        } else {
            Color.red.opacity(0.2)
        }
    }
}

/// The gate now renders the same ReadingUnitSurface used by the live Scroll
/// reader. Snapshot safety is supplied as a layout-width hint to the shared
/// justified renderer, rather than by maintaining a second typography mock.
private struct SnapshotSafeScrollUnitPreview: View {
    let unit: ReadingUnit
    let materialStore: MaterialProfileStore

    var body: some View {
        ReadingUnitSurface(
            unit: unit,
            materialStore: materialStore,
            materialSetting: .full,
            textScale: .standard,
            entryContext: .jumpIntoSection,
            lineLimit: 14,
            animateOpening: false,
            snapshotLayoutWidth: 334
        )
        .frame(maxWidth: .infinity, alignment: .top)
        .background(JJWWEditorialPalette.ink)
    }
}

private struct StaticGalleryPreview: View {
    let store: EditorialGalleryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("EDITORIAL GALLERY")
                    .font(.system(size: 22, weight: .black, design: .serif))
                Text("DROP IMAGE → REVIEW → PLACE")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .tracking(0.8)
                    .opacity(0.54)
            }
            .foregroundStyle(JJWWEditorialPalette.cream)

            ForEach(Array(store.assets.prefix(3))) { asset in
                HStack(spacing: 10) {
                    EditorialAssetImage(asset: asset, contentMode: .fill)
                        .frame(width: 116, height: 148)
                        .clipped()

                    VStack(alignment: .leading, spacing: 7) {
                        Text(asset.descriptor.title)
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .lineLimit(3)
                        Text(asset.descriptor.filename)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .lineLimit(3)
                            .opacity(0.56)
                        Spacer(minLength: 0)
                        Text(status(asset))
                            .font(.system(size: 8, weight: .black, design: .monospaced))
                            .tracking(0.5)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(asset.isAvailable ? JJWWEditorialPalette.orange : Color.black.opacity(0.08))
                    }
                    .foregroundStyle(JJWWEditorialPalette.ink)
                    .padding(.vertical, 8)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(JJWWEditorialPalette.cream)
                .overlay(Rectangle().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
            }

            Spacer(minLength: 0)

            Text("NEW FILES APPEAR AUTOMATICALLY AS UNPLACED")
                .font(.system(size: 8, weight: .black, design: .monospaced))
                .tracking(0.6)
                .foregroundStyle(JJWWEditorialPalette.cream.opacity(0.52))
        }
        .padding(14)
        .background(JJWWEditorialPalette.ink)
    }

    private func status(_ asset: ResolvedEditorialAsset) -> String {
        if !asset.isAvailable { return "MISSING · DROP INTO GALLERY" }
        if let placement = asset.descriptor.placement {
            return "L\(placement.canonicalLine) \(placement.edge.rawValue.uppercased())"
        }
        return asset.discoveredAutomatically ? "NEW · UNPLACED" : "UNPLACED"
    }
}

private struct StaticBindingChrome: View {
    let title: String
    let mode: ReaderDisplayMode

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Text("JJWW")
                    .font(.system(size: 10, weight: .black, design: .serif))
                Rectangle().fill(JJWWEditorialPalette.orange).frame(width: 2, height: 19)
                Text(title)
                    .font(.system(size: 10, weight: .semibold, design: .serif))
                    .lineLimit(1)
                    .foregroundStyle(JJWWEditorialPalette.cream.opacity(0.78))
                Spacer()
                Text("Aa")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                Text("FULL")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                Text(mode.rawValue.uppercased())
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(JJWWEditorialPalette.orange)
            }
            .foregroundStyle(JJWWEditorialPalette.cream)
            .padding(.horizontal, 12)
            .frame(height: 52)
            .background(JJWWEditorialPalette.ink.opacity(0.97))

            HStack(spacing: 0) {
                Rectangle().fill(JJWWEditorialPalette.orange).frame(width: 116, height: 3)
                Rectangle().fill(JJWWEditorialPalette.cream.opacity(0.16)).frame(height: 3)
            }
        }
    }
}
