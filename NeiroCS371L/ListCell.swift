//
//  ListCell.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/21/25.
//

import UIKit

class ListCell: UITableViewCell {

    private let card = UIView()
    private let imgView = UIImageView()
    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let subLabel = UILabel()

    // Trailing vertical stack
    private let trailingStack = UIStackView()
    private let trailingTopIcon = UIImageView()
    private let trailingBottomIcon = UIImageView()

    private let lead = UIView()
    private let stackH = UIStackView()
    private let stackV = UIStackView()

    private var leadWidth: NSLayoutConstraint!
    private let leadSize: CGFloat = 56

    // Tap callbacks
    private var trailingTopTapHandler: (() -> Void)?
    private var trailingBottomTapHandler: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { super.init(coder: coder); setupUI() }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        // Card
        card.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 6
        card.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        // Lead (image/emoji)
        imgView.contentMode = .scaleAspectFill
        imgView.layer.cornerRadius = 12
        imgView.clipsToBounds = true
        imgView.isHidden = true

        emojiLabel.font = .systemFont(ofSize: 40)
        emojiLabel.textAlignment = .center
        emojiLabel.isHidden = true

        lead.addSubview(imgView)
        lead.addSubview(emojiLabel)
        imgView.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        lead.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: lead.topAnchor),
            imgView.bottomAnchor.constraint(equalTo: lead.bottomAnchor),
            imgView.leadingAnchor.constraint(equalTo: lead.leadingAnchor),
            imgView.trailingAnchor.constraint(equalTo: lead.trailingAnchor),
            emojiLabel.centerXAnchor.constraint(equalTo: lead.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: lead.centerYAnchor)
        ])
        leadWidth = lead.widthAnchor.constraint(equalToConstant: leadSize)
        leadWidth.isActive = true
        lead.heightAnchor.constraint(greaterThanOrEqualToConstant: leadSize).isActive = true

        // Text
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        subLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subLabel.textColor = .secondaryLabel
        subLabel.numberOfLines = 1

        stackV.axis = .vertical
        stackV.spacing = 4
        stackV.addArrangedSubview(titleLabel)
        stackV.addArrangedSubview(subLabel)

        // Trailing icons stack (right side, vertical)
        trailingStack.axis = .vertical
        trailingStack.alignment = .center
        trailingStack.spacing = 8
        trailingStack.isLayoutMarginsRelativeArrangement = false

        [trailingTopIcon, trailingBottomIcon].forEach { icon in
            icon.tintColor = .tertiaryLabel
            icon.contentMode = .scaleAspectFit
            icon.preferredSymbolConfiguration = .init(pointSize: 16, weight: .semibold)
            icon.isUserInteractionEnabled = true
            icon.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 20),
                icon.heightAnchor.constraint(equalToConstant: 20)
            ])
        }

        // Gestures
        let topTap = UITapGestureRecognizer(target: self, action: #selector(didTapTop))
        topTap.cancelsTouchesInView = true
        trailingTopIcon.addGestureRecognizer(topTap)

        let bottomTap = UITapGestureRecognizer(target: self, action: #selector(didTapBottom))
        bottomTap.cancelsTouchesInView = true
        trailingBottomIcon.addGestureRecognizer(bottomTap)

        trailingStack.addArrangedSubview(trailingTopIcon)
        trailingStack.addArrangedSubview(trailingBottomIcon)
        trailingStack.isHidden = true // hidden by default

        // Horizontal content
        stackH.axis = .horizontal
        stackH.alignment = .center
        stackH.spacing = 14
        stackH.addArrangedSubview(lead)
        stackH.addArrangedSubview(stackV)
        stackH.addArrangedSubview(UIView()) // flexible spacer
        stackH.addArrangedSubview(trailingStack)

        card.addSubview(stackH)
        stackH.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackH.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stackH.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            stackH.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            stackH.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])
    }

    // Configure
    func configure(
        image: UIImage? = nil,
        emoji: String? = nil,
        title: String,
        subtitle: String? = nil,
        trailingTopImage: UIImage? = nil,
        trailingTopTap: (() -> Void)? = nil,
        trailingBottomImage: UIImage? = nil,
        trailingBottomTap: (() -> Void)? = nil
    ) {
        titleLabel.text = title
        subLabel.text = subtitle
        subLabel.isHidden = (subtitle == nil)

        // Leading icon logic
        if let img = image {
            imgView.image = img
            imgView.isHidden = false
            emojiLabel.isHidden = true
            showLead(true)
        } else if let e = emoji {
            emojiLabel.text = e
            emojiLabel.isHidden = false
            imgView.isHidden = true
            showLead(true)
        } else {
            emojiLabel.isHidden = true
            imgView.isHidden = true
            showLead(false)
        }

        // Trailing icons
        trailingTopTapHandler = trailingTopTap
        trailingBottomTapHandler = trailingBottomTap

        trailingTopIcon.image = trailingTopImage
        trailingTopIcon.isHidden = (trailingTopImage == nil)

        trailingBottomIcon.image = trailingBottomImage
        trailingBottomIcon.isHidden = (trailingBottomImage == nil)
        trailingBottomIcon.tintColor = trailingBottomImage == nil ? .tertiaryLabel : .systemRed

        // Hide whole stack if both are nil
        trailingStack.isHidden = (trailingTopImage == nil && trailingBottomImage == nil)
    }

    @objc private func didTapTop()    { trailingTopTapHandler?() }
    @objc private func didTapBottom() { trailingBottomTapHandler?() }

    private func showLead(_ visible: Bool) {
        leadWidth.constant = visible ? leadSize : 0
        stackH.spacing = visible ? 14 : 8
    }
}
