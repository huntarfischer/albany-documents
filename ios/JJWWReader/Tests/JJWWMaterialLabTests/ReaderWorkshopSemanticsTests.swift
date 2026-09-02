import Foundation
import Testing
import JJWWReaderCore
import JJWWMaterials
import JJWWTypography
@testable import JJWWMaterialLab

@Suite("JJWW Stage 9 Act III-A Workshop Semantics")
@MainActor
struct ReaderWorkshopSemanticsTests {
    private var canonicalURL: URL {
        let testsDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let packageRoot = testsDirectory
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let repositoryRoot = packageRoot
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        return repositoryRoot.appendingPathComponent(
            "jesse-james-and-the-widow-whipple-canonical-v1.1.json"
        )
    }

    @Test("Workshop exposes the thirteen Act II treatments from real profile identity")
    func treatmentListUsesActIIProfiles() throws {
        resetRegistries()
        defer { resetRegistries() }

        let session = try makeSession()
        #expect(session.availableTreatments.map(\.id) == TypographyCatalog.all.map(\.id))
        #expect(session.availableTreatments.count == 13)
    }

    @Test("Historical Book specimens are filtered and human-readable")
    func specimensBelongToSelectedTreatment() throws {
        resetRegistries()
        defer { resetRegistries() }

        let session = try makeSession()
        session.selectTreatment("historicalBook")

        #expect(session.availableSpecimens.count == 14)
        #expect(session.availableSpecimens.allSatisfy { $0.typographyProfile.id == "historicalBook" })
        #expect(session.availableSpecimens.allSatisfy { !$0.displayTitle.hasPrefix("unit-l1-cnt-") })
    }

    @Test("Switching specimen preserves the treatment typography and composition draft")
    func specimenSwitchKeepsTreatmentDraft() throws {
        resetRegistries()
        defer { resetRegistries() }

        let session = try makeSession()
        session.selectTreatment("historicalBook")
        let specimens = session.availableSpecimens
        let second = try #require(specimens.dropFirst().first)

        session.selectedRole = .body
        let tunedTracking = session.draftTypography.token(.body).tracking + 0.57
        let tunedHeaderScale = session.draftComposition.headerScale + 0.13
        session.updateSelectedToken { $0.tracking = tunedTracking }
        session.updateComposition { $0.headerScale = tunedHeaderScale }

        session.selectSpecimen(second.id)

        #expect(session.selectedUnitID == second.id)
        #expect(session.selectedTreatmentID == "historicalBook")
        #expect(session.draftTypography.token(.body).tracking == tunedTracking)
        #expect(session.draftComposition.headerScale == tunedHeaderScale)
    }

    @Test("Switching treatments preserves isolation and restores prior treatment tuning")
    func treatmentSwitchKeepsProfilesIndependent() throws {
        resetRegistries()
        defer { resetRegistries() }

        let session = try makeSession()
        session.selectTreatment("historicalBook")
        session.selectedRole = .body
        let historicalTracking = session.draftTypography.token(.body).tracking + 0.71
        let historicalHeaderScale = session.draftComposition.headerScale + 0.17
        session.updateSelectedToken { $0.tracking = historicalTracking }
        session.updateComposition { $0.headerScale = historicalHeaderScale }

        session.selectTreatment("correspondence")
        #expect(session.selectedTreatmentID == "correspondence")
        #expect(session.draftTypography.id == "correspondence")
        #expect(session.draftComposition.id == "composition.correspondence.v0.1")
        #expect(session.draftTypography.token(.body).tracking != historicalTracking)
        #expect(session.draftComposition.headerScale != historicalHeaderScale)

        session.selectTreatment("historicalBook")
        #expect(session.draftTypography.token(.body).tracking == historicalTracking)
        #expect(session.draftComposition.headerScale == historicalHeaderScale)
    }

    @Test("Newspaper 1827 specimens share one treatment while retaining source variants")
    func newspaperSpecimensShareTreatmentOwner() throws {
        resetRegistries()
        defer { resetRegistries() }

        let session = try makeSession()
        session.selectTreatment("newspaper1827")
        let specimens = session.availableSpecimens
        let variants = Set(specimens.compactMap(\.presentationVariant))

        #expect(variants.contains("argus1827"))
        #expect(variants.contains("dailyAdvertiser1827"))
        #expect(variants.contains("periodicalSource"))

        let compositionID = session.draftComposition.id
        let daily = try #require(specimens.first(where: { $0.presentationVariant == "dailyAdvertiser1827" }))
        session.selectSpecimen(daily.id)

        #expect(session.selectedTreatmentID == "newspaper1827")
        #expect(session.draftTypography.id == "newspaper1827")
        #expect(session.draftComposition.id == compositionID)
    }

    private func makeSession() throws -> ReaderWorkshopSession {
        let edition = try Stage8ProductionEdition.load(canonicalURL: canonicalURL)
        let materialStore = try MaterialProfileStore.bundled()
        return ReaderWorkshopSession(edition: edition, materialStore: materialStore)
    }

    private func resetRegistries() {
        MaterialTuningRegistry.shared.removeAll()
        TypographyTuningRegistry.shared.removeAll()
        ReaderCompositionTuningRegistry.shared.removeAll()
    }
}
