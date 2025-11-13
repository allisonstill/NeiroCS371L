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
    var isNewPlaylist: Bool = false
    
    private var tableView = UITableView()
    private var player: AVPlayer?
    private var currentlyPlayingIndex: IndexPath?
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
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupNavigationBar()
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
    
    deinit {
        stopPlayback()
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backTapped))
    
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )
    }
    
    private func configureHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(headerView)
        
        //adding gradient background
        let displayColors = playlist.gradientColors ?? generateGradientColors(from: playlist.emoji)
        if playlist.gradientColors == nil {
            playlist.gradientColors = displayColors
        }
        gradientView.colors = displayColors.map {$0.cgColor}
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
        
        setupRightContainerHeader(in: rightContainer)
        
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
  
        ])
    }
    
    private func setupRightContainerHeader(in container: UIView) {
        //playlist name
        playlistNameLabel.translatesAutoresizingMaskIntoConstraints = false
        playlistNameLabel.text = playlist.title
        playlistNameLabel.font = .systemFont(ofSize: 24, weight: .bold)
        playlistNameLabel.textColor = .white
        playlistNameLabel.numberOfLines = 2
        container.addSubview(playlistNameLabel)
        
        //features label
        featuresLabel.translatesAutoresizingMaskIntoConstraints = false
        featuresLabel.text = "Features:"
        featuresLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        featuresLabel.textColor = .white.withAlphaComponent(0.8)
        container.addSubview(featuresLabel)
        
        //artists list
        let artists = Array(Set(playlist.songs.compactMap {$0.artist})).prefix(3)
        artistsLabel.translatesAutoresizingMaskIntoConstraints = false
        artistsLabel.text = artists.isEmpty ? "Various Artists" : artists.joined(separator: ", ")
        if artists.count > 3 { artistsLabel.text! += ", and many more..." }
        artistsLabel.font = .systemFont(ofSize: 13)
        artistsLabel.textColor = .white.withAlphaComponent(0.9)
        artistsLabel.numberOfLines = 2
        container.addSubview(artistsLabel)
        
        //timestamp
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        timestampLabel.text = "Created At: \(formatter.string(from: playlist.createdAt))"
        timestampLabel.font = .systemFont(ofSize: 12)
        timestampLabel.textColor = .white.withAlphaComponent(0.7)
        container.addSubview(timestampLabel)
        
        NSLayoutConstraint.activate([
            //playlist name
            playlistNameLabel.topAnchor.constraint(equalTo: container.topAnchor),
            playlistNameLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            playlistNameLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            //features label
            featuresLabel.topAnchor.constraint(equalTo: playlistNameLabel.bottomAnchor, constant: 12),
            featuresLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            featuresLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            //artists label
            artistsLabel.topAnchor.constraint(equalTo: featuresLabel.bottomAnchor, constant: 4),
            artistsLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            artistsLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            
            //timestamp label
            timestampLabel.topAnchor.constraint(equalTo: artistsLabel.bottomAnchor, constant: 8),
            timestampLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            timestampLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            timestampLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor)
        ])
    }
    
    private func configureUpdateButton() {
        updateButton.translatesAutoresizingMaskIntoConstraints = false
        updateButton.setTitle("Update Playlist", for: .normal)
        updateButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        updateButton.setTitleColor(.white, for: .normal)
        updateButton.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        updateButton.layer.cornerRadius = 8
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
        tableView.backgroundColor = ThemeColor.Color.backgroundColor
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SongRow.self, forCellReuseIdentifier: "SongRow")
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
        exportButton.setTitleColor(.systemGreen, for: .normal)
        exportButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        exportButton.addTarget(self, action: #selector(exportTapped), for: .touchUpInside)
        exportBlurView.contentView.addSubview(exportButton)

        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        exportButton.addSubview(activityIndicator)
        
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
            
            switch result {
            case .success(let tracks):
                guard let track = tracks.first, let previewURL = track.preview_url else {
                    print("There is no preview url")
                    return
                }
                
                DispatchQueue.main.async {
                    self?.startPlayback(urlString: previewURL, at: indexPath)
                }
                
            case .failure(let error):
                print("Search didn't work: \(error)")
            }
        }
    }
    
    private func startPlayback(urlString: String, at indexPath: IndexPath) {
        guard let url = URL(string: urlString) else {return}
        
        player = AVPlayer(url: url)
        player?.play()
        
        currentlyPlayingIndex = indexPath
        tableView.reloadRows(at: [indexPath], with: .none)
        
        playbackObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: 1), queue: .main) { [weak self] time in
            if time.seconds >= 30.0 {
                self?.stopPlayback()
            }
        }
    }
    
    private func stopPlayback() {
        player?.pause()
        
        if let observer = playbackObserver {
            player?.removeTimeObserver(observer)
            playbackObserver = nil
        }
        player = nil
        
        if let index = currentlyPlayingIndex {
            currentlyPlayingIndex = nil
            tableView.reloadRows(at: [index], with: .none)
        }
    }
    
    @objc private func backTapped() {
        onSave?(playlist)
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func updatePlaylistTapped() {
        guard SpotifyUserAuthorization.shared.isConnected else {
            showAlert(title: "Not Connected", message: "Please connect Spotify account.")
            return
        }
        
        // disable UI during update
        activityIndicator.startAnimating()
        updateButton.isEnabled = false
        view.isUserInteractionEnabled = false

        let emoji = playlist.emoji
        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount
        let excludedGenres = settings.excludedGenres

        SpotifyAPI.shared.generatePlaylist(
            for: emoji,
            targetSongCount: targetCount,
            excludedGenres: excludedGenres
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.activityIndicator.stopAnimating()
                self.updateButton.isEnabled = true
                self.view.isUserInteractionEnabled = true

                switch result {
                case .success(let newSongs):

                    let uniqueSongs = Dictionary(grouping: newSongs, by: { "\($0.title)_\($0.artist ?? "")" })
                        .compactMap { $0.value.first }
                    
                    // update song list
                    self.playlist.songs = uniqueSongs

                    PlaylistLibrary.updatePlaylist(self.playlist)

                    // update artist header
                    let artists = Array(Set(uniqueSongs.compactMap { $0.artist })).prefix(3)
                    self.artistsLabel.text = artists.isEmpty ? "Various Artists" : artists.joined(separator: ", ")

                    // refresh UI
                    self.tableView.reloadData()

                    self.showAlert(title: "Playlist Updated", message: "Your playlist has been updated!")

                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func exportTapped() {
        setExport(isExporting: true)
        
        guard SpotifyUserAuthorization.shared.isConnected else {
            showAlert(title: "Not Connected", message: "Please connect Spotify account")
            return
        }
        
        SpotifyAPI.shared.exportPlaylist(playlist: playlist) {[weak self] result in
            DispatchQueue.main.async {
                self?.setExport(isExporting: false)
                self?.performExport(result)
            }
        }
    }
    
    private func setExport(isExporting: Bool) {
        if isExporting {
            activityIndicator.startAnimating()
            exportButton.setTitle("Exporting...", for: .normal)
            exportButton.isEnabled = false
        } else {
            activityIndicator.stopAnimating()
            exportButton.setTitle("Export to Spotify", for: .normal)
            exportButton.isEnabled = true
        }
    }
    
    private func performExport(_ result: Result<String, Error>) {
        switch result {
        case .success(let url):
            showAlert(title: "Success", message: "Playlist was exported to Spotify at url: \(url)")
                    
        case .failure(let error):
            showAlert(title: "Export failed", message: error.localizedDescription)
        }
    }
    
    @objc private func shareTapped() {
        let text = "\(playlist.emoji) \(playlist.title) \n \(playlist.songCount) songs in total."
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        present(activityVC, animated: true)
        
    }
    
    private func showNewPlaylistAlert() {
        showAlert(title: "Playlist Created", message: "Your new playlist is ready!")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
    private let albumImageView = UIImageView()
    
    var playHandler: (() -> Void)?
    var isPlaying: Bool = false {
        didSet {
            let symbol = isPlaying ? "pause.circle.fill" : "play.circle.fill"
            playButton.setImage(UIImage(systemName: symbol), for: .normal)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func configureUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        
        //album image
        albumImageView.translatesAutoresizingMaskIntoConstraints = false
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.layer.cornerRadius = 8
        albumImageView.clipsToBounds = true
        albumImageView.backgroundColor = .systemGray5
        contentView.addSubview(albumImageView)
        
        //labels stack
        let stackV = UIStackView()
        stackV.axis = .vertical
        stackV.spacing = 4
        stackV.translatesAutoresizingMaskIntoConstraints = false
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 1

        artistLabel.font = .systemFont(ofSize: 14, weight: .regular)
        artistLabel.textColor = .lightGray
        artistLabel.numberOfLines = 1
        
        stackV.addArrangedSubview(titleLabel)
        stackV.addArrangedSubview(artistLabel)
        contentView.addSubview(stackV)

        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.tintColor = .systemGreen
        let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
        playButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: config), for: .normal)
        playButton.addTarget(self, action: #selector(didTapPlay), for: .touchUpInside)
        contentView.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            albumImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            albumImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            albumImageView.widthAnchor.constraint(equalToConstant: 56),
            albumImageView.heightAnchor.constraint(equalToConstant: 56),
                        
            stackV.leadingAnchor.constraint(equalTo: albumImageView.trailingAnchor, constant: 12),
            stackV.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackV.trailingAnchor.constraint(equalTo: playButton.leadingAnchor, constant: -12),
                        
            playButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            playButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 44),
            playButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }


    func configure(with song: Song) {
        titleLabel.text = song.title
        artistLabel.text = song.artist ?? "Unknown Artist"
        
        albumImageView.image = nil
        albumImageView.backgroundColor = .systemGray5
        
        if let urlString = song.albumURL, !urlString.isEmpty, let url = URL(string: urlString) {
            loadImage(from: url)
        } else {
            showPlaceholder()
        }
    }
    
    private func loadImage(from url: URL) {
        albumImageView.contentMode = .scaleAspectFill
        albumImageView.backgroundColor = .systemGray5
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else {return}
            
            if error != nil {
                DispatchQueue.main.async { self.showPlaceholder() }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                DispatchQueue.main.async { self.showPlaceholder() }
                return
            }
            
            DispatchQueue.main.async {
                self.albumImageView.image = image
                self.albumImageView.backgroundColor = .clear
            }
        }.resume()
    }
    
    private func showPlaceholder() {
        albumImageView.image = UIImage(systemName: "music.note")
        albumImageView.tintColor = .systemGray
        albumImageView.contentMode = .center
        albumImageView.backgroundColor = .systemGray5
    }

    @objc private func didTapPlay() { playHandler?() }
}
