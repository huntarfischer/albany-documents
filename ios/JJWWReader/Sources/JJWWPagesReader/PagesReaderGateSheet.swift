import SwiftUI
import JJWWReaderCore
import JJWWMaterials
import JJWWPagination

public struct PagesReaderGateSheet: View {
    public struct Sample: Identifiable, Sendable {
        public let id: String
        public let label: String
        public let location: ReaderLocation
        public let page: PageSlice

        public init(id: String, label: String, location: ReaderLocation, page: PageSlice) {
            self.id = id
            self.label = label
            self.location = location
            self.page = page
        }
    }

    public let edition: Edition
    public let materialStore: MaterialProfileStore
    public let samples: [Sample]

    public init(
        edition: Edition,
        materialStore: MaterialProfileStore,
        samples: [Sample]
    ) {
        self.edition = edition
        self.materialStore = materialStore
        self.samples = samples
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("JJWW · STAGE 6")
                        .font(.system(size: 32, weight: .black, design: .serif))
                    Text("PAGES READER · semantic handoff into physical leaves")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .tracking(1.1)
                        .opacity(0.58)
                }
                Spacer()
                Text("390 × 844 · FOUR REAL LEAVES")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .opacity(0.54)
            }
            .foregroundStyle(.white)

            HStack(alignment: .top, spacing: 18) {
                ForEach(Array(samples.prefix(4))) { sample in
                    VStack(spacing: 7) {
                        HStack {
                            Text(sample.label).lineLimit(1)
                            Spacer()
                            Text("P\(sample.page.pageNumber) · \(sample.page.side.rawValue.uppercased())")
                        }
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.62))
                        .frame(width: 390)

                        PagesLeafView(
                            page: sample.page,
                            edition: edition,
                            materialStore: materialStore
                        )
                        .frame(width: 390, height: 844)
                        .clipped()
                        .overlay(Rectangle().stroke(.white.opacity(0.18), lineWidth: 1))

                        Text(mappingText(sample))
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.52))
                            .frame(width: 390, alignment: .leading)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("MODE CONTRACT")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .tracking(1.1)
                Text("SCROLL → PAGES resolves the exact ReaderLocation to its containing PageSlice. PAGES → SCROLL returns to the exact pre-switch location until a leaf is turned; after a turn it returns to that visible leaf's semantic start anchor.")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .frame(maxWidth: 1180, alignment: .leading)
                Text("MOTION: PAGE CURL · REDUCE MOTION: HORIZONTAL NON-CURL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .tracking(0.7)
                    .opacity(0.56)
            }
            .foregroundStyle(.white)
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(width: 1726, height: 1048, alignment: .topLeading)
        .background(Color(red: 0.075, green: 0.067, blue: 0.055))
    }

    private func mappingText(_ sample: Sample) -> String {
        "L\(sample.location.canonicalLine):\(sample.location.utf16OffsetInLine) → page \(sample.page.pageNumber) · starts L\(sample.page.startLocation.canonicalLine):\(sample.page.startLocation.utf16OffsetInLine)"
    }
}
