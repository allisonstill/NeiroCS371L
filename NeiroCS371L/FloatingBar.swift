//
//  FloatingBar.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/19/25.
//

import UIKit

final class FloatingBar: UIView {

    // MARK: - API
    // Called when an item is tapped (0...4)
    var onTap: ((Int) -> Void)?

    // Programmatically select an item (updates tinting)
    func select(index: Int) {
        guard index >= 0 && index < itemViews.count else { return }
        itemViews.enumerated().forEach { i, v in v.isSelected = (i == index) }
    }

    // MARK: - Private UI
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
    private let stack = UIStackView()
    private var itemViews: [NavItemView] = []

    // Order: Playlists (also Home), History, Group, Settings
    private let items: [(title: String, symbol: String)] = [
        ("Playlist", "music.note"),
        ("History", "clock"),
        ("Group", "person.3.fill"),
        ("Settings", "gearshape.fill"),
    ]

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup
    private func setup() {
        // Card look
        layer.cornerRadius = 28
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: 6)

        // Blurred background
        blur.layer.cornerRadius = 28
        blur.clipsToBounds = true
        addSubview(blur)
        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        // Horizontal stack of items
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.spacing = 16
        blur.contentView.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: blur.contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: blur.contentView.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: blur.contentView.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: blur.contentView.trailingAnchor, constant: -20)
        ])

        // Build item views
        items.enumerated().forEach { idx, item in
            let view = NavItemView(symbolName: item.symbol, title: item.title)
            view.tag = idx
            view.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            itemViews.append(view)
            stack.addArrangedSubview(view)
        }

        // Default selection
        select(index: 0)
        isAccessibilityElement = false
        accessibilityElements = itemViews
    }

    @objc private func itemTapped(_ sender: UIControl) {
        select(index: sender.tag)
        onTap?(sender.tag)
    }
    
    // True - the icons will have a word under them (Home, Playlists, etc.)
    // False - just the icons
    func setShowCaptions(_ show: Bool) {
        itemViews.forEach { $0.showsCaption = show }
    }

}

// MARK: - NavItemView (icon + caption)
private final class NavItemView: UIControl {

    private let imageView = UIImageView()
    private let label = UILabel()
    private let vstack = UIStackView()

    // Toggle captions if you want icon-only later
    var showsCaption: Bool = true {
        didSet { label.isHidden = !showsCaption }
    }

    // Colors: selected vs unselected
    private var selectedTint: UIColor { .label }
    private var unselectedTint: UIColor { .secondaryLabel }

    init(symbolName: String, title: String) {
        super.init(frame: .zero)
        setupUI(symbolName: symbolName, title: title)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI(symbolName: "questionmark", title: "")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1.0 }
    }

    override var isSelected: Bool {
        didSet { applyState() }
    }

    private func setupUI(symbolName: String, title: String) {
        // Vertical stack
        vstack.axis = .vertical
        vstack.alignment = .center
        vstack.spacing = 4
        addSubview(vstack)
        vstack.isUserInteractionEnabled = false
        vstack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: topAnchor, constant: 6),
            vstack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
            vstack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6),
            vstack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6)
        ])

        // Icon – FIX: keep a fixed size + aspectFit so symbols never stretch
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        imageView.image = UIImage(systemName: symbolName, withConfiguration: config)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = unselectedTint
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 22),
            imageView.widthAnchor.constraint(equalToConstant: 22)
        ])
        // Keep icon from stretching horizontally
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        imageView.setContentHuggingPriority(.required, for: .vertical)
        imageView.setContentCompressionResistancePriority(.required, for: .vertical)

        // Caption – single line, truncates (prevents pushing on icon)
        label.text = title
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.textColor = unselectedTint
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        vstack.addArrangedSubview(imageView)
        vstack.addArrangedSubview(label)

        // Accessibility
        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
    }

    private func applyState() {
        imageView.tintColor = isSelected ? selectedTint : unselectedTint
        label.textColor = isSelected ? selectedTint : unselectedTint
    }
}
