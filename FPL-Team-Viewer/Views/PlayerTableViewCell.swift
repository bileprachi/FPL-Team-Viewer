import UIKit

public final class PlayerTableViewCell: UITableViewCell {
    public static let reuseIdentifier = "PlayerTableViewCell"

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textColor = .label
        return label
    }()

    private let fullNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }()

    private let positionBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 11, weight: .semibold)
        label.textColor = .secondaryLabel
        label.backgroundColor = .secondarySystemFill
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 20)
        ])
        return label
    }()

    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .label
        label.textAlignment = .right
        return label
    }()

    private let pointsBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .systemBlue
        label.textAlignment = .right
        return label
    }()

    private let nameStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        return stack
    }()

    private let statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .trailing
        return stack
    }()

    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override public init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    private func setupViews() {
        selectionStyle = .none

        nameStackView.addArrangedSubview(nameLabel)
        nameStackView.addArrangedSubview(fullNameLabel)
        nameStackView.addArrangedSubview(positionBadge)

        statsStackView.addArrangedSubview(priceLabel)
        statsStackView.addArrangedSubview(pointsBadge)

        mainStackView.addArrangedSubview(nameStackView)
        mainStackView.addArrangedSubview(statsStackView)

        // Make sure stats stay right-aligned without clipping
        statsStackView.setContentCompressionResistancePriority(.required, for: .horizontal)
        nameStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        contentView.addSubview(mainStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            mainStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            mainStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }

    public func configure(with player: Player, position: Position?) {
        nameLabel.text = player.webName
        fullNameLabel.text = player.fullName
        if let pos = position {
            positionBadge.text = "  \(pos.singularName)  "
            positionBadge.isHidden = false
        } else {
            positionBadge.isHidden = true
        }
        priceLabel.text = player.formattedPrice
        pointsBadge.text = "\(player.totalPoints) pts"
    }
}
