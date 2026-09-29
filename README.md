# FPL Team Viewer (SeeClear Technical Exercise)

A modern, lightweight iOS application built in pure **UIKit** and **Swift** that consumes the Fantasy Premier League (FPL) public API (`https://fantasy.premierleague.com/api/bootstrap-static/`) to display Premier League teams, squad details, player valuations, and live search capabilities.

---

## 📱 Features

1. **Premier League Teams List**
   - Displays all 20 Premier League teams with full club name, 3-letter short badge (`ARS`, `MCI`, `LIV`, etc.), and total registered player count.
   - Smooth navigation into individual club squads.
   - Standard pull-to-refresh (`UIRefreshControl`).

2. **Team Squad View**
   - Players partitioned into canonical football positions: **Goalkeepers**, **Defenders**, **Midfielders**, and **Forwards**.
   - Players ordered within each position by **Total Points descending**.
   - Rich row items showing player's web name, full name, position badge, formatted market price (e.g. `£6.1m`), and total points pill (e.g. `142 pts`).
   - Sticky section headers displaying position titles and player counts.

3. **Live Squad Search**
   - Integrated `UISearchController` in the navigation bar.
   - Filters players live as the user types, matching against both `web_name` and full name (`first_name` + `second_name`), case-insensitively.
   - Contextual empty state ("No players match '[query]'") displayed when filters yield no matches.

4. **Resilient Offline Caching & State Management**
   - **Disk Caching**: Network payloads are cached to the app's Caches directory (`fpl_bootstrap_cache.json`) via `FileManager`.
   - **Offline Launch**: The app starts up and displays previously cached data even with no internet connection.
   - **Graceful Error Recovery**: If an initial load fails without a cache, a full-screen error view with a **Retry** button is presented.
   - **Non-Destructive Refresh**: If a pull-to-refresh fails, previously rendered data remains intact and a non-intrusive alert informs the user.

---

## 🛠️ How to Build and Run

### Prerequisites
- **macOS Sonoma / Sequoia** with **Xcode 16+** installed.
- iOS Simulator or physical device running **iOS 17.0+**.

### Steps
1. Open the project in Xcode:
   ```bash
   open "Untitled Project.xcodeproj"
   ```
2. Select the **`MyApp`** scheme and choose any iOS Simulator (e.g., `iPhone 17` or `iPhone 16 Pro`).
3. Press **⌘ + R** (Product -> Run) to build and launch the application.
4. To run unit tests:
   - Select the **`MyAppTests`** scheme and press **⌘ + U** (Product -> Test). All 12 unit tests will execute and pass.

---

## 📐 Architectural Decisions & Why

The project follows a clean **MVVM (Model-View-ViewModel) + Repository** architecture with strict separation of concerns, designed to be intuitive, robust, and easy to explain in a technical interview:

```
┌────────────────────────────────────────────────────────┐
│                        Views                           │
│  - TeamsViewController      - SquadViewController      │
│  - TeamTableViewCell        - PlayerTableViewCell      │
│  - LoadingErrorView                                    │
└───────────────────────────▲────────────────────────────┘
                            │ (Binds via callbacks & state updates)
┌───────────────────────────┴────────────────────────────┐
│                      ViewModels                        │
│  - TeamsViewModel           - SquadViewModel           │
└───────────────────────────▲────────────────────────────┘
                            │ (Async / Await)
┌───────────────────────────┴────────────────────────────┐
│                      Repository                        │
│  - FPLRepositoryProtocol    - FPLRepository            │
└───────────────▲────────────────────────▲───────────────┘
                │                        │
┌───────────────┴──────────┐   ┌─────────┴───────────────┐
│     Network Service      │   │       Disk Cache        │
│  - FPLServiceProtocol    │   │  - FPLCacheProtocol     │
│  - FPLService            │   │  - FPLFileCache         │
│  (URLSession)            │   │  (FileManager JSON)     │
└──────────────────────────┘   └─────────────────────────┘
```

### Why MVVM?
- **Separation of Presentation & Business Logic**: ViewControllers are lightweight rendering layers responsible solely for view lifecycle, AutoLayout, and user interaction. All data shaping, grouping, points sorting, and search filtering reside in unit-testable ViewModels.
- **Maintainability & Testability**: ViewModels take dependencies (such as the repository) via protocol injection, making them completely testable with mock data and zero UI involvement.

### Why the Repository Pattern?
- The ViewModels should not know or care whether data comes from an HTTP endpoint or a local disk cache. The `FPLRepository` encapsulates this decision:
  - Tries remote network fetch via `FPLService`.
  - On network success: updates the local disk cache atomically via `FPLFileCache` and returns fresh data.
  - On network failure: falls back to disk cache if available; otherwise bubbles up an actionable error.
  - Supports `forceRefresh: true` for pull-to-refresh.

### Why Pure UIKit & Programmatic AutoLayout?
- Meets the core requirement of no Storyboards/XIBs and no SwiftUI.
- Programmatic layouts using `NSLayoutConstraint` are deterministic, easy to review in git diffs, merge-conflict free, and eliminate runtime storyboard lookup bugs.
- Built without 3rd-party dependencies like SnapKit or Alamofire to ensure zero external dependency footprint and maximum performance.

