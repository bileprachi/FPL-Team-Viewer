import Foundation
import Testing

// MARK: - Mock Service & Cache for Unit Testing
final class MockFPLService: FPLServiceProtocol, @unchecked Sendable {
    var result: Result<FPLBootstrapData, Error>

    init(result: Result<FPLBootstrapData, Error>) {
        self.result = result
    }

    func fetchBootstrapData() async throws -> FPLBootstrapData {
        switch result {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }
}

final class MockFPLCache: FPLCacheProtocol, @unchecked Sendable {
    var storedData: FPLBootstrapData?
    var didCallSave = false
    var didCallClear = false

    init(initialData: FPLBootstrapData? = nil) {
        self.storedData = initialData
    }

    func loadCachedData() -> FPLBootstrapData? {
        return storedData
    }

    func saveCachedData(_ data: FPLBootstrapData) throws {
        didCallSave = true
        storedData = data
    }

    func clearCache() {
        didCallClear = true
        storedData = nil
    }
}

// MARK: - Test Data Fixtures
struct TestFixtures {
    static let arsenal = Team(id: 1, name: "Arsenal", shortName: "ARS")
    static let chelsea = Team(id: 2, name: "Chelsea", shortName: "CHE")

    static let gkPos = Position(id: 1, pluralName: "Goalkeepers", singularName: "Goalkeeper", shortName: "GKP")
    static let defPos = Position(id: 2, pluralName: "Defenders", singularName: "Defender", shortName: "DEF")
    static let midPos = Position(id: 3, pluralName: "Midfielders", singularName: "Midfielder", shortName: "MID")
    static let fwdPos = Position(id: 4, pluralName: "Forwards", singularName: "Forward", shortName: "FWD")

    static let positions = [gkPos, defPos, midPos, fwdPos]
    static let positionsMap: [Int: Position] = [1: gkPos, 2: defPos, 3: midPos, 4: fwdPos]

    static let raya = Player(
        id: 1,
        firstName: "David",
        secondName: "Raya",
        webName: "Raya",
        teamId: 1,
        elementTypeId: 1,
        nowCost: 61,
        totalPoints: 30
    )

    static let saliba = Player(
        id: 2,
        firstName: "William",
        secondName: "Saliba",
        webName: "Saliba",
        teamId: 1,
        elementTypeId: 2,
        nowCost: 60,
        totalPoints: 25
    )

    static let saka = Player(
        id: 3,
        firstName: "Bukayo",
        secondName: "Saka",
        webName: "Saka",
        teamId: 1,
        elementTypeId: 3,
        nowCost: 100,
        totalPoints: 45
    )

    static let odegaard = Player(
        id: 4,
        firstName: "Martin",
        secondName: "Ødegaard",
        webName: "Ødegaard",
        teamId: 1,
        elementTypeId: 3,
        nowCost: 85,
        totalPoints: 20
    )

    static let palmer = Player(
        id: 5,
        firstName: "Cole",
        secondName: "Palmer",
        webName: "Palmer",
        teamId: 2,
        elementTypeId: 3,
        nowCost: 105,
        totalPoints: 50
    )

