import Foundation

// MARK: - Position Section
public struct PositionSection: Hashable, Sendable {
    public let position: Position
    public let players: [Player]

    public init(position: Position, players: [Player]) {
        self.position = position
        self.players = players
    }
}

// MARK: - Squad ViewModel
@MainActor
public class SquadViewModel {
    public let team: Team
    public let positionsById: [Int: Position]
    private let allSquadPlayers: [Player]

    public private(set) var visibleSections: [PositionSection] = []
    public private(set) var searchQuery: String = ""

    public var onUpdate: (() -> Void)?

    public init(
        team: Team,
        players: [Player],
        positionsById: [Int: Position]
    ) {
        self.team = team
        self.positionsById = positionsById
        self.allSquadPlayers = players
        recalculateSections()
    }

    public var title: String {
        return team.name
    }

    public var isSearchActive: Bool {
        return !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var hasResults: Bool {
        return !visibleSections.isEmpty
    }

    public func updateSearch(query: String) {
        self.searchQuery = query
        recalculateSections()
        onUpdate?()
    }

    private func recalculateSections() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        // Filter players based on search query
        let filteredPlayers: [Player]
        if trimmedQuery.isEmpty {
            filteredPlayers = allSquadPlayers
        } else {
            filteredPlayers = allSquadPlayers.filter { player in
                player.webName.lowercased().contains(trimmedQuery) ||
                player.fullName.lowercased().contains(trimmedQuery)
            }
        }

        // Group players by element_type (position id)
        var grouped: [Int: [Player]] = [:]
        for player in filteredPlayers {
            grouped[player.elementTypeId, default: []].append(player)
        }

        // Standard FPL position order: Goalkeepers (1), Defenders (2), Midfielders (3), Forwards (4)
        let sortedPositionIds = positionsById.keys.sorted()

        var sections: [PositionSection] = []
        for posId in sortedPositionIds {
            guard let playersInPos = grouped[posId], !playersInPos.isEmpty else {
                continue
            }
            // Sort by totalPoints descending (highest points first), then cost descending
            let sortedPlayers = playersInPos.sorted { p1, p2 in
                if p1.totalPoints != p2.totalPoints {
                    return p1.totalPoints > p2.totalPoints
                }
                return p1.nowCost > p2.nowCost
            }

            if let position = positionsById[posId] {
                sections.append(PositionSection(position: position, players: sortedPlayers))
            }
        }

        self.visibleSections = sections
    }

    // MARK: - Helpers
    public var numberOfSections: Int {
        return visibleSections.count
    }

    public func numberOfRows(in sectionIndex: Int) -> Int {
        guard sectionIndex < visibleSections.count else { return 0 }
        return visibleSections[sectionIndex].players.count
    }

    public func sectionHeaderTitle(for sectionIndex: Int) -> String {
        guard sectionIndex < visibleSections.count else { return "" }
        let sec = visibleSections[sectionIndex]
        return "\(sec.position.pluralName) (\(sec.players.count))"
    }

    public func player(atSection sectionIndex: Int, row rowIndex: Int) -> Player? {
        guard sectionIndex < visibleSections.count else { return nil }
        let sec = visibleSections[sectionIndex]
        guard rowIndex < sec.players.count else { return nil }
        return sec.players[rowIndex]
    }

    public func position(for player: Player) -> Position? {
        return positionsById[player.elementTypeId]
    }
}
