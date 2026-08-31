import Foundation
import Combine
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader
import JJWWPagesReader

public enum BookShellPhase: String, Codable, Equatable, Sendable {
    case cover
    case reading
}

@MainActor
public final class BookShellSession: ObservableObject {
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    public let gallery: EditorialGalleryStore
    public let coordinator: ReaderLocationCoordinator
    public let progressSpine: ProgressSpineModel

    @Published public private(set) var phase: BookShellPhase
    @Published public var chromeVisible: Bool

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        gallery: EditorialGalleryStore,
        persistence: ReaderLocationPersistence = UserDefaultsReaderLocationPersistence(),
        initialPhase: BookShellPhase = .cover
    ) throws {
        self.edition = edition
        self.materialStore = materialStore
        self.gallery = gallery
        self.progressSpine = ProgressSpineModel(edition: edition)
        self.phase = initialPhase
        self.chromeVisible = true

        let scrollSession = ScrollReaderSession(
            edition: edition,
            persistence: persistence
        )
        self.coordinator = try ReaderLocationCoordinator(
            edition: edition,
            scrollSession: scrollSession
        )
    }

    public var hasResumeLocation: Bool {
        guard let unit = edition.readingUnit(id: coordinator.scrollSession.location.readingUnitID) else {
            return false
        }
        return unit.kind != .cover
    }

    public var progress: Double {
        progressSpine.progress(for: coordinator.scrollSession.location)
    }

    public var currentSectionLabel: String {
        guard let unit = edition.readingUnit(id: coordinator.scrollSession.location.readingUnitID) else {
            return ""
        }
        return unit.sourcePresentation?.displayTitle ?? unit.id
    }

    public func openBook(preferredMode: ReaderDisplayMode = .scroll) {
        if !hasResumeLocation, let first = firstReadingLocation {
            coordinator.scrollSession.move(to: first, requestScrollNavigation: preferredMode == .scroll)
        }
        phase = .reading
        setDisplayMode(preferredMode)
    }

    public func continueReading() {
        if !hasResumeLocation, let first = firstReadingLocation {
            coordinator.scrollSession.move(to: first, requestScrollNavigation: true)
        }
        phase = .reading
    }

    public func returnToCover() {
        phase = .cover
    }

    public func setDisplayMode(_ mode: ReaderDisplayMode) {
        switch mode {
        case .scroll:
            if coordinator.scrollSession.displayMode == .pages {
                coordinator.enterScroll()
            } else {
                coordinator.scrollSession.requestScrollMode()
            }
        case .pages:
            if coordinator.scrollSession.displayMode != .pages {
                coordinator.enterPages()
            }
        }
    }

    public func toggleChrome() {
        chromeVisible.toggle()
    }

    public var firstReadingLocation: ReaderLocation? {
        guard let unit = edition.orderedReadingUnits.first(where: { $0.kind != .cover }),
              let block = unit.blocks.first else {
            return nil
        }
        return ReaderLocation(
            readingUnitID: unit.id,
            blockID: block.id,
            canonicalLine: block.canonicalAnchor.startLine,
            utf16OffsetInLine: 0
        )
    }
}