    static func sampleBootstrapData() -> FPLBootstrapData {
        return FPLBootstrapData(
            teams: [arsenal, chelsea],
            elements: [raya, saliba, saka, odegaard, palmer],
            elementTypes: positions
        )
    }
}

// MARK: - 1. API & Data Decoding Tests
@Suite("API and Data Decoding Tests")
struct APIDataDecodingTests {
    @Test("Decode valid FPL JSON payload")
    func testDecodeValidJSON() throws {
        let json = """
        {
            "teams": [
                { "id": 1, "name": "Arsenal", "short_name": "ARS" }
            ],
            "elements": [
                {
                    "id": 1,
                    "first_name": "David",
                    "second_name": "Raya",
                    "web_name": "Raya",
                    "team": 1,
                    "element_type": 1,
                    "now_cost": 61,
                    "total_points": 30
                }
            ],
            "element_types": [
                {
                    "id": 1,
                    "plural_name": "Goalkeepers",
                    "singular_name": "Goalkeeper",
                    "singular_name_short": "GKP"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(FPLBootstrapData.self, from: json)
        #expect(decoded.teams.count == 1)
        #expect(decoded.teams.first?.name == "Arsenal")
        #expect(decoded.teams.first?.shortName == "ARS")
        #expect(decoded.elements.count == 1)
        #expect(decoded.elements.first?.webName == "Raya")
        #expect(decoded.elements.first?.nowCost == 61)
        #expect(decoded.elements.first?.formattedPrice == "£6.1m")
        #expect(decoded.elementTypes.count == 1)
        #expect(decoded.elementTypes.first?.singularName == "Goalkeeper")
    }

    @Test("Decoding fails on invalid JSON structure")
    func testDecodeInvalidJSON() {
        let malformed = "{\"invalid_structure\": 123}".data(using: .utf8)!
        #expect(throws: Error.self) {
            try JSONDecoder().decode(FPLBootstrapData.self, from: malformed)
        }
    }
}

// MARK: - 2. Data Transformation & Formatting Tests
@Suite("Team & Player Transformation Tests")
struct DataTransformationTests {
    @Test("Player price formatting handles decimals correctly")
    func testPriceFormatting() {
        let player1 = Player(id: 1, firstName: "A", secondName: "B", webName: "AB", teamId: 1, elementTypeId: 1, nowCost: 61, totalPoints: 10)
        let player2 = Player(id: 2, firstName: "C", secondName: "D", webName: "CD", teamId: 1, elementTypeId: 1, nowCost: 100, totalPoints: 20)
        let player3 = Player(id: 3, firstName: "E", secondName: "F", webName: "EF", teamId: 1, elementTypeId: 1, nowCost: 45, totalPoints: 5)

        #expect(player1.formattedPrice == "£6.1m")
        #expect(player2.formattedPrice == "£10.0m")
        #expect(player3.formattedPrice == "£4.5m")
    }

    @Test("Player full name trims whitespace appropriately")
    func testFullName() {
        let player = Player(id: 1, firstName: "Erling", secondName: "Haaland", webName: "Haaland", teamId: 1, elementTypeId: 4, nowCost: 150, totalPoints: 60)
        #expect(player.fullName == "Erling Haaland")
    }

    @Test("Player count is correctly aggregated per team")
    @MainActor
    func testTeamPlayerCountCalculation() async {
        let sampleData = TestFixtures.sampleBootstrapData()
        let mockService = MockFPLService(result: .success(sampleData))
        let mockCache = MockFPLCache()
        let repo = FPLRepository(service: mockService, cache: mockCache)
        let vm = TeamsViewModel(repository: repo)

        await vm.loadData()

        if case .loaded(let items) = vm.state {
            let arsenalItem = items.first(where: { $0.team.id == 1 })
            let chelseaItem = items.first(where: { $0.team.id == 2 })

            // Arsenal has Raya, Saliba, Saka, Odegaard = 4 players
            #expect(arsenalItem?.playerCount == 4)
            // Chelsea has Palmer = 1 player
            #expect(chelseaItem?.playerCount == 1)
        } else {
            Issue.record("Expected state to be loaded")
        }
    }
}

// MARK: - 3. Squad Grouping & Search Filtering Tests
@Suite("Squad Grouping and Search Tests")
struct SquadViewModelTests {
    @Test("Players are grouped by position in canonical order (GK, DEF, MID, FWD)")
    @MainActor
    func testSquadGrouping() {
        let squadVM = SquadViewModel(
            team: TestFixtures.arsenal,
            players: [TestFixtures.saka, TestFixtures.raya, TestFixtures.saliba, TestFixtures.odegaard],
            positionsById: TestFixtures.positionsMap
        )

        #expect(squadVM.numberOfSections == 3) // GK, DEF, MID (no forwards in fixture)
        #expect(squadVM.sectionHeaderTitle(for: 0) == "Goalkeepers (1)")
        #expect(squadVM.sectionHeaderTitle(for: 1) == "Defenders (1)")
        #expect(squadVM.sectionHeaderTitle(for: 2) == "Midfielders (2)")
    }

    @Test("Players within a position section are ordered by total points descending")
    @MainActor
    func testOrderingByTotalPoints() {
        let squadVM = SquadViewModel(
            team: TestFixtures.arsenal,
            players: [TestFixtures.odegaard, TestFixtures.saka], // Saka: 45 pts, Odegaard: 20 pts
            positionsById: TestFixtures.positionsMap
        )

        #expect(squadVM.numberOfSections == 1)
        let firstPlayer = squadVM.player(atSection: 0, row: 0)
        let secondPlayer = squadVM.player(atSection: 0, row: 1)

        #expect(firstPlayer?.webName == "Saka")
        #expect(secondPlayer?.webName == "Ødegaard")
    }

    @Test("Search filtering updates results by web name and full name case-insensitively")
    @MainActor
    func testSearchFiltering() {
        let squadVM = SquadViewModel(
            team: TestFixtures.arsenal,
            players: [TestFixtures.raya, TestFixtures.saliba, TestFixtures.saka, TestFixtures.odegaard],
            positionsById: TestFixtures.positionsMap
        )

        // Search by webName
        squadVM.updateSearch(query: "saka")
        #expect(squadVM.numberOfSections == 1)
        #expect(squadVM.numberOfRows(in: 0) == 1)
        #expect(squadVM.player(atSection: 0, row: 0)?.webName == "Saka")

        // Search by firstName
        squadVM.updateSearch(query: "william")
        #expect(squadVM.numberOfSections == 1)
        #expect(squadVM.player(atSection: 0, row: 0)?.webName == "Saliba")

        // Search with non-matching term
        squadVM.updateSearch(query: "xyznonexistent")
        #expect(squadVM.numberOfSections == 0)
        #expect(squadVM.hasResults == false)

        // Clear search
        squadVM.updateSearch(query: "")
        #expect(squadVM.numberOfSections == 3)
        #expect(squadVM.hasResults == true)
    }
}

// MARK: - 4. Caching & Offline Behaviour Tests
@Suite("Caching and Offline Behaviour Tests")
struct CachingTests {
    @Test("FPLFileCache saves and retrieves data from disk")
    func testFileCacheSaveAndLoad() throws {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("test_fpl_cache_\(UUID().uuidString).json")
        let cache = FPLFileCache(fileURL: tempFileURL)

        let sample = TestFixtures.sampleBootstrapData()
        try cache.saveCachedData(sample)

        let loaded = cache.loadCachedData()
        #expect(loaded != nil)
        #expect(loaded?.teams.count == sample.teams.count)
        #expect(loaded?.elements.count == sample.elements.count)

        cache.clearCache()
        #expect(cache.loadCachedData() == nil)
    }

    @Test("Repository falls back to cached data when network fails on initial load")
    func testRepositoryOfflineFallback() async throws {
        let sample = TestFixtures.sampleBootstrapData()
        let mockService = MockFPLService(result: .failure(FPLError.networkError("No internet connection")))
        let mockCache = MockFPLCache(initialData: sample)

        let repo = FPLRepository(service: mockService, cache: mockCache)
        let loadedData = try await repo.loadData(forceRefresh: false)

        #expect(loadedData.teams.count == 2)
        #expect(loadedData.elements.count == 5)
    }
}

// MARK: - 5. Error Handling Tests
@Suite("Error Handling Tests")
struct ErrorHandlingTests {
    @Test("TeamsViewModel enters error state when network fails and no cache exists")
    @MainActor
    func testInitialLoadFailure() async {
        let mockService = MockFPLService(result: .failure(FPLError.networkError("Server unavailable")))
        let mockCache = MockFPLCache(initialData: nil)
        let repo = FPLRepository(service: mockService, cache: mockCache)
        let vm = TeamsViewModel(repository: repo)

        await vm.loadData()

        if case .error(let msg) = vm.state {
            #expect(msg.contains("Server unavailable"))
        } else {
            Issue.record("Expected state to be error")
        }
    }

    @Test("Refresh failure keeps existing data and emits refresh error message")
    @MainActor
    func testRefreshFailureKeepsExistingData() async {
        let sample = TestFixtures.sampleBootstrapData()
        let mockService = MockFPLService(result: .success(sample))
        let mockCache = MockFPLCache()
        let repo = FPLRepository(service: mockService, cache: mockCache)
        let vm = TeamsViewModel(repository: repo)

        // 1. Initial successful load
        await vm.loadData()
        #expect(vm.allTeams.count == 2)

        // 2. Simulate subsequent failure during pull-to-refresh
        mockService.result = .failure(FPLError.networkError("Connection timed out"))
        var refreshErrorMessage: String?
        vm.onRefreshError = { msg in
            refreshErrorMessage = msg
        }

        await vm.refreshData()

        // Existing data must remain visible
        #expect(vm.allTeams.count == 2)
        if case .loaded(let items) = vm.state {
            #expect(items.count == 2)
        } else {
            Issue.record("Existing data should remain loaded")
        }
        #expect(refreshErrorMessage != nil)
    }
}
