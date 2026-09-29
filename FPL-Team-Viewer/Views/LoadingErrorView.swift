import UIKit

public final class LoadingErrorView: UIView {
    public enum State {
        case hidden
        case loading(String)
        case error(String, retryAction: (() -> Void)?)
        case empty(String)
    }

    private let containerStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .secondaryLabel
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 48),
            imageView.heightAnchor.constraint(equalToConstant: 48)
        ])
        return imageView
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = .secondaryLabel
        return label
    }()

    private let retryButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Retry"
        config.buttonSize = .medium
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config)
        return button
    }()

    private var retryHandler: (() -> Void)?

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        backgroundColor = .systemBackground

        addSubview(containerStackView)
        containerStackView.addArrangedSubview(activityIndicator)
        containerStackView.addArrangedSubview(iconImageView)
        containerStackView.addArrangedSubview(messageLabel)
        containerStackView.addArrangedSubview(retryButton)

        retryButton.addTarget(self, action: #selector(handleRetry), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerStackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            containerStackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            containerStackView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])
    }

    public func configure(for state: State) {
        switch state {
        case .hidden:
            isHidden = true
            activityIndicator.stopAnimating()
        case .loading(let message):
            isHidden = false
            iconImageView.isHidden = true
            retryButton.isHidden = true
            messageLabel.text = message
            activityIndicator.startAnimating()
        case .error(let message, let retryAction):
            isHidden = false
            activityIndicator.stopAnimating()
            iconImageView.isHidden = false
            iconImageView.image = UIImage(systemName: "exclamationmark.triangle")
            iconImageView.tintColor = .systemRed
            messageLabel.text = message
            self.retryHandler = retryAction
            retryButton.isHidden = (retryAction == nil)
        case .empty(let message):
            isHidden = false
            activityIndicator.stopAnimating()
            iconImageView.isHidden = false
            iconImageView.image = UIImage(systemName: "magnifyingglass")
            iconImageView.tintColor = .secondaryLabel
            messageLabel.text = message
            retryButton.isHidden = true
        }
    }

    @objc private func handleRetry() {
        retryHandler?()
    }
}
