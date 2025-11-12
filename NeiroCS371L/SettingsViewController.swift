//
//  SettingsViewController.swift
//  NeiroCS371L
//
//  Created by Ethan Yu on 10/21/25.
//

import UIKit
import FirebaseAuth

enum BackendData {
    static let allGenres: [String] = [
        "Pop","Rock","Rap","Hip-Hop","R&B","EDM","House","Techno","Trance","Drum & Bass",
        "Lo-Fi","Indie","Alternative","Funk","Soul","Jazz","Blues","Classical","Country",
        "Reggae","K-Pop","J-Pop","Metal","Punk","Folk","Latin","Afrobeats","Dancehall"
    ]
    static let allArtists: [String] = [
        "Drake","Taylor Swift","Bad Bunny","Billie Eilish","Ed Sheeran","Kanye West","The Weeknd",
        "Ariana Grande","Coldplay","Imagine Dragons","Kendrick Lamar","Doja Cat","Dua Lipa",
        "SZA","Travis Scott","Post Malone","Olivia Rodrigo","Harry Styles","Rihanna","Eminem"
    ]
}

// One-session memory for this screen
private enum SessionStore {
    static var appearanceStyle: String = "light" // "dark" | "light"
    static var playlistMinutes: Int = 10
    static var avatarImage: UIImage?
    static var preferredGenres  = Set<String>()
    static var preferredArtists = Set<String>()
    static var unwantedGenres   = Set<String>()
    static var unwantedArtists  = Set<String>()
}

