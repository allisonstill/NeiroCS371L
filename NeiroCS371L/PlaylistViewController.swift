//
//  Playlist.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/21/25.
//

import UIKit

final class PlaylistViewController: UITableViewController {

    var playlists: [Playlist] = []

    private static let df: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()
    
    init() {
        super.init(style: .plain)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPlaylistsFromFirebase()
        
    }
    
    private func setupNavigationBar() {
        title = "Playlists"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        //add button on top right "+"
        let addAction = UIAction(title: "Add Playlist") { [weak self] _ in
            self?.addTapped()
        }
        let addItem = UIBarButtonItem(systemItem: .add, primaryAction: addAction)
        addItem.accessibilityLabel = "Add Playlist"
        
        navigationItem.rightBarButtonItem  = addItem
        navigationItem.rightBarButtonItems = [addItem]
    }
    
    private func setupTableView() {
        view.backgroundColor = ThemeColor.Color.backgroundColor

        tableView.register(ListCell.self, forCellReuseIdentifier: "ListCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 112
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 24, right: 0)

    }
    
    //data loading of playlists from firebase
    private func loadPlaylistsFromFirebase() {
        PlaylistLibrary.loadPlaylists{[weak self] success in
            guard let self = self else {return}
            if success {
                self.playlists = PlaylistLibrary.allPlaylists()
                self.playlistGradients()
                self.tableView.reloadData()
            } else {
                print("Failed to load playlists.")
            }
        }
    }
    
    //set up gradients for playlist backgrounds
    private func playlistGradients() {
        for playlist in playlists where playlist.gradientColors == nil {
            playlist.gradientColors = generateGradientColors(from: playlist.emoji)
        }
    }
    
    //generate gradient colors (UI purposes)
    private func generateGradientColors(from emoji: String) -> [UIColor] {
        let hash = emoji.hashValue
        let firstHue = CGFloat((hash & 0xFF)) / 255.0
        let secondHue = CGFloat(((hash >> 8) & 0xFF)) / 255.0
        
        let firstColor = UIColor(hue: firstHue, saturation: 0.6, brightness: 0.5, alpha: 1.0)
        let secondColor = UIColor(hue: secondHue, saturation: 0.6, brightness: 0.3, alpha: 1.0)
        
        return [firstColor, secondColor]
    }
    
    private func addTapped() {
        let vc = CreatePlaylistViewController()
        vc.onCreate = { [weak self] playlist in
            self?.loadPlaylistsFromFirebase()
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
        configureCell(cell, with: p, at: indexPath)
        return cell
    }
    
    private func configureCell(_ cell: ListCell, with playlist: Playlist, at indexPath: IndexPath) {
        
        let date = Self.df.string(from: playlist.createdAt)
        let info = "\(playlist.songCount) songs • \(playlist.formattedLength) • \(date)"

        let pencil = UIImage(systemName: "pencil")
        let xmark  = UIImage(systemName: "xmark")

        cell.configure(
            image: nil,
            emoji: playlist.emoji,
            title: playlist.title,
            subtitle: info,
            gradientColors: playlist.gradientColors,
            trailingTopImage: pencil,
            trailingTopTap: { [weak self] in
                self?.changePlaylistName(at: indexPath)
            },
            trailingBottomImage: xmark,
            trailingBottomTap: { [weak self] in
                self?.deletePlaylist(at: indexPath)
            }
        )
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Navigate to detail screen with the selected playlist
        let detailVC = PlaylistDetailViewController()
        detailVC.playlist = playlists[indexPath.row]
        
        // saving playlist to this table view
        detailVC.onSave = { [weak self] updated in
                guard let self else { return }
                PlaylistLibrary.updatePlaylist(updated) { [weak self] success in
                    if success {
                        self?.loadPlaylistsFromFirebase()
                    }
                }
            }
        
        navigationController?.pushViewController(detailVC, animated: true)
    }

    // MARK: TODO - firebase integration
    func changePlaylistName(at indexPath: IndexPath) {
        let playlist = playlists[indexPath.row]
        let alert = UIAlertController(title: "Rename Playlist",
                                      message: nil,
                                      preferredStyle: .alert)
        
        alert.addTextField { tf in
            tf.placeholder = "Playlist name"
            tf.text = playlist.title
            tf.clearButtonMode = .whileEditing
            tf.autocapitalizationType = .words
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            guard let newTitle = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newTitle.isEmpty else { return}

            playlist.title = newTitle
            PlaylistLibrary.updatePlaylist(playlist) { [weak self] success in
                if success {
                    self?.loadPlaylistsFromFirebase()
                }
            }
        })
        present(alert, animated: true)
    }
    
    private func deletePlaylist(at indexPath: IndexPath) {
        let playlist = playlists[indexPath.row]
        let ac = UIAlertController(
            title: "Delete \"\(playlist.title)\"?",
            message: "This will remove the playlist from your list.",
            preferredStyle: .alert
        )
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        ac.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            PlaylistLibrary.removePlaylist(playlist) { [weak self] success in
                if success {
                    self?.loadPlaylistsFromFirebase()
                }
            }
        })
        present(ac, animated: true)
    }
}
