import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWBookShell
#if DEBUG
import JJWWMaterialLab
#endif

@main
struct JJWWApp: App {
    var body: some Scene {
        WindowGroup {
            JJWWAppRootView()
        }
    }
}

@MainActor
private final class JJWWAppModel: ObservableObject {
    let edition: Edition
    let materialStore: MaterialProfileStore
    let session: BookShellSession

    init() throws {
        guard let canonicalURL = Bundle.main.url(
            forResource: "jesse-james-and-the-widow-whipple-canonical-v1.1",
            withExtension: "json"
        ) else {
            throw JJWWAppBootstrapError.canonicalFixtureMissing
        }

        let edition = try Stage0Fixture.load(canonicalURL: canonicalURL)
        let materialStore = try MaterialProfileStore.bundled()
        let gallery = try EditorialGalleryStore.bundled()

        self.edition = edition
        self.materialStore = materialStore
        self.session = try BookShellSession(
            edition: edition,
            materialStore: materialStore,
            gallery: gallery
        )
    }
}

private enum JJWWAppBootstrapError: LocalizedError {
    case canonicalFixtureMissing

    var errorDescription: String? {
        switch self {
        case .canonicalFixtureMissing:
            return "The canonical v1.1 book fixture is missing from the app bundle."
        }
    }
}

private struct JJWWAppRootView: View {
    @State private var model: JJWWAppModel?
    @State private var bootstrapError: String?
    #if DEBUG
    @State private var workshopPresented = false
    #endif

    var body: some View {
        Group {
            if let model {
                ZStack(alignment: .bottomTrailing) {
                    JJWWBookView(session: model.session)

                    #if DEBUG
                    Button {
                        workshopPresented = true
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(.black.opacity(0.82), in: Circle())
                            .overlay(Circle().stroke(.white.opacity(0.18), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Reader Lab")
                    .padding(.trailing, 18)
                    .padding(.bottom, 24)
                    .sheet(isPresented: $workshopPresented) {
                        ReaderLabView(
                            profiles: model.materialStore.profiles,
                            edition: model.edition,
                            materialStore: model.materialStore,
                            gallery: model.session.gallery
                        )
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                    }
                    #endif
                }
            } else if let bootstrapError {
                ContentUnavailableView(
                    "JJWW could not open",
                    systemImage: "book.closed",
                    description: Text(bootstrapError)
                )
            } else {
                ProgressView("Opening JJWW…")
                    .task { bootstrap() }
            }
        }
    }

    private func bootstrap() {
        do {
            model = try JJWWAppModel()
        } catch {
            bootstrapError = error.localizedDescription
        }
    }
}