final class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // UI
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let headerCard = UIView()
    private let headerLabel = UILabel()

    private let profileRow = UIStackView()
    private let avatar = UIImageView()
    private let changePhotoButton = UIButton(type: .system)
    private let nameRow = UIStackView()
    private let usernameTitle = UILabel()
    private let usernameValue = UILabel()
    private let spotifyPill = UIButton(type: .system)
    
    //private let usernameLabel = UILabel()
    //private let spotifyStatusLabel = UILabel()
    //private let connectSpotifyButton = UIButton()

    private let appearanceCard = UIView()
    private let appearanceTitle = UILabel()
    private let appearanceSeg = UISegmentedControl(items: ["System", "Dark", "Light"])

    private let lengthCard = UIView()
    private let lengthTitle = UILabel()
    private let lengthSeg = UISegmentedControl(items: ["10 Min", "30 Min", "60 Min", "120 Min"])

    // Preference rows
    private let preferredGenresRow = PickerRow(title: "Preferred Genres")
    private let preferredArtistsRow = PickerRow(title: "Preferred Artists")
    private let unwantedGenresRow   = PickerRow(title: "Unwanted Genres")
    private let unwantedArtistsRow  = PickerRow(title: "Unwanted Artists")

    // Local copies bound to SessionStore
    private var preferredGenresList  = Set<String>()
    private var preferredArtistsList = Set<String>()
    private var unwantedGenresList   = Set<String>()
    private var unwantedArtistsList  = Set<String>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScroll()
        buildHeader()
        buildProfile()
        buildAppearance()
        buildLength()
        buildPreferenceRows()
        buildActions()
        loadFromSession()
        populateUser()
        checkSpotifyConnection()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkSpotifyConnection()
    }

    // MARK: - Build UI
    private func setupScroll() {
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        scroll.addSubview(content)
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])
    }

    private func buildHeader() {
        stylizeCard(headerCard)
        headerLabel.text = "Settings"
        headerLabel.font = ThemeColor.Font.titleFont()
        headerLabel.textColor = ThemeColor.Color.titleColor
        headerLabel.textAlignment = .center

        headerCard.addSubview(headerLabel)
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 18),
            headerLabel.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -18),
            headerLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 16),
            headerLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -16)
        ])
        content.addArrangedSubview(headerCard)
    }

    private func buildProfile() {
        let profileCard = UIView(); stylizeCard(profileCard)
        content.addArrangedSubview(profileCard)

        profileRow.axis = .horizontal
        profileRow.alignment = .center
        profileRow.spacing = 16

        avatar.image = UIImage(systemName: "person.crop.circle.fill")
        avatar.tintColor = .secondaryLabel
        avatar.contentMode = .scaleAspectFill
        avatar.clipsToBounds = true
        avatar.layer.cornerRadius = 48
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 96),
            avatar.heightAnchor.constraint(equalToConstant: 96)
        ])

        changePhotoButton.setTitle("Change Profile Picture", for: .normal)
        changePhotoButton.setTitleColor(.systemBlue, for: .normal)
        changePhotoButton.addTarget(self, action: #selector(changePhotoTapped), for: .touchUpInside)
        changePhotoButton.contentHorizontalAlignment = .left

        nameRow.axis = .horizontal
        nameRow.alignment = .center
        nameRow.spacing = 8

        usernameTitle.text = "Username:"
        usernameTitle.font = ThemeColor.Font.bodyAuthFont()
        usernameTitle.textColor = .white

        usernameValue.text = "username"
        usernameValue.font = ThemeColor.Font.bodyAuthFont()
        usernameValue.textColor = .secondaryLabel

        nameRow.addArrangedSubview(usernameTitle)
        nameRow.addArrangedSubview(usernameValue)

        var pillCfg = UIButton.Configuration.filled()
        pillCfg.title = "Spotify Not Connected"
        pillCfg.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
        pillCfg.baseForegroundColor = .white
        pillCfg.cornerStyle = .capsule
        pillCfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        spotifyPill.configuration = pillCfg
        spotifyPill.isUserInteractionEnabled = true
        spotifyPill.addTarget(self, action: #selector(connectSpotifyTapped), for: .touchUpInside)

        let rightStack = UIStackView(arrangedSubviews: [nameRow, spotifyPill, changePhotoButton])
        rightStack.axis = .vertical
        rightStack.spacing = 10
        rightStack.alignment = .leading

        profileRow.addArrangedSubview(avatar)
        profileRow.addArrangedSubview(rightStack)

        profileCard.addSubview(profileRow)
        profileRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            profileRow.topAnchor.constraint(equalTo: profileCard.topAnchor, constant: 16),
            profileRow.leadingAnchor.constraint(equalTo: profileCard.leadingAnchor, constant: 16),
            profileRow.trailingAnchor.constraint(equalTo: profileCard.trailingAnchor, constant: -16),
            profileRow.bottomAnchor.constraint(equalTo: profileCard.bottomAnchor, constant: -16)
        ])
    }
    
    private func checkSpotifyConnection() {
        if SpotifyUserAuthorization.shared.isConnected {
            var pillCfg = spotifyPill.configuration
            pillCfg?.title = "Spotify Connected"
            pillCfg?.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
            spotifyPill.configuration = pillCfg

            if let spotifyName = SpotifyUserAuthorization.shared.userDisplayName {
                usernameValue.text = spotifyName
            }
        } else {
            
            var pillCfg = spotifyPill.configuration
            pillCfg?.title = "Connect Spotify"
            pillCfg?.baseBackgroundColor = UIColor.systemRed.withAlphaComponent(0.9)
            spotifyPill.configuration = pillCfg
        }
    }

    private func buildAppearance() {
        stylizeCard(appearanceCard)
        content.addArrangedSubview(appearanceCard)

        appearanceTitle.text = "Appearance"
        appearanceTitle.font = UIFont.boldSystemFont(ofSize: 22)
        appearanceTitle.textColor = .white

        appearanceSeg.addTarget(self, action: #selector(appearanceChanged), for: .valueChanged)

        let v = UIStackView(arrangedSubviews: [appearanceTitle, appearanceSeg])
        v.axis = .vertical
        v.spacing = 12

        appearanceCard.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: appearanceCard.topAnchor, constant: 16),
            v.leadingAnchor.constraint(equalTo: appearanceCard.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: appearanceCard.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: appearanceCard.bottomAnchor, constant: -16)
        ])
    }

    private func buildLength() {
        stylizeCard(lengthCard)
        content.addArrangedSubview(lengthCard)

        lengthTitle.text = "Length of Playlist"
        lengthTitle.font = UIFont.boldSystemFont(ofSize: 22)
        lengthTitle.textColor = .white

        lengthSeg.addTarget(self, action: #selector(lengthChanged), for: .valueChanged)

        let v = UIStackView(arrangedSubviews: [lengthTitle, lengthSeg])
        v.axis = .vertical
        v.spacing = 12

        lengthCard.addSubview(v)
        v.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: lengthCard.topAnchor, constant: 16),
            v.leadingAnchor.constraint(equalTo: lengthCard.leadingAnchor, constant: 16),
            v.trailingAnchor.constraint(equalTo: lengthCard.trailingAnchor, constant: -16),
            v.bottomAnchor.constraint(equalTo: lengthCard.bottomAnchor, constant: -16)
        ])
    }

    private func buildPreferenceRows() {
        // Make entire rows tappable
        preferredGenresRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickPreferredGenres)))
        preferredArtistsRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickPreferredArtists)))
        unwantedGenresRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickUnwantedGenres)))
        unwantedArtistsRow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickUnwantedArtists)))

        content.addArrangedSubview(preferredGenresRow)
        content.addArrangedSubview(preferredArtistsRow)
        content.addArrangedSubview(unwantedGenresRow)
        content.addArrangedSubview(unwantedArtistsRow)

        refreshPickerSubtitles()
    }

    private func buildActions() {
        let clearHistoryButton = UIButton(type: .system)
        clearHistoryButton.setTitle("Clear History", for: .normal)
        clearHistoryButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.25)
        clearHistoryButton.setTitleColor(.white, for: .normal)
        clearHistoryButton.layer.cornerRadius = 14
        clearHistoryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let signOutButton = UIButton(type: .system)
        signOutButton.setTitle("Sign Out", for: .normal)
        signOutButton.titleLabel?.textColor = .gray
        signOutButton.backgroundColor = ThemeColor.Color.titleOutline
        signOutButton.setTitleColor(.white, for: .normal)
        signOutButton.layer.cornerRadius = 14
        signOutButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)

        content.addArrangedSubview(clearHistoryButton)
        content.addArrangedSubview(signOutButton)
    }

    private func stylizeCard(_ v: UIView) {
        v.backgroundColor = UIColor(white: 1, alpha: 0.05)
        v.layer.cornerRadius = 18
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.15
        v.layer.shadowRadius = 12
        v.layer.shadowOffset = CGSize(width: 0, height: 6)
    }

    // MARK: - Session I/O
    private func loadFromSession() {
        // ["Dark","Light"] => 0: dark, 1: light
        appearanceSeg.selectedSegmentIndex = (SessionStore.appearanceStyle == "dark") ? 1 : 0
        applyAppearance(SessionStore.appearanceStyle)

        let idx: [Int:Int] = [10:0, 30:1, 60:2, 120:3]
        lengthSeg.selectedSegmentIndex = idx[SessionStore.playlistMinutes] ?? 0

        preferredGenresList  = SessionStore.preferredGenres
        preferredArtistsList = SessionStore.preferredArtists
        unwantedGenresList   = SessionStore.unwantedGenres
        unwantedArtistsList  = SessionStore.unwantedArtists

        if let img = SessionStore.avatarImage {
            avatar.image = img
            avatar.contentMode = .scaleAspectFill
        }
    }

    private func saveToSession() {
        SessionStore.preferredGenres  = preferredGenresList
        SessionStore.preferredArtists = preferredArtistsList
        SessionStore.unwantedGenres   = unwantedGenresList
        SessionStore.unwantedArtists  = unwantedArtistsList
    }

    private func summaryText(for set: Set<String>) -> String {
        guard !set.isEmpty else { return "None selected" }
        let list = Array(set).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        return list.count <= 3 ? list.joined(separator: ", ")
                               : "\(list.prefix(3).joined(separator: ", ")) … +\(list.count - 3)"
    }

    private func refreshPickerSubtitles() {
        preferredGenresRow.setSubtitle(summaryText(for: preferredGenresList))
        preferredArtistsRow.setSubtitle(summaryText(for: preferredArtistsList))
        unwantedGenresRow.setSubtitle(summaryText(for: unwantedGenresList))
        unwantedArtistsRow.setSubtitle(summaryText(for: unwantedArtistsList))
    }

    // MARK: - Actions
    @objc private func appearanceChanged() {
        // ["Dark","Light"] => index 0 is dark
        let choice: AppAppearance = {
                switch appearanceSeg.selectedSegmentIndex {
                case 1:
                    let style = "light"
                    SessionStore.appearanceStyle = style
                    applyAppearance(style)
                    return .light
                case 2: return .dark
                default: return .system
                }
            }()
        ThemeManager.set(choice)
        // let style = (appearanceSeg.selectedSegmentIndex == 1) ? "dark" : "light"
        // SessionStore.appearanceStyle = style
        // applyAppearance(style)
    }

    @objc private func lengthChanged() {
        let minutes = [10, 30, 60, 120][lengthSeg.selectedSegmentIndex]
        SessionStore.playlistMinutes = minutes
    }

    private func applyAppearance(_ style: String) {
        overrideUserInterfaceStyle = (style == "light") ? .light : .dark
    }

    @objc private func signOutTapped() {
        do {
            try Auth.auth().signOut()
            SpotifyUserAuthorization.shared.disconnect()
            if
                let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                let delegate = scene.delegate as? SceneDelegate {
                delegate.showAuth(animated: true)
            }
        } catch {
            print("Sign out failed: \(error)")
        }
    }

    @objc private func changePhotoTapped() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc private func connectSpotifyTapped() {
        if SpotifyUserAuthorization.shared.isConnected {
            let alert = UIAlertController(
                title: "Disconnect Spotify?",
                message: "You will no longer be able to export playlists to Spotify",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Disconnect", style: .destructive) { _ in
                SpotifyUserAuthorization.shared.disconnect()
                self.checkSpotifyConnection()
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style:.cancel))
            
            present(alert, animated: true)
        } else {
            SpotifyUserAuthorization.shared.startLogin(presentingVC: self, forSignup: false) { [weak self] safari in
                if safari == nil {
                    self?.showAlert(title: "Error", message: "Failed to start Spotify login")
                }}
        }
    }

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let img = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
            avatar.image = img
            avatar.contentMode = .scaleAspectFill
            SessionStore.avatarImage = img
        }
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }

    // MARK: - Preference pickers
    @objc private func pickPreferredGenres() {
        presentPicker(title: "Preferred Genres",
                      items: BackendData.allGenres,
                      selected: preferredGenresList) { [weak self] sel in
            self?.preferredGenresList = sel
            self?.saveToSession()
            self?.refreshPickerSubtitles()
        }
    }
    @objc private func pickPreferredArtists() {
        presentPicker(title: "Preferred Artists",
                      items: BackendData.allArtists,
                      selected: preferredArtistsList) { [weak self] sel in
            self?.preferredArtistsList = sel
            self?.saveToSession()
            self?.refreshPickerSubtitles()
        }
    }
    @objc private func pickUnwantedGenres() {
        presentPicker(title: "Unwanted Genres",
                      items: BackendData.allGenres,
                      selected: unwantedGenresList) { [weak self] sel in
            self?.unwantedGenresList = sel
            self?.saveToSession()
            self?.refreshPickerSubtitles()
        }
    }
    @objc private func pickUnwantedArtists() {
        presentPicker(title: "Unwanted Artists",
                      items: BackendData.allArtists,
                      selected: unwantedArtistsList) { [weak self] sel in
            self?.unwantedArtistsList = sel
            self?.saveToSession()
            self?.refreshPickerSubtitles()
        }
    }

    private func presentPicker(title: String,
                               items: [String],
                               selected: Set<String>,
                               onDone: @escaping (Set<String>) -> Void) {
        let vc = SearchableMultiPickerViewController(title: title,
                                                     items: items,
                                                     initiallySelected: selected,
                                                     onDone: onDone)
        let nav = UINavigationController(rootViewController: vc)

        let ap = UINavigationBarAppearance()
        ap.configureWithOpaqueBackground()
        ap.backgroundColor = ThemeColor.Color.backgroundColor
        ap.titleTextAttributes = [.foregroundColor: UIColor.white]
        ap.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        nav.navigationBar.standardAppearance = ap
        nav.navigationBar.scrollEdgeAppearance = ap
        nav.navigationBar.tintColor = .white

        present(nav, animated: true)
    }

    private func populateUser() {
        let user = Auth.auth().currentUser
        let display = user?.displayName ?? user?.email ?? "username"
        usernameValue.text = display
    }
    
    //helper function to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
}

