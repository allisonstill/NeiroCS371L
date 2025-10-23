//
//  SettingsViewController.swift
//  NeiroCS371L
//
//  Created by Ethan Yu on 10/21/25.
//

import UIKit
import FirebaseAuth

final class SettingsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - UI
    private let scroll = UIScrollView()
    private let content = UIStackView()

    // Header
    private let headerCard = UIView()
    private let headerLabel = UILabel()

    // Profile
    private let profileRow = UIStackView()
    private let avatar = UIImageView()
    private let changePhotoButton = UIButton(type: .system)
    private let nameRow = UIStackView()
    private let usernameTitle = UILabel()
    private let usernameValue = UILabel()
    private let spotifyPill = UIButton(type: .system)

    // Appearance
    private let appearanceCard = UIView()
    private let appearanceTitle = UILabel()
    private let appearanceSeg = UISegmentedControl(items: ["Light", "Dark"])

    // Playlist length
    private let lengthCard = UIView()
    private let lengthTitle = UILabel()
    private let lengthSeg = UISegmentedControl(items: ["10 Min", "30 Min", "60 Min", "120 Min"])

    // Dropdowns
    private let unwantedGenres = ExpandableRow(title: "Unwanted Genres")
    private let unwantedArtists = ExpandableRow(title: "Unwanted Artists")

    // Actions
    private let clearHistoryButton = UIButton(type: .system)
    private let signOutButton = UIButton(type: .system)

    // MARK: - Keys
    private let kAppearanceKey = "neiro.appearance"          // "light" | "dark"
    private let kPlaylistMinutesKey = "neiro.playlist.minutes"
    private let kAvatarPNGKey = "neiro.avatar.png"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScroll()
        buildHeader()
        buildProfile()
        buildAppearance()
        buildLength()
        buildDropdowns()
        buildActions()
        loadPersisted()
        populateUser()
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

        // avatar
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
        pillCfg.title = "Spotify Account Connected"
        pillCfg.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.9)
        pillCfg.baseForegroundColor = .white
        pillCfg.cornerStyle = .capsule
        pillCfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        spotifyPill.configuration = pillCfg
        spotifyPill.isUserInteractionEnabled = false

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

    private func buildAppearance() {
        stylizeCard(appearanceCard)
        content.addArrangedSubview(appearanceCard)

        appearanceTitle.text = "Appearance"
        appearanceTitle.font = UIFont.boldSystemFont(ofSize: 22)
        appearanceTitle.textColor = .white

        appearanceSeg.selectedSegmentIndex = (UserDefaults.standard.string(forKey: kAppearanceKey) == "dark") ? 0 : 1
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

        lengthSeg.selectedSegmentIndex = 0
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

    private func buildDropdowns() {
        content.addArrangedSubview(unwantedGenres)
        content.addArrangedSubview(unwantedArtists)

        // Add some placeholder content so the dropdown visibly expands.
        unwantedGenres.setBody(rows: ["Rock", "EDM", "Country"])
        unwantedArtists.setBody(rows: ["Artist A", "Artist B", "Artist C"])
    }

    private func buildActions() {
        // Clear history
        clearHistoryButton.setTitle("Clear History", for: .normal)
        clearHistoryButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.25)
        clearHistoryButton.setTitleColor(.white, for: .normal)
        clearHistoryButton.layer.cornerRadius = 14
        clearHistoryButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        // (no-op for now)

        // Sign out
        signOutButton.setTitle("Sign Out", for: .normal)
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

    // MARK: - Populate & Persist
    private func populateUser() {
        let user = Auth.auth().currentUser
        let display = user?.displayName ?? user?.email ?? "username"
        usernameValue.text = display

        if let data = UserDefaults.standard.data(forKey: kAvatarPNGKey),
           let img = UIImage(data: data) {
            avatar.image = img
            avatar.contentMode = .scaleAspectFill
        }
    }

    private func loadPersisted() {
        // Appearance
        let style = UserDefaults.standard.string(forKey: kAppearanceKey) ?? "dark"
        appearanceSeg.selectedSegmentIndex = (style == "dark") ? 0 : 1
        applyAppearance(style)

        // Playlist length
        let minutes = UserDefaults.standard.integer(forKey: kPlaylistMinutesKey)
        let indexMap: [Int:Int] = [10:0, 30:1, 60:2, 120:3]
        lengthSeg.selectedSegmentIndex = indexMap[minutes] ?? 0
    }

    private func applyAppearance(_ style: String) {
        let mode: UIUserInterfaceStyle = (style == "dark") ? .dark : .light
        // Apply to the whole window if possible
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = (scene.delegate as? SceneDelegate)?.window {
            window.overrideUserInterfaceStyle = mode
        } else {
            // Fallback: at least apply to this VC
            overrideUserInterfaceStyle = mode
        }
    }


    // MARK: - Actions
    @objc private func appearanceChanged() {
        let style = appearanceSeg.selectedSegmentIndex == 0 ? "dark" : "light"
        UserDefaults.standard.setValue(style, forKey: kAppearanceKey)
        applyAppearance(style)
    }

    @objc private func lengthChanged() {
        let minutes: [Int] = [10, 30, 60, 120]
        let value = minutes[lengthSeg.selectedSegmentIndex]
        UserDefaults.standard.setValue(value, forKey: kPlaylistMinutesKey)
    }

    @objc private func signOutTapped() {
        do {
            try Auth.auth().signOut()
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

    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let img = (info[.editedImage] ?? info[ .originalImage ]) as? UIImage {
            avatar.image = img
            avatar.contentMode = .scaleAspectFill
            if let data = img.pngData() {
                UserDefaults.standard.setValue(data, forKey: kAvatarPNGKey)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Simple expandable row
private final class ExpandableRow: UIView {
    private let titleButton = UIButton(type: .system)
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let container = UIStackView()
    private var isOpen = false

    init(title: String) {
        super.init(frame: .zero)
        setup(title: title)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup(title: "")
    }

    private func setup(title: String) {
        layer.cornerRadius = 18
        backgroundColor = UIColor(white: 1, alpha: 0.05)

        let bar = UIView()
        bar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bar)

        titleButton.setTitle(title, for: .normal)
        titleButton.setTitleColor(.white, for: .normal)
        titleButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        titleButton.contentHorizontalAlignment = .left
        titleButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        chevron.tintColor = .white
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let barStack = UIStackView(arrangedSubviews: [titleButton, chevron])
        barStack.axis = .horizontal
        barStack.alignment = .center
        barStack.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(barStack)

        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: topAnchor),
            bar.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            bar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),

            barStack.topAnchor.constraint(equalTo: bar.topAnchor, constant: 14),
            barStack.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            barStack.trailingAnchor.constraint(equalTo: bar.trailingAnchor),
            barStack.bottomAnchor.constraint(equalTo: bar.bottomAnchor, constant: -14),
        ])

        container.axis = .vertical
        container.spacing = 8
        container.isHidden = true
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 10),
            container.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    func setBody(rows: [String]) {
        container.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for r in rows {
            let lbl = UILabel()
            lbl.text = "• \(r)"
            lbl.textColor = .secondaryLabel
            lbl.font = UIFont.systemFont(ofSize: 16)
            container.addArrangedSubview(lbl)
        }
    }

    @objc private func toggle() {
        isOpen.toggle()
        UIView.animate(withDuration: 0.2) {
            self.container.isHidden = !self.isOpen
            self.chevron.transform = self.isOpen ? CGAffineTransform(rotationAngle: .pi/2) : .identity
        }
    }
}

