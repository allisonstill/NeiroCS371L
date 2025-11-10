//
//  HomePlaylistViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/9/25.
//

import UIKit

// view controller for the home screen (recently played playlist screen)
final class HomePlaylistViewController: UIViewController {
    
    //container for empty label or playlist
    private var container: UIView = UIView()
    private var emptyLabel = UILabel() // shown if user has no playlists
    private var currentDetail: UIViewController? // ref to child (playlist) currently

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Playlist"
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupUI()
        refresh()
        
        //keep track of when there is a new 'last opened playlist'
        NotificationCenter.default.addObserver(self, selector: #selector(refreshFromNotification), name: .lastOpenedPlaylistDidChange, object: nil)

    }
    
    private func setupUI() {
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        //empty label shown if there are no playlists
        emptyLabel.text = "No Playlists Created. Go create a playlist!"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24)
        ])
    }
    
    @objc private func refreshFromNotification() { refresh() }
    
    func refresh() {
        //use last opened or newest, else empty
        if let p = PlaylistLibrary.homePlaylist() {
            showDetail(for: p)
            emptyLabel.isHidden = true
        } else {
            emptyLabel.isHidden = false
            removeCurrentDetail()
        }
    }
    
    private func showDetail(for playlist: Playlist) {
        removeCurrentDetail()
        
        //show most recent playlist from playlistdetailVC (embed it)
        let detail = PlaylistDetailViewController()
        detail.playlist = playlist
        detail.onSave = { updated in
            PlaylistLibrary.updatePlaylist(updated, completion: nil)
        }
        addChild(detail)
        container.addSubview(detail.view)
        detail.view.frame = container.bounds
        detail.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        detail.didMove(toParent: self)
        currentDetail = detail
    }
    
    //remove previous child (last playlist)
    private func removeCurrentDetail() {
        guard let vc = currentDetail else { return }
        vc.willMove(toParent: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParent()
        currentDetail = nil
    }

}

extension Notification.Name {
    static let lastOpenedPlaylistDidChange = Notification.Name("lastOpenedPlaylistDidChange")
}
