import SwiftUI
import JJWWMaterials

#if DEBUG
public struct ReaderLabView: View {
    private let profiles: [MaterialProfileDefinition]

    public init(profiles: [MaterialProfileDefinition]) {
        self.profiles = profiles
    }

    public var body: some View {
        TabView {
            MaterialLabView(profiles: profiles)
                .tabItem { Label("Material", systemImage: "square.3.layers.3d") }
            InkLabView()
                .tabItem { Label("Ink", systemImage: "drop.fill") }
        }
    }
}
#endif
