//
//  PlaylistDetailViewController.swift .swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 10/22/25.
//

import UIKit
import AVFoundation

final class PlaylistDetailViewController: UIViewController {

    var playlist: Playlist!
    private var tableView = UITableView()
    private var player: AVAudioPlayer?
    private var currentlyPlayingIndex: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = playlist.title
        view.backgroundColor = ThemeColor.Color.backgroundColor
        configureTableView()
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SongRow.self, forCellReuseIdentifier: "SongRow")
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    // MARK: - Playback
    private func playSnippet(for song: Song, at indexPath: IndexPath) {
        // Toggle off if already playing this row
        if currentlyPlayingIndex == indexPath {
            player?.stop()
            currentlyPlayingIndex = nil
            tableView.reloadRows(at: [indexPath], with: .none)
            return
        }

        // Use a mock sound for now
        guard let soundURL = Bundle.main.url(forResource: "click", withExtension: "wav") else {
            print("Simulating playback for \(song.title)")
            currentlyPlayingIndex = indexPath
            tableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.currentlyPlayingIndex = nil
                self.tableView.reloadRows(at: [indexPath], with: .none)
            }
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: soundURL)
            player?.play()
            currentlyPlayingIndex = indexPath
            tableView.reloadData()
        } catch {
            print("Couldn’t play snippet:", error)
        }
    }
}

// MARK: - Table Delegate + DataSource
extension PlaylistDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        playlist.songs.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongRow",
                                                 for: indexPath) as! SongRow
        let song = playlist.songs[indexPath.row]
        cell.configure(with: song)
        cell.isPlaying = (indexPath == currentlyPlayingIndex)
        cell.playHandler = { [weak self] in
            self?.playSnippet(for: song, at: indexPath)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
}

// MARK: - Custom Song Cell
final class SongRow: UITableViewCell {

    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let artistLabel = UILabel()
    private let playButton = UIButton(type: .system)
    var playHandler: (() -> Void)?
    var isPlaying: Bool = false {
        didSet {
            let symbol = isPlaying ? "pause.circle.fill" : "play.circle.fill"
            playButton.setImage(UIImage(systemName: symbol), for: .normal)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = ThemeColor.Color.backgroundColor
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func configureUI() {
        emojiLabel.font = .systemFont(ofSize: 26)
        emojiLabel.text = "🎵"
        emojiLabel.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = .white

        artistLabel.font = .systemFont(ofSize: 14)
        artistLabel.textColor = .lightGray

        playButton.tintColor = .systemBlue
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        let hStack = UIStackView(arrangedSubviews: [emojiLabel, textStack, playButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 16
        hStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(hStack)
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10)
        ])
    }

    func configure(with song: Song) {
        titleLabel.text = song.title
        artistLabel.text = song.artist
    }

    @objc private func didTapPlay() { playHandler?() }
}
