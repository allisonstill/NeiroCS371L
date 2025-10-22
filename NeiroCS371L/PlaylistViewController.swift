import UIKit

final class PlaylistViewController: UITableViewController {

    // Demo data (swap with Firebase later)
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

        // Big emoji on the left, title + subtitle on the right
        cell.configure(image: nil, emoji: p.emoji, title: p.title, subtitle: info)
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // TODO: push a detail screen later
    }
}
