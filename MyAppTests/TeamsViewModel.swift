import Foundation

// MARK: - Teams View State
public enum TeamsViewState: Equatable {
    case loading
    case loaded([TeamDisplayItem])
    case error(String)
    case empty
}

// MARK: - Teams ViewModel
@MainActor
public class TeamsViewModel {
    private let repository: FPLRepositoryProtocol

    public private(set) var state: TeamsViewState = .loading {
        didSet {
            onStateChange?(state)
        }
    }

    public private(set) var allTeams: [Team] = []
    public private(set) var allPlayers: [Player] = []
    public private(set) var positionsById: [Int: Position] = [:]
    public private(set) var isOfflineData: Bool = false

    public var onStateChange: ((TeamsViewState) -> Void)?
    public var onRefreshError: ((String) -> Void)?

    public init(repository: FPLRepositoryProtocol) {
        self.repository = repository
    }

    public convenience init() {
        self.init(repository: FPLRepository())
    }

    public func loadData() async {
        // If we already have cache available, present it immediately for instant responsiveness
        if let cached = repository.getCachedData(), allTeams.isEmpty {
            applyData(cached, isCachedFallback: true)
        } else {
            state = .loading
        }

        do {
            let data = try await repository.loadData(forceRefresh: false)
            applyData(data, isCachedFallback: false)
        } catch {
            if allTeams.isEmpty {
                state = .error(error.localizedDescription)
            } else {
                // If we already have cached data on screen, keep it visible and notify
                onRefreshError?(error.localizedDescription)
            }
        }
    }

    public func refreshData() async {
        do {
            let data = try await repository.loadData(forceRefresh: true)
            applyData(data, isCachedFallback: false)
        } catch {
            // Keep existing data visible and report refresh failure
            onRefreshError?("Failed to refresh: \(error.localizedDescription)")
        }
    }

    private func applyData(_ data: FPLBootstrapData, isCachedFallback: Bool) {
        self.allTeams = data.teams
        self.allPlayers = data.elements
        self.isOfflineData = isCachedFallback

        var posMap: [Int: Position] = [:]
        for pos in data.elementTypes {
            posMap[pos.id] = pos
        }
        self.positionsById = posMap

        // Compute display items with player counts
        let displayItems: [TeamDisplayItem] = data.teams.map { team in
            let count = data.elements.filter { $0.teamId == team.id }.count
            return TeamDisplayItem(team: team, playerCount: count)
        }

        if displayItems.isEmpty {
            state = .empty
        } else {
            state = .loaded(displayItems)
        }
    }

    public func squadViewModel(for team: Team) -> SquadViewModel {
        let teamPlayers = allPlayers.filter { $0.teamId == team.id }
        return SquadViewModel(team: team, players: teamPlayers, positionsById: positionsById)
    }
}
