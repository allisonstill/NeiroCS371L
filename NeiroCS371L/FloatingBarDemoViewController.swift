//
//  FloatingBarDemoViewController.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/19/25.
//

import UIKit
import FirebaseAuth

final class FloatingBarDemoViewController: UIViewController {

    private let floatingBar = FloatingBar()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupFloatingBar()
        floatingBar.setShowCaptions(false)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Log Out",
            style: .plain,
            target: self,
            action: #selector(logOut)
        )
        print("Current user:", Auth.auth().currentUser?.email ?? "nil")

        // Optional: pick a default selected item
        floatingBar.select(index: 0) // Home
    }

    @objc private func logOut() {
        do {
            try Auth.auth().signOut()
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let delegate = scene.delegate as? SceneDelegate {
                delegate.showAuth(animated: true)
            }
        } catch {
            print("Sign out failed: \(error)")
        }
    }

    private func setupFloatingBar() {
        view.addSubview(floatingBar)
        floatingBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            floatingBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            floatingBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            floatingBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            floatingBar.heightAnchor.constraint(equalToConstant: 64) // matches the bar's internal layout
        ])

        // Map new indices: 0=Home, 1=Playlists, 2=Group, 3=Profile, 4=Settings
        floatingBar.onTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case 0:
                print("Home")
                self.floatingBar.select(index: 0)
                // self.show(HomeVC())
            case 1:
                print("Playlists")
                self.floatingBar.select(index: 1)
                // self.show(PlaylistsVC())
            case 2:
                print("Group")
                self.floatingBar.select(index: 2)
                // self.show(GroupVC())
            case 3:
                print("Profile")
                self.floatingBar.select(index: 3)
                // self.show(ProfileVC())
            case 4:
                print("Settings")
                self.floatingBar.select(index: 4)
                // Present Settings screen (full screen)
                let settings = SettingsViewController()
                settings.modalPresentationStyle = .fullScreen
                self.present(settings, animated: false)

                // Option A: open Settings screen
                // self.show(SettingsVC())
                // Option B: quick action to log out from Settings
            default:
                break
            }
        }
    }
}
