import SwiftUI
import JJWWMaterials

public struct TypographySpecimenSheet: View {
    private let materialStore: MaterialProfileStore
    private let materialEngine = MaterialEngine()

    public init(materialStore: MaterialProfileStore) {
        self.materialStore = materialStore
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("JJWW TYPOGRAPHY + INK AWAKENING")
                    .font(.system(size: 28, weight: .black, design: .serif))
                Text("Stage 3 gate · final typography with three reveal states")
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Text("25%")
                Spacer()
                Text("58%")
                Spacer()
                Text("100%")
            }
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.secondary)

            specimen(
                materialID: "argus1827",
                typography: TypographyCatalog.newspaper,
                ink: InkAwakeningCatalog.argus,
                date: "Tuesday May 8, 1827",
                source: "The Albany Argus & City Gazette",
                title: "PROCLAMATION",
                body: "A horrible assassination was committed at Cherry Hill."
            )

            specimen(
                materialID: "dailyAdvertiser1827",
                typography: TypographyCatalog.newspaper,
                ink: InkAwakeningCatalog.dailyAdvertiser,
                date: "Monday June 18, 1827",
                source: "The Albany Daily Advertiser",
                title: "THE LATE MURDER",
                body: "The report now turns toward confession, arrest, and the recovery of the rifle."
            )

            specimen(
                materialID: "confessionPamphlet1827",
                typography: TypographyCatalog.confession,
                ink: InkAwakeningCatalog.confession,
                date: "1827",
                source: "The Confession Of Jesse James Strang",
                title: "CONFESSION",
                body: "I now proceed to give a history of my life and the circumstances which brought me here."
            )

            specimen(
                materialID: "trialRecord1827",
                typography: TypographyCatalog.trial,
                ink: InkAwakeningCatalog.trial,
                date: "July 1827",
                source: "The Trial of Jesse James Strang",
                title: "MATILDA BECKER, sworn.",
                body: "By Oakley. The witness answers; counsel interrupts; the court rules."
            )

            specimen(
                materialID: "farewell1827",
                typography: TypographyCatalog.farewell,
                ink: InkAwakeningCatalog.farewell,
                date: "August 24, 1827",
                source: "Farewell Address",
                title: "THE FINAL WORDS OF JESSE JAMES STRANG",
                body: "And bid thee go and sin NO more."
            )
        }
        .padding(24)
        .frame(width: 1360)
        .background(Color(red: 0.095, green: 0.085, blue: 0.07))
    }

    @ViewBuilder
    private func specimen(
        materialID: String,
        typography: TypographyProfileDefinition,
        ink: InkAwakeningProfile,
        date: String,
        source: String,
        title: String,
        body: String
    ) -> some View {
        if let material = materialStore.profile(id: materialID) {
            let recipe = materialEngine.resolve(profile: material, state: .full, seed: seed(for: materialID))
            MaterialSurfaceView(recipe: recipe) {
                HStack(alignment: .top, spacing: 20) {
                    headerColumn(progress: 0.25, typography: typography, ink: ink, date: date, source: source, title: title)
                    headerColumn(progress: 0.58, typography: typography, ink: ink, date: date, source: source, title: title)
                    headerColumn(progress: 1.00, typography: typography, ink: ink, date: date, source: source, title: title)
                }
                .overlay(alignment: .bottomLeading) {
                    TypographicText(body, token: typography.token(typography.id == "farewell1827" ? .verse : .body))
                        .foregroundStyle(Color.black.opacity(0.76))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 14)
                }
                .padding(20)
            }
            .frame(height: 235)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private func headerColumn(
        progress: Double,
        typography: TypographyProfileDefinition,
        ink: InkAwakeningProfile,
        date: String,
        source: String,
        title: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            InkAwakeningPreviewText(
                date,
                token: typography.token(.dateHeading),
                profile: ink,
                seed: seed(for: "\(ink.id).date"),
                progress: progress
            )
            InkAwakeningPreviewText(
                source,
                token: typography.token(.sourceHeader),
                profile: ink,
                seed: seed(for: "\(ink.id).source"),
                progress: progress
            )
            InkAwakeningPreviewText(
                title,
                token: typography.token(.sectionTitle),
                profile: ink,
                seed: seed(for: "\(ink.id).title"),
                progress: progress
            )
        }
        .foregroundStyle(Color.black.opacity(0.84))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func seed(for text: String) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in text.utf8 {
            hash ^= UInt64(byte)
            hash &*= 0x100000001b3
        }
        return hash
    }
}