// MARK: - Searchable picker
final class SearchableMultiPickerViewController: UITableViewController {
    private let allItems: [String]
    private var filtered: [String]
    private var selected: Set<String>
    private let onDone: (Set<String>) -> Void

    private let searchController = UISearchController(searchResultsController: nil)

    init(title: String, items: [String], initiallySelected: Set<String>, onDone: @escaping (Set<String>) -> Void) {
        self.allItems = items.sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        self.filtered = self.allItems
        self.selected = initiallySelected
        self.onDone = onDone
        super.init(style: .insetGrouped)
        self.title = title
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()

        // System backgrounds + dynamic label colors for readability in both modes
        view.backgroundColor = .systemBackground
        tableView.backgroundColor = .systemBackground
        tableView.rowHeight = 54
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = UIColor.label.withAlphaComponent(0.15)
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Type to filter"
        searchController.searchBar.searchTextField.textColor = .label
        searchController.searchBar.searchTextField.leftView?.tintColor = .secondaryLabel
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Done",
            style: .prominent,
            target: self,
            action: #selector(doneTapped)
        )
    }

    @objc private func doneTapped() {
        onDone(selected)
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { filtered.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = filtered[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        var cfg = UIListContentConfiguration.cell()
        cfg.text = item
        cfg.textProperties.color = .label
        cfg.secondaryText = selected.contains(item) ? "Selected" : nil
        cfg.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = cfg

        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.tintColor = .systemBlue
        cell.accessoryType = selected.contains(item) ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = filtered[indexPath.row]
        if selected.contains(item) { selected.remove(item) } else { selected.insert(item) }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension SearchableMultiPickerViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let q = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        filtered = q.isEmpty ? allItems : allItems.filter { $0.localizedCaseInsensitiveContains(q) }
        tableView.reloadData()
    }
}

// MARK: - Simple row (fully tappable)
private final class PickerRow: UIControl {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor(white: 0.95, alpha: 1)
        layer.cornerRadius = 18

        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label

        subtitleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1

        chevron.tintColor = .tertiaryLabel
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        v.axis = .vertical
        v.spacing = 4
        v.isUserInteractionEnabled = false

        let h = UIStackView(arrangedSubviews: [v, chevron])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12
        h.translatesAutoresizingMaskIntoConstraints = false
        h.isUserInteractionEnabled = false
        chevron.isUserInteractionEnabled = false

        addSubview(h)
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            h.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            h.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            h.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setSubtitle(_ text: String?) { subtitleLabel.text = text }
}
