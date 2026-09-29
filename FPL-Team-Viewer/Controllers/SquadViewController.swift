import UIKit

@MainActor
public final class SquadViewController: UIViewController {
    private let viewModel: SquadViewModel

    // MARK: - UI Elements
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(PlayerTableViewCell.self, forCellReuseIdentifier: PlayerTableViewCell.reuseIdentifier)
        return table
    }()

    private let searchController: UISearchController = {
        let search = UISearchController(searchResultsController: nil)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "Search player by name"
        search.searchBar.autocapitalizationType = .none
        return search
    }()

    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // MARK: - Initialization
    public init(viewModel: SquadViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }

    // MARK: - Setup
    private func setupUI() {
        title = viewModel.title
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = .systemGroupedBackground

        // Search Controller
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        // TableView
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self

        // Empty State Label
        view.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func setupBindings() {
        viewModel.onUpdate = { [weak self] in
            guard let self = self else { return }
            self.updateUI()
        }
    }

    private func updateUI() {
        tableView.reloadData()

        if viewModel.hasResults {
            emptyStateLabel.isHidden = true
            tableView.isHidden = false
        } else {
            tableView.isHidden = true
            emptyStateLabel.isHidden = false
            if viewModel.isSearchActive {
                emptyStateLabel.text = "No players found matching \"\(viewModel.searchQuery)\"."
            } else {
                emptyStateLabel.text = "No players available for this team."
            }
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SquadViewController: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(in: section)
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.sectionHeaderTitle(for: section)
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: PlayerTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? PlayerTableViewCell else {
            return UITableViewCell()
        }

        if let player = viewModel.player(atSection: indexPath.section, row: indexPath.row) {
            let position = viewModel.position(for: player)
            cell.configure(with: player, position: position)
        }

        return cell
    }
}

// MARK: - UISearchResultsUpdating
extension SquadViewController: UISearchResultsUpdating {
    public func updateSearchResults(for searchController: UISearchController) {
        let query = searchController.searchBar.text ?? ""
        viewModel.updateSearch(query: query)
    }
}
