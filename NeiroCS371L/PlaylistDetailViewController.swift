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
    
    private var currentDeviceId: String?

    
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
    
    private let openSpotifyMsg = "Open the Spotify app, start any song, then come back to Neiro.\nMust have Spotify Premium!\n\n(We know, it's annoying :/)"
    
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
    // MARK: - Playback
    // Now uses Spotify Web API playback instead of local 30s previews
    private func playSnippet(for song: Song, at indexPath: IndexPath) {
        // Toggle off if already playing this row
        if currentlyPlayingIndex == indexPath {
            stopPlayback()
            return
        }
        
        // stop any existing playback / UI state
        stopPlayback()
        
        // Make sure we're connected to Spotify
        guard SpotifyUserAuthorization.shared.isConnected else {
            showAlert(title: "Not Connected", message: "Please connect your Spotify account.")
            return
        }
        
        // Search for song on Spotify by title and artist
        let query = "\(song.title) \(song.artist ?? "")"
        
        SpotifyAPI.shared.searchTracks(query: query, limit: 1) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let tracks):
                guard let track = tracks.first else {
                    print("No track found for query: \(query)")
                    return
                }
                
                // Use the track's Spotify URI for playback
                let trackURI = track.uri
                
                DispatchQueue.main.async {
                    self.startPlayback(urlString: trackURI, at: indexPath)
                }
                
            case .failure(let error):
                print("Search didn't work: \(error)")
            }
        }
    }

    private func startPlayback(urlString trackURI: String, at indexPath: IndexPath) {
        // 1) Get a valid token (this may refresh)
        SpotifyUserAuthorization.shared.getValidAccessToken { [weak self] token in
            guard let self = self else { return }
            
            // No token → show alert and bail
            guard let accessToken = token else {
                DispatchQueue.main.async {
                    self.showAlert(
                        title: "Not Connected",
                        message: "Please connect your Spotify account."
                    )
                }
                return
            }
            
            // 2) Get an active Spotify device (phone, speaker, etc.)
            self.fetchActiveDevice(accessToken: accessToken) { [weak self] deviceId in
                guard let self = self else { return }
                
                guard let deviceId = deviceId else {
                    // No active device found: tell user what to do
                    DispatchQueue.main.async {
                        self.showAlert(
                            title: "No Active Spotify Device",
                            message: self.openSpotifyMsg
                        )
                    }
                    return
                }
                
                self.currentDeviceId = deviceId
                
                // 3) Build the request: PUT /v1/me/player/play?device_id=... with body { "uris": [...] }
                var components = URLComponents(string: "https://api.spotify.com/v1/me/player/play")!
                components.queryItems = [
                    URLQueryItem(name: "device_id", value: deviceId)
                ]
                
                guard let url = components.url else {
                    print("Invalid Spotify play URL with device_id")
                    return
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "PUT"
                request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body: [String: Any] = ["uris": [trackURI]]
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                } catch {
                    print("Failed to encode play body: \(error)")
                    return
                }
                
                // Cancel any existing timer observer (snippet timer)
                if let timer = self.playbackObserver as? Timer {
                    timer.invalidate()
                    self.playbackObserver = nil
                }
                
                URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("Error starting Spotify playback: \(error)")
                        return
                    }
                    
                    if let http = response as? HTTPURLResponse {
                        let status = http.statusCode
                        let bodyString = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                        print("Spotify play response status: \(status), body: \(bodyString)")
                        
                        if (200...299).contains(status) || status == 204 {
                            // Success – update UI on main thread
                            DispatchQueue.main.async {
                                self.currentlyPlayingIndex = indexPath
                                self.tableView.reloadRows(at: [indexPath], with: .none)
                                
                                // Auto-stop after ~30 seconds to mimic "snippet" behavior
                                let timer = Timer.scheduledTimer(
                                    withTimeInterval: 30.0,
                                    repeats: false
                                ) { [weak self] _ in
                                    self?.stopPlayback()
                                }
                                self.playbackObserver = timer
                            }
                        } else if status == 404 {
                            // Still no active device – show guidance
                            DispatchQueue.main.async {
                                self.showAlert(
                                    title: "No Active Spotify Device",
                                    message: self.openSpotifyMsg
                                )
                            }
                        } else {
                            print("Spotify play failed with status: \(status)")
                        }
                    }
                }.resume()
            }
        }
    }



    private func stopPlayback() {
        // Stop any local AVPlayer if it was ever used
        player?.pause()
        player = nil
        
        // Cancel the snippet timer if present
        if let timer = playbackObserver as? Timer {
            timer.invalidate()
            playbackObserver = nil
        }
        
        // Clear UI state if a row was marked playing
        if let index = currentlyPlayingIndex {
            currentlyPlayingIndex = nil
            tableView.reloadRows(at: [index], with: .none)
        }
        
        // If we don't know which device we were playing on, don't pause anything remotely
        guard let deviceId = currentDeviceId else {
            return
        }
        
        // Get a valid token (may refresh)
        SpotifyUserAuthorization.shared.getValidAccessToken { [weak self] token in
            guard let self = self else { return }
            guard let accessToken = token else {
                return
            }
            
            var components = URLComponents(string: "https://api.spotify.com/v1/me/player/pause")!
            components.queryItems = [
                URLQueryItem(name: "device_id", value: deviceId)
            ]
            
            guard let url = components.url else {
                print("Invalid Spotify pause URL with device_id")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Error pausing Spotify playback: \(error)")
                    return
                }
                
                if let http = response as? HTTPURLResponse {
                    let status = http.statusCode
                    let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? "<no body>"
                    print("Spotify pause response status: \(status), body: \(body)")
                }
            }.resume()
        }
    }

    
    private func fetchActiveDevice(accessToken: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.spotify.com/v1/me/player/devices") else {
            print("Invalid devices URL")
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching devices: \(error)")
                completion(nil)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let devices = json["devices"] as? [[String: Any]] else {
                print("Invalid devices response")
                completion(nil)
                return
            }
            
            // 🔍 Debug: print full devices list so we can see types/names
            print("Spotify devices JSON: \(devices)")
            
            // 1) Prefer a device whose *name* contains "iphone"
            let iphoneByName = devices.first { device in
                if let name = device["name"] as? String {
                    return name.lowercased().contains("iphone")
                }
                return false
            }
            
            // 2) Then any device whose *type* looks like a phone
            let phoneByType = devices.first { device in
                if let type = device["type"] as? String {
                    return type.lowercased().contains("phone")   // matches "Smartphone", "Phone", etc.
                }
                return false
            }
            
            // 3) Then any active, non-computer device (e.g. smart speaker, TV, etc.)
            let activeNotComputer = devices.first { device in
                let active = (device["is_active"] as? Bool) == true
                let type = (device["type"] as? String ?? "").lowercased()
                return active && type != "computer"
            }
            
            // ❗️We do NOT fall back to computer/web here.
            let chosen = iphoneByName ?? phoneByType ?? activeNotComputer
            
            guard let chosen = chosen,
                  let deviceId = chosen["id"] as? String else {
                print("No suitable mobile device found (won't use laptop).")
                completion(nil)   // let caller show "open Spotify app on your phone" message
                return
            }
            
            let name = chosen["name"] as? String ?? "<unknown>"
            let type = chosen["type"] as? String ?? "<unknown>"
            let isActive = (chosen["is_active"] as? Bool) == true
            print("Using Spotify device: \(name) [\(type)] active=\(isActive) (\(deviceId))")
            
            completion(deviceId)
        }.resume()
    }



    
    @objc private func backTapped() {
        onSave?(playlist)
        navigationController?.popViewController(animated: true)
    }
    
    //updated update playlist button to now route to LLM Screen so users have the option to update the playlist based on English language preferences
    @objc private func updatePlaylistTapped() {
        
        //check if still connected to Spotify
        guard SpotifyUserAuthorization.shared.isConnected else {
            showAlert(title: "Not Connected", message: "Please connect Spotify account.")
            return
        }
        
        let describeVC = DescribeLLMViewController()
        describeVC.updatingPlaylist = playlist
        
        // callback after updating the playlist through Gemini
        describeVC.onUpdate = { [weak self] updatedPlaylist in
            guard let self = self else { return }
            
            // update local playlist with emoji, artists, timestamp
            self.playlist = updatedPlaylist
            self.emojiLabel.text = updatedPlaylist.emoji
            self.playlistNameLabel.text = updatedPlaylist.title
            let artists = Array(Set(updatedPlaylist.songs.compactMap{ $0.artist})).prefix(3)
            self.artistsLabel.text = artists.isEmpty ? "Various Artists" : artists.joined(separator: ", ")
            self.timestampLabel.text = Self.dateFormatter.string(from: updatedPlaylist.createdAt)
            
            self.tableView.reloadData()
            
            // call onSave callback
            self.onSave?(updatedPlaylist)
            
        }
        
        // push LLM screen back onto nav controller
        if let nav = navigationController {
            nav.pushViewController(describeVC, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: describeVC)
            nav.modalPresentationStyle = .formSheet
            present(nav, animated: true)
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
