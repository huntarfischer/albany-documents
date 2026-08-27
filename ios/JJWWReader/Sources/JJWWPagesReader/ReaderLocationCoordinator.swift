import Foundation
import Combine
import JJWWReaderCore
import JJWWScrollReader
import JJWWPagination

public enum PageTurnTransition: String, Codable, Equatable, Sendable {
    case pageCurl
    case horizontalScroll
}

public enum PageTurnPolicy {
    public static func transition(reduceMotion: Bool) -> PageTurnTransition {
        reduceMotion ? .horizontalScroll : .pageCurl
    }
}

@MainActor
public final class ReaderLocationCoordinator: ObservableObject {
    public let edition: Edition
    public let scrollSession: ScrollReaderSession

    @Published public private(set) var pagination: PaginationResult
    @Published public private(set) var currentPageIndex: Int

    private let paginationEngine: PaginationEngine
    private var geometry: PageGeometry

    public init(
        edition: Edition,
        scrollSession: ScrollReaderSession,
        paginationEngine: PaginationEngine = PaginationEngine(),
        geometry: PageGeometry = .phonePortrait
    ) throws {
        self.edition = edition
        self.scrollSession = scrollSession
        self.paginationEngine = paginationEngine
        self.geometry = geometry

        let configuration = PaginationConfiguration(
            geometry: geometry,
            textScale: scrollSession.textScale
        )
        let result = try paginationEngine.paginate(
            edition: edition,
            configuration: configuration
        )
        self.pagination = result
        self.currentPageIndex = ReaderLocationCoordinator.pageIndex(
            containing: scrollSession.location,
            in: result
        ) ?? 0
    }

    public var currentPage: PageSlice? {
        guard pagination.pages.indices.contains(currentPageIndex) else { return nil }
        return pagination.pages[currentPageIndex]
    }

    public var canTurnBackward: Bool { currentPageIndex > 0 }
    public var canTurnForward: Bool { currentPageIndex + 1 < pagination.pages.count }

    public func enterPages() {
        currentPageIndex = ReaderLocationCoordinator.pageIndex(
            containing: scrollSession.location,
            in: pagination
        ) ?? min(currentPageIndex, max(0, pagination.pages.count - 1))

        if let currentPage {
            scrollSession.move(to: currentPage.startLocation, requestScrollNavigation: false)
        }
        scrollSession.requestPagesMode()
    }

    public func enterScroll() {
        if let currentPage {
            scrollSession.move(to: currentPage.startLocation, requestScrollNavigation: true)
        }
        scrollSession.requestScrollMode()
    }

    public func showPage(index: Int) {
        guard pagination.pages.indices.contains(index) else { return }
        currentPageIndex = index
        let page = pagination.pages[index]
        scrollSession.move(to: page.startLocation, requestScrollNavigation: false)
    }

    public func turnForward() {
        guard canTurnForward else { return }
        showPage(index: currentPageIndex + 1)
    }

    public func turnBackward() {
        guard canTurnBackward else { return }
        showPage(index: currentPageIndex - 1)
    }

    public func repaginate(
        textScale: ReaderTextScale,
        geometry newGeometry: PageGeometry? = nil
    ) throws {
        let semanticLocation = scrollSession.location
        scrollSession.changingTextScale(to: textScale)
        if let newGeometry { geometry = newGeometry }

        let configuration = PaginationConfiguration(
            geometry: geometry,
            textScale: textScale
        )
        let result = try paginationEngine.paginate(
            edition: edition,
            configuration: configuration
        )
        pagination = result
        currentPageIndex = ReaderLocationCoordinator.pageIndex(
            containing: semanticLocation,
            in: result
        ) ?? min(currentPageIndex, max(0, result.pages.count - 1))

        if scrollSession.displayMode == .pages, let currentPage {
            scrollSession.move(to: currentPage.startLocation, requestScrollNavigation: false)
        }
    }

    public static func pageIndex(
        containing location: ReaderLocation,
        in result: PaginationResult
    ) -> Int? {
        result.page(containing: location)?.pageIndex
    }
}
