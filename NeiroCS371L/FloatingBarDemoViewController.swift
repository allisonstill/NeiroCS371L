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
    private let content = UIView()          // where child screens live
    private var currentChild: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        layoutUI()
        wireFloatingBar()
        floatingBar.setShowCaptions(false)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Log Out",
            style: .plain,
            target: self,
            action: #selector(logOut)
        )

        print("Current user:", Auth.auth().currentUser?.email ?? "nil")

        // Start on "Home" (placeholder)
        showChild(SimplePlaceholderVC(title: "Home"))
        floatingBar.select(index: 0)
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

    // MARK: - Layout
    private func layoutUI() {
        // content area
        view.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false

        // floating bar
        view.addSubview(floatingBar)
        floatingBar.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // content fills above bar
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: floatingBar.topAnchor, constant: -12),

            // bar pinned to bottom
            floatingBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            floatingBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            floatingBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            floatingBar.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    // MARK: - Switching tabs (child VCs)
    private func showChild(_ vc: UIViewController) {
        // remove old
        if let old = currentChild {
            old.willMove(toParent: nil)
            // crossfade from old to new
            addChild(vc)
            vc.view.frame = content.bounds
            vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            transition(from: old, to: vc, duration: 0.25, options: .transitionCrossDissolve, animations: nil) { _ in
                old.removeFromParent()
                vc.didMove(toParent: self)
                self.currentChild = vc
            }
            return
        }

        // first time
        addChild(vc)
        vc.view.frame = content.bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        content.addSubview(vc.view)
        vc.didMove(toParent: self)
        currentChild = vc
    }

    private func wireFloatingBar() {
        floatingBar.onTap = { [weak self] index in
            guard let self = self else { return }
            switch index {
            case 0:
                self.floatingBar.select(index: 0)
                self.showChild(SimplePlaceholderVC(title: "Home"))
            case 1:
                self.floatingBar.select(index: 1)
                let playlists = PlaylistViewController()
                self.showChild(playlists)
            case 2:
                self.floatingBar.select(index: 2)
                self.showChild(SimplePlaceholderVC(title: "Group"))
            case 3:
                self.floatingBar.select(index: 3)
                self.showChild(SimplePlaceholderVC(title: "Profile"))
            case 4:
                self.floatingBar.select(index: 4)
                // you can show a Settings VC here; for now, log out:
                self.logOut()
            default: break
            }
        }
    }
}

// Simple placeholder so you can see tab swaps working
private final class SimplePlaceholderVC: UIViewController {
    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        label.text = title
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
