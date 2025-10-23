//
//  CreatePlaylistViewController.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/20/25.
//

import UIKit

final class CreatePlaylistViewController: UIViewController {

    // Callback to return a new playlist to the list VC
    var onCreate: ((Playlist) -> Void)?

    // Easily editable emoji set
    var emojis: [String] = ["😀","😎","🥲","😭",
                            "🤪","🤩","😴","😐",
                            "😌","🙂","🙃","😕",
                            "🔥","❤️","⚡️","➕"]

    private var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Playlist"
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupCollection()
        setupButtons()
    }

    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45)
        ])
    }

    private func setupButtons() {
        let makeRandom = primaryButton("Select Random Playlist Mood")
        makeRandom.addTarget(self, action: #selector(randomTapped), for: .touchUpInside)

        let describe = secondaryButton("Describe Your Own Playlist")
        describe.addTarget(self, action: #selector(describeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [makeRandom, describe])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func primaryButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = title
            config.baseBackgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
            config.baseForegroundColor = .label
            config.cornerStyle = .medium
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attrs = incoming; attrs.font = .systemFont(ofSize: 16, weight: .semibold); return attrs
            }
            button.configuration = config
            button.layer.cornerRadius = 12
            button.layer.masksToBounds = true
        } else {
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
            button.layer.cornerRadius = 12
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        }
        return button
    }

    private func secondaryButton(_ title: String) -> UIButton {
        let b = primaryButton(title)
        if #available(iOS 15.0, *) {
            if var config = b.configuration {
                config.baseBackgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.7)
                b.configuration = config
            } else {
                b.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.7)
            }
        } else {
            b.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.7)
        }
        return b
    }

    // MARK: Actions
    @objc private func randomTapped() {
        if let random = emojis.randomElement() {
            handleEmojiSelection(random)
        }
    }

    @objc private func describeTapped() {
        // placeholder for text/AI prompt integration later
        let ac = UIAlertController(title: "Coming Soon", message: "Describe feature not yet implemented.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(ac, animated: true)
    }

    private func handleEmojiSelection(_ emoji: String) {
        if let playlist = PlaylistLibrary.playlist(for: emoji) {
            let detailVC = PlaylistDetailViewController()
            detailVC.playlist = playlist
            detailVC.isNewPlaylist = true
            navigationController?.pushViewController(detailVC, animated: true)
            return
        }

        // Otherwise create a new one
        let new = Playlist(title: "New \(emoji) Playlist",
                           emoji: emoji,
                           createdAt: Date(),
                           songs: [])
        onCreate?(new)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Collection
extension CreatePlaylistViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { emojis.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
        cell.configure(emojis[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 4
        let spacing: CGFloat = 12 * (columns + 1)
        let width = (collectionView.bounds.width - spacing) / columns
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = emojis[indexPath.item]
        handleEmojiSelection(emoji)
    }
}

// MARK: - Emoji Cell
final class EmojiCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 14
        contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)

        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func configure(_ emoji: String) {
        label.text = emoji
    }
}
