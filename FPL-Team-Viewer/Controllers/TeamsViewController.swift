import UIKit

@MainActor
public final class TeamsViewController: UIViewController {
    private let viewModel: TeamsViewModel
    private var displayItems: [TeamDisplayItem] = []

    // MARK: - UI Elements
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(TeamTableViewCell.self, forCellReuseIdentifier: TeamTableViewCell.reuseIdentifier)
        return table
    }()

    private let refreshControl = UIRefreshControl()
    private let loadingErrorView = LoadingErrorView()

    // MARK: - Initialization
    public init(viewModel: TeamsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public convenience init() {
        self.init(viewModel: TeamsViewModel())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        loadData()
    }

    // MARK: - Setup
    private func setupUI() {
        title = "Premier League"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemGroupedBackground

        // Setup TableView
        view.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handlePullToRefresh), for: .valueChanged)

        // Setup Loading / Error / Empty View
        view.addSubview(loadingErrorView)
        loadingErrorView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            loadingErrorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            loadingErrorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingErrorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingErrorView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupBindings() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
            self.render(state: state)
        }

        viewModel.onRefreshError = { [weak self] errorMessage in
            guard let self = self else { return }
            self.refreshControl.endRefreshing()
            self.showRefreshErrorAlert(message: errorMessage)
        }
    }

    private func render(state: TeamsViewState) {
        switch state {
        case .loading:
            loadingErrorView.configure(for: .loading("Loading teams..."))
            tableView.isHidden = true

        case .loaded(let items):
            self.displayItems = items
            loadingErrorView.configure(for: .hidden)
            tableView.isHidden = false
            tableView.reloadData()
            updateOfflineIndicator()

        case .error(let message):
            tableView.isHidden = true
            loadingErrorView.configure(for: .error(message) { [weak self] in
                self?.loadData()
            })

        case .empty:
            tableView.isHidden = true
            loadingErrorView.configure(for: .empty("No teams found."))
        }
    }

    private func updateOfflineIndicator() {
        if viewModel.isOfflineData {
            let offlineLabel = UILabel()
            offlineLabel.text = "Offline Mode"
            offlineLabel.font = .systemFont(ofSize: 12, weight: .semibold)
            offlineLabel.textColor = .secondaryLabel
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: offlineLabel)
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func showRefreshErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Refresh Failed",
            message: "\(message)\n\nPreviously loaded data is still available.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Actions
    private func loadData() {
        Task {
            await viewModel.loadData()
        }
    }

    @objc private func handlePullToRefresh() {
        Task {
            await viewModel.refreshData()
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension TeamsViewController: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayItems.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TeamTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? TeamTableViewCell else {
            return UITableViewCell()
        }

        let item = displayItems[indexPath.row]
        cell.configure(with: item)
        return cell
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = displayItems[indexPath.row]
        let squadViewModel = viewModel.squadViewModel(for: item.team)
        let squadVC = SquadViewController(viewModel: squadViewModel)
        navigationController?.pushViewController(squadVC, animated: true)
    }
}
