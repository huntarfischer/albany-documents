import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWScrollReader
import JJWWPagination

public struct SynchronizedReaderView: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    @ObservedObject public var coordinator: ReaderLocationCoordinator

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        coordinator: ReaderLocationCoordinator
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.coordinator = coordinator
    }

    public var body: some View {
        switch coordinator.scrollSession.displayMode {
        case .scroll:
            ScrollReaderView(
                edition: edition,
                materialStore: materialStore,
                session: coordinator.scrollSession,
                pagesEnabled: true,
                onRequestPages: { coordinator.enterPages() }
            )
        case .pages:
            PagesReaderView(
                edition: edition,
                materialStore: materialStore,
                coordinator: coordinator
            )
        }
    }
}

public struct PagesReaderView: View {
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    @ObservedObject public var coordinator: ReaderLocationCoordinator

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        coordinator: ReaderLocationCoordinator
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.coordinator = coordinator
    }

    public var body: some View {
        ZStack(alignment: .top) {
            NativePagesController(
                pages: coordinator.pagination.pages,
                currentPageIndex: Binding(
                    get: { coordinator.currentPageIndex },
                    set: { coordinator.showPage(index: $0) }
                ),
                transition: PageTurnPolicy.transition(reduceMotion: reduceMotion),
                edition: edition,
                materialStore: materialStore,
                materialState: coordinator.scrollSession.materialSetting.materialState
            )
            .id(PageTurnPolicy.transition(reduceMotion: reduceMotion))
            .ignoresSafeArea()

            PagesChrome(coordinator: coordinator)
        }
        .background(Color(red: 0.07, green: 0.064, blue: 0.052))
    }
}

public struct PagesLeafView: View {
    public let page: PageSlice
    public let edition: Edition
    public let materialStore: MaterialProfileStore
    public let materialState: MaterialState

    public init(
        page: PageSlice,
        edition: Edition,
        materialStore: MaterialProfileStore,
        materialState: MaterialState = .full
    ) {
        self.page = page
        self.edition = edition
        self.materialStore = materialStore
        self.materialState = materialState
    }

    public var body: some View {
        ComposedPageLeafView(
            page: page,
            edition: edition,
            materialStore: materialStore,
            materialState: materialState
        )
        .overlay {
            HStack(spacing: 0) {
                if page.side == .recto {
                    gutter
                    Spacer(minLength: 0)
                } else {
                    Spacer(minLength: 0)
                    gutter
                }
            }
        }
        .overlay(Rectangle().stroke(Color.black.opacity(0.08), lineWidth: 0.5))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Page \(page.pageNumber)")
    }

    private var gutter: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.16), Color.black.opacity(0.045), .clear],
            startPoint: page.side == .recto ? .leading : .trailing,
            endPoint: page.side == .recto ? .trailing : .leading
        )
        .frame(width: 15)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct PagesChrome: View {
    @ObservedObject var coordinator: ReaderLocationCoordinator

    var body: some View {
        VStack(spacing: 0) {
            ProgressView(
                value: Double(coordinator.currentPageIndex + 1),
                total: Double(max(1, coordinator.pagination.pages.count))
            )
            .progressViewStyle(.linear)
            .tint(Color(red: 0.94, green: 0.29, blue: 0.06))
            .scaleEffect(x: 1, y: 0.55, anchor: .center)

            HStack(spacing: 14) {
                Text("\(coordinator.currentPageIndex + 1)/\(coordinator.pagination.pages.count)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.72))

                Spacer()

                Menu {
                    ForEach(ReaderTextScale.allCases, id: \.self) { scale in
                        Button(scale.rawValue.capitalized) {
                            try? coordinator.repaginate(textScale: scale)
                        }
                    }
                } label: {
                    Text("Aa")
                        .font(.system(size: 15, weight: .bold, design: .serif))
                }

                Menu {
                    ForEach(ReaderMaterialSetting.allCases, id: \.self) { setting in
                        Button(setting.rawValue.capitalized) {
                            coordinator.scrollSession.changingMaterial(to: setting)
                        }
                    }
                } label: {
                    Text(coordinator.scrollSession.materialSetting.rawValue.capitalized)
                        .font(.system(size: 12, weight: .semibold))
                }

                HStack(spacing: 4) {
                    Button("SCROLL") {
                        coordinator.enterScroll()
                    }
                    .font(.system(size: 10, weight: .black, design: .monospaced))

                    Text("PAGES")
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Color(red: 0.94, green: 0.29, blue: 0.06),
                            in: Capsule()
                        )
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(.black.opacity(0.78))
            .foregroundStyle(.white)
        }
    }
}

#if canImport(UIKit)
import UIKit

private struct NativePagesController: UIViewControllerRepresentable {
    let pages: [PageSlice]
    @Binding var currentPageIndex: Int
    let transition: PageTurnTransition
    let edition: Edition
    let materialStore: MaterialProfileStore
    let materialState: MaterialState

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let style: UIPageViewController.TransitionStyle = transition == .pageCurl ? .pageCurl : .scroll
        let controller = UIPageViewController(
            transitionStyle: style,
            navigationOrientation: .horizontal,
            options: nil
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.isDoubleSided = false
        context.coordinator.controller = controller

        if pages.indices.contains(currentPageIndex) {
            let page = context.coordinator.hostingController(for: currentPageIndex)
            controller.setViewControllers([page], direction: .forward, animated: false)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIPageViewController, context: Context) {
        context.coordinator.parent = self
        guard pages.indices.contains(currentPageIndex) else { return }
        let visibleIndex = uiViewController.viewControllers?.first?.view.tag
        guard visibleIndex != currentPageIndex else { return }
        let direction: UIPageViewController.NavigationDirection = (visibleIndex ?? 0) < currentPageIndex ? .forward : .reverse
        let page = context.coordinator.hostingController(for: currentPageIndex)
        uiViewController.setViewControllers([page], direction: direction, animated: false)
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var parent: NativePagesController
        weak var controller: UIPageViewController?

        init(parent: NativePagesController) {
            self.parent = parent
        }

        func hostingController(for index: Int) -> UIViewController {
            let page = parent.pages[index]
            let host = UIHostingController(
                rootView: PagesLeafView(
                    page: page,
                    edition: parent.edition,
                    materialStore: parent.materialStore,
                    materialState: parent.materialState
                )
                .ignoresSafeArea()
            )
            host.view.tag = index
            host.view.backgroundColor = .clear
            return host
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            let index = viewController.view.tag
            guard index > 0 else { return nil }
            return hostingController(for: index - 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            let index = viewController.view.tag
            guard index + 1 < parent.pages.count else { return nil }
            return hostingController(for: index + 1)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed,
                  let index = pageViewController.viewControllers?.first?.view.tag else { return }
            parent.currentPageIndex = index
        }
    }
}

#else
private struct NativePagesController: View {
    let pages: [PageSlice]
    @Binding var currentPageIndex: Int
    let transition: PageTurnTransition
    let edition: Edition
    let materialStore: MaterialProfileStore
    let materialState: MaterialState

    var body: some View {
        if pages.indices.contains(currentPageIndex) {
            PagesLeafView(
                page: pages[currentPageIndex],
                edition: edition,
                materialStore: materialStore,
                materialState: materialState
            )
        } else {
            Color.clear
        }
    }
}
#endif
