import Foundation

// MARK: - API Response Model
public struct FPLBootstrapData: Codable, Sendable, Equatable {
    public let teams: [Team]
    public let elements: [Player]
    public let elementTypes: [Position]

    public init(teams: [Team], elements: [Player], elementTypes: [Position]) {
        self.teams = teams
        self.elements = elements
        self.elementTypes = elementTypes
    }

    enum CodingKeys: String, CodingKey {
        case teams
        case elements
        case elementTypes = "element_types"
    }
}

// MARK: - Team Model
public struct Team: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let shortName: String

    public init(id: Int, name: String, shortName: String) {
        self.id = id
        self.name = name
        self.shortName = shortName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case shortName = "short_name"
    }
}

// MARK: - Position Model
public struct Position: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let pluralName: String
    public let singularName: String
    public let shortName: String

    public init(id: Int, pluralName: String, singularName: String, shortName: String) {
        self.id = id
        self.pluralName = pluralName
        self.singularName = singularName
        self.shortName = shortName
    }

    enum CodingKeys: String, CodingKey {
        case id
        case pluralName = "plural_name"
        case singularName = "singular_name"
        case shortName = "singular_name_short"
    }
}

// MARK: - Player Model
public struct Player: Codable, Identifiable, Hashable, Sendable {
    public let id: Int
    public let firstName: String
    public let secondName: String
    public let webName: String
    public let teamId: Int
    public let elementTypeId: Int
    public let nowCost: Int        // Tenths of a million: e.g. 61 = £6.1m
    public let totalPoints: Int

    public init(
        id: Int,
        firstName: String,
        secondName: String,
        webName: String,
        teamId: Int,
        elementTypeId: Int,
        nowCost: Int,
        totalPoints: Int
    ) {
        self.id = id
        self.firstName = firstName
        self.secondName = secondName
        self.webName = webName
        self.teamId = teamId
        self.elementTypeId = elementTypeId
        self.nowCost = nowCost
        self.totalPoints = totalPoints
    }

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case secondName = "second_name"
        case webName = "web_name"
        case teamId = "team"
        case elementTypeId = "element_type"
        case nowCost = "now_cost"
        case totalPoints = "total_points"
    }

    public var fullName: String {
        return "\(firstName) \(secondName)".trimmingCharacters(in: .whitespaces)
    }

    public var formattedPrice: String {
        let millions = Double(nowCost) / 10.0
        return String(format: "£%.1fm", millions)
    }
}

// MARK: - UI Presentation Item for Team
public struct TeamDisplayItem: Identifiable, Hashable, Sendable {
    public var id: Int { team.id }
    public let team: Team
    public let playerCount: Int

    public init(team: Team, playerCount: Int) {
        self.team = team
        self.playerCount = playerCount
    }
}
