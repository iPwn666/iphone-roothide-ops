import UIKit

final class RootViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = .black

		let titleLabel = UILabel()
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		titleLabel.text = "TopOps Lens Fresh"
		titleLabel.textColor = .white
		titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
		titleLabel.textAlignment = .left
		titleLabel.numberOfLines = 1

		let badgeLabel = UILabel()
		badgeLabel.translatesAutoresizingMaskIntoConstraints = false
		badgeLabel.text = "Fresh Bundle UIKit Mode"
		badgeLabel.textColor = .white
		badgeLabel.font = .systemFont(ofSize: 13, weight: .semibold)
		badgeLabel.textAlignment = .center
		badgeLabel.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.25)
		badgeLabel.layer.borderColor = UIColor.systemOrange.withAlphaComponent(0.7).cgColor
		badgeLabel.layer.borderWidth = 1
		badgeLabel.layer.cornerRadius = 16
		badgeLabel.layer.masksToBounds = true

		let bodyLabel = UILabel()
		bodyLabel.translatesAutoresizingMaskIntoConstraints = false
		bodyLabel.text = "Verification build: pure UIKit window + view controller only. No SwiftUI view tree, no camera runtime, no Photos runtime."
		bodyLabel.textColor = UIColor.white.withAlphaComponent(0.82)
		bodyLabel.font = .systemFont(ofSize: 18, weight: .regular)
		bodyLabel.numberOfLines = 0

		let detailLabel = UILabel()
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.text = "If this stays open, the remaining issue was inside the previous UI stack rather than signing or deployment."
		detailLabel.textColor = UIColor.white.withAlphaComponent(0.58)
		detailLabel.font = .systemFont(ofSize: 14, weight: .regular)
		detailLabel.numberOfLines = 0

		let stack = UIStackView(arrangedSubviews: [badgeLabel, titleLabel, bodyLabel, detailLabel])
		stack.translatesAutoresizingMaskIntoConstraints = false
		stack.axis = .vertical
		stack.alignment = .leading
		stack.spacing = 18

		view.addSubview(stack)

		NSLayoutConstraint.activate([
			badgeLabel.heightAnchor.constraint(equalToConstant: 32),
			badgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 136),

			stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
			stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
			stack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
		])
	}
}
