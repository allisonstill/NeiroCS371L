//
//  PlaylistDetailViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 10/22/25.
//

import UIKit
import AVFoundation

final class PlaylistDetailViewController: UIViewController {

    var playlist: Playlist!
    var onSave: ((Playlist) -> Void)?
    private var tableView = UITableView()
    private var player: AVPlayer?
    private var currentlyPlayingIndex: IndexPath?
    private let saveButton = UIButton(type: .system)
    var isNewPlaylist: Bool = false
    private var tableBottomConstraint: NSLayoutConstraint!
    
    private let exportButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var playbackObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = playlist.title
        view.backgroundColor = ThemeColor.Color.backgroundColor
        configureTableView()
        configureExportButton()
        if isNewPlaylist {
                    configureSaveButton()
                    tableBottomConstraint.constant = -80 // leave space for the button
                } else {
                    tableBottomConstraint.constant = 0   // no button, table goes to bottom
                }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        
        if isNewPlaylist{
            showNewPlaylistAlert()
        }
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SongRow.self, forCellReuseIdentifier: "SongRow")
        view.addSubview(tableView)

        tableBottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableBottomConstraint
        ])
    }
    
    private func configureExportButton() {
        //only show if connected to spotify
        guard SpotifyUserAuthorization.shared.isConnected else { return }
        
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.setTitle("Export to Spotify", for: .normal)
        exportButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        exportButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.backgroundColor = .systemGreen
        exportButton.layer.cornerRadius = 12
        exportButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = "Export to Spotify"
            config.image = UIImage(systemName: "square.and.arrow.up")
            config.baseBackgroundColor = .systemGreen
            config.baseForegroundColor = .white
            config.cornerStyle = .medium
            config.imagePlacement = .leading
            config.imagePadding = 8
            config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16)
            exportButton.configuration = config
        }
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        exportButton.addSubview(activityIndicator)
        
        view.addSubview(exportButton)
        
        NSLayoutConstraint.activate([
            exportButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            exportButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exportButton.heightAnchor.constraint(equalToConstant: 44),
            
            activityIndicator.centerXAnchor.constraint(equalTo: exportButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: exportButton.centerYAnchor)
        ])
        
        if let topConstraint = tableView.constraints.first(where: {$0.firstAnchor == tableView.topAnchor}) {
            topConstraint.isActive = false
        }
        
        tableView.topAnchor.constraint(equalTo: exportButton.bottomAnchor, constant: 8).isActive = true
    }
    
    private func configureSaveButton() {
            saveButton.translatesAutoresizingMaskIntoConstraints = false
            saveButton.setTitle("Save Playlist", for: .normal)
            saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
            saveButton.setTitleColor(.white, for: .normal)
            saveButton.backgroundColor = .systemBlue
            saveButton.layer.cornerRadius = 12
            saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)

            view.addSubview(saveButton)
            NSLayoutConstraint.activate([
                saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                saveButton.heightAnchor.constraint(equalToConstant: 50)
            ])
        }

    // MARK: - Playback
    //TODO: Not sure if the play snippets are working yet
    private func playSnippet(for song: Song, at indexPath: IndexPath) {
        // Toggle off if already playing this row
        if currentlyPlayingIndex == indexPath {
            stopPlayback()
            return
        }
        
        stopPlayback()
        
        //search for song on Spotify by title and artist
        let query = "\(song.title) \(song.artist ?? "")"
        
        SpotifyAPI.shared.searchTracks(query: query, limit: 1) { [weak self] result in
            
            guard let self = self else {return}
            DispatchQueue.main.async {
                switch result {
                case .success(let tracks):
                    if let track = tracks.first, let previewURL = track.preview_url, let url = URL(string: previewURL) {
                        
                        self.player = AVPlayer(url: url)
                        self.currentlyPlayingIndex = indexPath
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                        
                        self.observePlaybackEnd()
                        self.player?.play()
                    } else {
                        self.playMockSound(for: song, at: indexPath)
                    }
                case .failure:
                    self.playMockSound(for: song, at: indexPath)
                }
            }
            
        }

    }
    
    private func playMockSound(for song: Song, at indexPath: IndexPath) {
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
        
        player = AVPlayer(url: soundURL)
        currentlyPlayingIndex = indexPath
        tableView.reloadData()
        
        observePlaybackEnd()
        player?.play()
    }
    
    @objc private func playerDidFinishPlaying() {
        currentlyPlayingIndex = nil
        tableView.reloadData()
    }
    
    private func observePlaybackEnd() {
        guard let player = player, let currentItem = player.currentItem else {return}
        
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackObserver = nil
        }
        
        playbackObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: currentItem, queue: .main) { [weak self] _ in
            self?.handlePlaybackEnd()
        }
    }
    
    private func stopPlayback() {
        player?.pause()
        player = nil
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackObserver = nil
        }
        
        if let index = currentlyPlayingIndex {
            currentlyPlayingIndex = nil
            tableView.reloadRows(at: [index], with: .none)
        }
    }
    
    private func handlePlaybackEnd() {
        if let index = currentlyPlayingIndex {
            currentlyPlayingIndex = nil
            tableView.reloadRows(at: [index], with: .none)
        }
        
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackObserver = nil
        }
    }
    
    @objc private func saveTapped() {
        let hadOnSave = (onSave != nil)
        onSave?(playlist)

        guard let nav = navigationController else { return }

        // 1) If PlaylistVC is on the stack, handle that case
        if let listVC = nav.viewControllers.compactMap({ $0 as? PlaylistViewController }).first {
            if !hadOnSave { listVC.addPlaylist(playlist) }
            nav.popToViewController(listVC, animated: true)
            return
        }

        // 2) Normal case with the container as root
        if let container = nav.viewControllers.first as? FloatingBarDemoViewController {
            // find the existing child instance of PlaylistViewController
            if let listVC = container.children.compactMap({ $0 as? PlaylistViewController }).first {
                if !hadOnSave { listVC.addPlaylist(playlist) }
                // pop all the way back to the container
                nav.popToRootViewController(animated: true)
                return
            }
        }

        // 3) Fallback: just pop one level
        nav.popViewController(animated: true)
    }
    
    @objc private func exportTapped() {
        guard SpotifyUserAuthorization.shared.isConnected else {
            showAlert(title: "Not Connected", message: "Please connect Spotify account")
            return
        }
        
        let alert = UIAlertController(title: "Export to Spotify", message: "This will create a new playlist in your Spotify account.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Export", style: .default) { [weak self] _  in
            
            self?.performExport()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func performExport() {
        exportButton.isEnabled = false
        activityIndicator.startAnimating()
        
        SpotifyAPI.shared.exportPlaylist(playlist: playlist) { [weak self] result in
            
            DispatchQueue.main.async {
                self?.exportButton.isEnabled = true
                self?.activityIndicator.stopAnimating()
                
                switch result{
                case .success(let url):
                    self?.showExportSuccess(url: url)
                    
                case .failure(let error):
                    self?.showAlert(title: "Export failed", message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showExportSuccess(url: String) {
        let alert = UIAlertController(title: "Success", message: "Playlist was exported to Spotify", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Open in Spotify", style: .default) { _  in
            if let spotifyURL = URL(string: url) {
                UIApplication.shared.open(spotifyURL)
            }
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func shareTapped() {
        let text = "\(playlist.emoji) \(playlist.title) \n \(playlist.songCount) songs in total."
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        present(activityVC, animated: true)
        
    }
    
    private func showNewPlaylistAlert() {
        let alert = UIAlertController(title: "Playlist Created", message: "Your new playlist is ready!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it!", style: .default))
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    deinit {
        stopPlayback()
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            
            self?.removeSong(at: indexPath)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func removeSong(at indexPath: IndexPath) {
        let song = playlist.songs[indexPath.row]
        playlist.removeSong(byID: song.id)
        tableView.deleteRows(at: [indexPath], with: .fade)
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
        
        layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        layer.borderWidth = 0.5
        layer.cornerRadius = 10
        layer.masksToBounds = true
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
        playButton.setContentHuggingPriority(.required, for: .horizontal)
        playButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, artistLabel])
        textStack.axis = .vertical
        textStack.spacing = 2

        // Flexible spacer pushes playButton to the right edge
        let spacer = UIView()

        let hStack = UIStackView(arrangedSubviews: [emojiLabel, textStack, spacer, playButton])
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
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