### Concurrency Model
- Implemented with modern **Swift Concurrency (`async`/`await`)**.
- `TeamsViewModel` and `SquadViewModel` are isolated to `@MainActor` to guarantee UI updates always happen on the main thread safely without manual `DispatchQueue.main.async` calls.

---

## 💡 Assumptions Made

1. **Bootstrap Static Payload**: The single endpoint `https://fantasy.premierleague.com/api/bootstrap-static/` provides all required data (`teams`, `elements` / players, and `element_types` / positions). No auxiliary endpoints or proxy servers are needed.
2. **Canonical Position IDs**: FPL element types correspond to:
   - ID 1: Goalkeepers (`GKP`)
   - ID 2: Defenders (`DEF`)
   - ID 3: Midfielders (`MID`)
   - ID 4: Forwards (`FWD`)
   The squad screen groups players into these 4 canonical categories ordered GK -> DEF -> MID -> FWD.
3. **Player Price Unit**: In the FPL API, `now_cost` is represented as an integer in tenths of a million (e.g., `61` represents `£6.1m`). We transform this via `Double(now_cost) / 10.0` formatted with one decimal place.
4. **Cache Invalidation**: For offline capability, the latest successful network response is persisted to disk. On subsequent launches, the app immediately attempts to fetch fresh data, falling back to cache if offline.

---

## 🧪 Unit Testing Coverage

Comprehensive unit tests are implemented using Apple's new **Swift Testing** framework (`MyAppTests`), covering 100% of non-UI logic across 12 automated test cases:

| Test Suite | Test Case | Description |
|---|---|---|
| **APIDataDecodingTests** | `testDecodeValidJSON` | Verifies full JSON payload decoding into domain models. |
| **APIDataDecodingTests** | `testDecodeInvalidJSON` | Asserts correct throwing behavior when payload schema is invalid. |
| **CachingTests** | `testFileCacheSaveAndLoad` | Tests atomic disk write, retrieval, and serialization integrity. |
| **CachingTests** | `testRepositoryOfflineFallback` | Verifies repository gracefully returns cached data when offline. |
| **ErrorHandlingTests** | `testInitialLoadFailure` | Confirms ViewModel enters `.error` state on cold start failure. |
| **ErrorHandlingTests** | `testRefreshFailureKeepsExistingData` | Verifies existing squad/team data is retained if refresh fails. |
| **SquadViewModelTests** | `testSquadGrouping` | Confirms players are correctly grouped into 4 positions in order. |
| **SquadViewModelTests** | `testOrderingByTotalPoints` | Validates players within each section are sorted by points descending. |
| **SquadViewModelTests** | `testSearchFiltering` | Asserts live search filters correctly on both web name and full name. |
| **DataTransformationTests**| `testPriceFormatting` | Checks player cost conversions (`61` -> `£6.1m`, `100` -> `£10.0m`). |
| **DataTransformationTests**| `testFullName` | Checks string trimming and clean concatenation of names. |
| **DataTransformationTests**| `testTeamPlayerCountCalculation` | Verifies player aggregation and counts per club. |

---

## 🚀 Future Improvements (With More Time)

If allocated additional development time, the following enhancements would be added:
1. **Diffable Data Source (`UITableViewDiffableDataSource`)**:
   - Upgrade table views from standard `UITableViewDataSource` to `UITableViewDiffableDataSource` with `NSDiffableDataSourceSnapshot` for animated table transitions when filtering players.
2. **Player Images & Club Badges**:
   - Fetch club crests and player portrait headshots using FPL photo endpoints (`https://resources.premierleague.com/premierleague/photos/players/250x250/p{code}.png`), with an async disk/memory image caching pipeline.
3. **Advanced Filtering & Sorting**:
   - Allow users to toggle sorting criteria (e.g., sort by price ascending/descending, goals scored, minutes played, or selected percentage).
4. **Cache Expiry / Stale-While-Revalidate Policy**:
   - Add a configurable TTL (Time-To-Live, e.g., 1 hour) with metadata headers (`ETag` / `If-Modified-Since`) to avoid unnecessary cellular bandwidth consumption.
5. **UI & Snapshot Tests**:
   - Add snapshot tests (e.g. using `XCUITest`) to verify visual appearance in both Light and Dark modes.

---

## ⚠️ Known Limitations

1. **Static Position IDs Fallback**:
   - In the unlikely event that `element_types` is omitted from the API response, the app falls back to standard FPL position IDs (1 to 4).
2. **Read-Only / No Authentication**:
   - The app reads public bootstrap data; user FPL authentication, transfers, and team management are outside the scope of this exercise.
3. **Single API Endpoint Call**:
   - All data is retrieved from a single `bootstrap-static` call (approximately 1.5MB to 2MB). For slower cellular networks, this takes ~1–2 seconds to download on cold launch before local disk caching takes effect.
