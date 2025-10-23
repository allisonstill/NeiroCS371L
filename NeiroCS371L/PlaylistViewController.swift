//
//  Playlist.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/21/25.
//

import UIKit

final class PlaylistViewController: UITableViewController {

    // Demo data (TODO: swap with Firebase later)
    var playlists: [Playlist] = [
        Playlist.demo,
        Playlist(title: "Late Night Lo-Fi", emoji: "😴",
                 songs: [
                    Song(title: "Warmth", artist: "Keys of Moon", genre: "Lo-Fi", lengthSeconds: 214),
                    Song(title: "Night Drive", artist: "Evoke", genre: "Lo-Fi", lengthSeconds: 189)
                 ]),
        Playlist(title: "Cardio Mix", emoji: "⚡️",
                 songs: [
                    Song(title: "Can’t Hold Us", artist: "Macklemore", genre: "Hip-Hop", lengthSeconds: 270),
                    Song(title: "Titanium", artist: "David Guetta", genre: "EDM", lengthSeconds: 245),
                    Song(title: "Stronger", artist: "Kanye West", genre: "Hip-Hop", lengthSeconds: 312)
                 ]),
    ]

    init() { super.init(style: .plain) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Playlists"
        navigationController?.navigationBar.prefersLargeTitles = true

        view.backgroundColor = ThemeColor.Color.backgroundColor

        tableView.register(ListCell.self, forCellReuseIdentifier: "ListCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 112
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)

        // Top-right "+" button
        let addAction = UIAction(title: "Add Playlist") { [weak self] _ in
            self?.addTapped()
        }
        let addItem = UIBarButtonItem(systemItem: .add, primaryAction: addAction)
        addItem.accessibilityLabel = "Add Playlist"

        // Set both forms (some containers read one or the other)
        navigationItem.rightBarButtonItem  = addItem
        navigationItem.rightBarButtonItems = [addItem]

        // (helps with visibility + layout)
        navigationItem.largeTitleDisplayMode = .always

    }

    private func addTapped() {
        let vc = CreatePlaylistViewController()
        vc.onCreate = { [weak self] newPlaylist in
            guard let self else { return }
            self.playlists.insert(newPlaylist, at: 0)
            self.tableView.reloadData()
        }

        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            // Fallback if this VC isn't inside a nav controller
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .formSheet
            present(nav, animated: true)
        }
    }

    // MARK: - Table Data
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        playlists.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let p = playlists[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListCell

        let date = Self.df.string(from: p.createdAt)
        let info = "\(p.songCount) songs • \(p.formattedLength) • \(date)"

        let pencil = UIImage(systemName: "pencil")
        let xmark  = UIImage(systemName: "xmark")

        cell.configure(
            image: nil,
            emoji: p.emoji,
            title: p.title,
            subtitle: info,
            trailingTopImage: pencil,
            trailingTopTap: { [weak self, weak tableView, weak cell] in
                guard let self,
                      let tableView,
                      let cell = cell,
                      let tappedIndexPath = tableView.indexPath(for: cell) else { return }
                self.changePlaylistName(at: tappedIndexPath)
            },
            trailingBottomImage: xmark,
            trailingBottomTap: { [weak self, weak tableView, weak cell] in
                guard let self,
                      let tableView,
                      let cell = cell,
                      let tappedIndexPath = tableView.indexPath(for: cell) else { return }
                self.deletePlaylist(at: tappedIndexPath)
            }
        )
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Navigate to detail screen with the selected playlist
        let detailVC = PlaylistDetailViewController()
        detailVC.playlist = playlists[indexPath.row]
        
        // saving playlist to this table view
        detailVC.onSave = { [weak self] updated in
                guard let self else { return }
                self.playlists[indexPath.row] = updated
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: TODO - firebase integration
    func changePlaylistName(at indexPath: IndexPath) {
        let current = playlists[indexPath.row]
        let alert = UIAlertController(title: "Rename Playlist",
                                      message: nil,
                                      preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "Playlist name"
            tf.text = current.title
            tf.clearButtonMode = .whileEditing
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            guard let self else { return }
            let newTitle = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !newTitle.isEmpty, newTitle != current.title else { return }

            // TODO: Firebase update later
            // Local update for now:
            self.playlists[indexPath.row].title = newTitle
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
        }))
        present(alert, animated: true)
    }
    
    private func deletePlaylist(at indexPath: IndexPath) {
        let playlist = playlists[indexPath.row]
        let ac = UIAlertController(
            title: "Delete \"\(playlist.title)\"?",
            message: "This will remove the playlist from your list.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
            guard let self else { return }
            self.playlists.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            // TODO: also delete from Firebase when integrated
        }))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func addPlaylist(_ new: Playlist) {
        playlists.insert(new, at: 0)
        tableView.reloadData()
    }
}
