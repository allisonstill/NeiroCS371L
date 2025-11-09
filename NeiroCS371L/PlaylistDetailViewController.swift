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
    var isNewPlaylist: Bool = false
    private var playbackObserver: Any?
    
    private let headerView = UIView()
    private let gradientView = CAGradientLayer()
    private let emojiLabel = UILabel()
    private let playlistNameLabel = UILabel()
    private let featuresLabel = UILabel()
    private let artistsLabel = UILabel()
    private let timestampLabel = UILabel()
    private let updateButton = UIButton(type: .system)
    private let exportButton = UIButton(type: .system)
    private let exportBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
    
    //private var tableBottomConstraint: NSLayoutConstraint!
    //private let saveButton = UIButton(type: .system)
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //title = playlist.title
        view.backgroundColor = ThemeColor.Color.backgroundColor
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backTapped))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareTapped))
        
        configureHeader()
        configureUpdateButton()
        configureTableView()
        configureExportButton()
        

        if isNewPlaylist{
            showNewPlaylistAlert()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientView.frame = headerView.bounds
    }
    
    private func configureHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        //adding gradient background
        let colors = generateGradientColors(from: playlist.emoji)
        gradientView.colors = colors.map {$0.cgColor}
        gradientView.startPoint = CGPoint(x: 0, y: 0)
        gradientView.endPoint = CGPoint(x: 1, y: 1)
        headerView.layer.insertSublayer(gradientView, at: 0)
        
        //emoji on left side of header
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.text = playlist.emoji
        emojiLabel.font = .systemFont(ofSize: 80)
        emojiLabel.textAlignment = .center
        headerView.addSubview(emojiLabel)
        
        //container on right
        let rightContainer = UIView()
        rightContainer.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(rightContainer)
        
        //playlist name
        playlistNameLabel.translatesAutoresizingMaskIntoConstraints = false
        playlistNameLabel.text = playlist.title
        playlistNameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        playlistNameLabel.textColor = .white
        playlistNameLabel.numberOfLines = 2
        rightContainer.addSubview(playlistNameLabel)
        
        //features label
        featuresLabel.translatesAutoresizingMaskIntoConstraints = false
        featuresLabel.text = "Features:"
        featuresLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        featuresLabel.textColor = .white.withAlphaComponent(0.8)
        rightContainer.addSubview(featuresLabel)
        
        //artists list
        let arists = Array(Set(playlist.songs.compactMap {$0.artist})).prefix(3)
        artistsLabel.translatesAutoresizingMaskIntoConstraints = false
        artistsLabel.text = arists.isEmpty ? "Various Artists" : arists.joined(separator: ", ")
        artistsLabel.font = .systemFont(ofSize: 13)
        artistsLabel.textColor = .white.withAlphaComponent(0.9)
        artistsLabel.numberOfLines = 2
        rightContainer.addSubview(artistsLabel)
        
        //timestamp
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        timestampLabel.text = "Created At: \(formatter.string(from: playlist.createdAt))"
        timestampLabel.font = .systemFont(ofSize: 12)
        timestampLabel.textColor = .white.withAlphaComponent(0.7)
        rightContainer.addSubview(timestampLabel)
        
        NSLayoutConstraint.activate([
            
            //header view
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            
            //emoji label
            emojiLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            emojiLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 100),
            
            //right container
            rightContainer.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 16),
            rightContainer.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            rightContainer.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            //playlist name
            playlistNameLabel.topAnchor.constraint(equalTo: rightContainer.topAnchor),
            playlistNameLabel.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            playlistNameLabel.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            
            //features label
            featuresLabel.topAnchor.constraint(equalTo: playlistNameLabel.bottomAnchor, constant: 12),
            featuresLabel.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            featuresLabel.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            
            //artists label
            artistsLabel.topAnchor.constraint(equalTo: featuresLabel.bottomAnchor, constant: 4),
            artistsLabel.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            artistsLabel.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            
            //timestamp label
            timestampLabel.topAnchor.constraint(equalTo: artistsLabel.bottomAnchor, constant: 8),
            timestampLabel.leadingAnchor.constraint(equalTo: rightContainer.leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: rightContainer.trailingAnchor),
            timestampLabel.bottomAnchor.constraint(lessThanOrEqualTo: rightContainer.bottomAnchor)
            
        ])
    }
    
    private func configureUpdateButton() {
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.setTitle("Update Playlist", for: .normal)
        updateButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        updateButton.setTitleColor(.white, for: .normal)
        updateButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        updateButton.layer.cornerRadius = 16
        updateButton.layer.borderWidth = 1
        updateButton.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        updateButton.addTarget(self, action: #selector(updatePlaylistTapped), for: .touchUpInside)
        view.addSubview(updateButton)
        
        NSLayoutConstraint.activate([
            updateButton.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 12),
            updateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateButton.widthAnchor.constraint(equalToConstant: 150),
            updateButton.heightAnchor.constraint(equalToConstant: 32)
            
        ])
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SongRow.self, forCellReuseIdentifier: "SongRow")
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: updateButton.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func configureExportButton() {
        //only show if connected to spotify
        guard SpotifyUserAuthorization.shared.isConnected else { return }
        
        //blur view behind export button
        exportBlurView.translatesAutoresizingMaskIntoConstraints = false
        exportBlurView.layer.cornerRadius = 0
        exportBlurView.clipsToBounds = true
        view.addSubview(exportBlurView)
        
        //export button
        exportButton.translatesAutoresizingMaskIntoConstraints = false
        exportButton.setTitle("Export to Spotify", for: .normal)
        exportButton.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        exportButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        exportButton.setTitleColor(.white, for: .normal)
        exportButton.tintColor = .white
        exportButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        exportButton.layer.cornerRadius = 12
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = "Export to Spotify"
            config.image = UIImage(systemName: "square.and.arrow.up")
            config.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
            config.baseForegroundColor = .white
            config.cornerStyle = .medium
            config.imagePlacement = .leading
            config.imagePadding = 8
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)
            exportButton.configuration = config
        }
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        exportButton.addSubview(activityIndicator)
        
        exportBlurView.contentView.addSubview(exportButton)
        
        NSLayoutConstraint.activate([
            exportBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            exportBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            exportBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            exportBlurView.heightAnchor.constraint(equalToConstant: 100),
            
            exportButton.centerXAnchor.constraint(equalTo: exportBlurView.centerXAnchor),
            exportButton.centerYAnchor.constraint(equalTo: exportBlurView.centerYAnchor, constant: -10),
            exportButton.heightAnchor.constraint(equalToConstant: 50),
            exportButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
            
            activityIndicator.centerXAnchor.constraint(equalTo: exportButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: exportButton.centerYAnchor)
        ])
    }
    /*
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
        }*/
    
    private func generateGradientColors(from emoji: String) -> [UIColor] {
        let hash = emoji.hashValue
        let firstHue = CGFloat((hash & 0xFF)) / 255.0
        let secondHue = CGFloat(((hash >> 8) & 0xFF)) / 255.0
        
        let firstColor = UIColor(hue: firstHue, saturation: 0.6, brightness: 0.5, alpha: 1.0)
        let secondColor = UIColor(hue: secondHue, saturation: 0.6, brightness: 0.3, alpha: 1.0)
        
        return [firstColor, secondColor]
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
    
    @objc private func backTapped() {
        onSave?(playlist)
        guard let nav = navigationController else {
            dismiss(animated: true)
            return
        }
        
        if let viewControllers = nav.viewControllers as? [UIViewController] {
            for vc in viewControllers.reversed() {
                if vc is PlaylistViewController {
                    nav.popToViewController(vc, animated: true)
                    return
                }
            }
        }
        nav.popViewController(animated: true)
    }
    
    @objc private func updatePlaylistTapped() {
        //TODO: fill this out to create a button to update the playlist!
    }
    
    /*@objc private func saveTapped() {
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
    }*/
    
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
