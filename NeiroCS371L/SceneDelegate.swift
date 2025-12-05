//  SceneDelegate.swift

import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        ThemeManager.applyToAllWindows()

        if Auth.auth().currentUser != nil {
            //showMainApp(animated: false)
            loadUserPlaylistsAndShowMainApp(animated: false)
        } else {
            showAuth(animated: false)
        }

        window.makeKeyAndVisible()
        
        if let urlContext = connectionOptions.urlContexts.first {
            self.scene(scene, openURLContexts: Set([urlContext]))
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        print("Received this url: \(url.absoluteString) within Scene Delegate")
        
        //check if we got a Spotify callback url
        if url.scheme == "neiro" && url.host == "spotify-callback" {
            //TODO
            SpotifyUserAuthorization.shared.handleCallback(url: url) { success in
                
                DispatchQueue.main.async {
                    if success {
                        print("Spotify authentication successful!!")
                        
                        //notify observers (signupVC, settingsVC)
                        NotificationCenter.default.post(
                            name: Notification.Name("spotifyAuthSuccess"),
                            object: nil
                        )
                        
                        //if during sign up, go to main app
                        if Auth.auth().currentUser != nil {
                            self.showMainApp(animated: true)
                        }
                    } else {
                        print("Spotify authentication failed")
                        NotificationCenter.default.post(
                            name: Notification.Name("spotifyAuthFailed"),
                            object: nil
                        )
                    }
                }
            }
        }
    }

    

    // MARK: - Routing helpers

    func showAuth(animated: Bool = true) {
        PlaylistLibrary.clearLocal()
        let root = LoginViewController()
        //let root = SignUpViewController()
        // If you want a nav bar during auth, wrap in a UINavigationController too:
        // let nav = UINavigationController(rootViewController: root)
        // setRootViewController(nav, animated: animated)
        setRootViewController(root, animated: animated)
    }

    func showMainApp(animated: Bool = true) {
        loadUserPlaylistsAndShowMainApp(animated: animated)
    }
    
    private func loadUserPlaylistsAndShowMainApp(animated: Bool = true) {
        if let window = self.window {
            let loadingVC = UIViewController()
            loadingVC.view.backgroundColor = ThemeColor.Color.backgroundColor
            
            let activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.color = .white
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false
            activityIndicator.startAnimating()
            loadingVC.view.addSubview(activityIndicator)
            
            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: loadingVC.view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: loadingVC.view.centerYAnchor)
            ])
            
            let label = UILabel()
            label.text = "Loading your playlists..."
            label.textColor = .white
            label.font = .systemFont(ofSize: 16)
            label.translatesAutoresizingMaskIntoConstraints = false
            loadingVC.view.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: loadingVC.view.centerXAnchor),
                label.topAnchor.constraint(equalTo: activityIndicator.bottomAnchor, constant: 20)
            ])
            
            setRootViewController(loadingVC, animated: false)
        }
        
        PlaylistLibrary.loadPlaylists { success in
            DispatchQueue.main.async {
                if success {
                    print("Playlists loaded!")
                } else {
                    print("Failed to load playlists.")
                }
                
                let root = FloatingBarDemoViewController()
                let nav = UINavigationController(rootViewController: root)
                
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = ThemeColor.Color.backgroundColor
                appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]

                nav.navigationBar.standardAppearance = appearance
                nav.navigationBar.scrollEdgeAppearance = appearance
                nav.navigationBar.compactAppearance = appearance
                nav.navigationBar.tintColor = .label // <- back button & bar items

                nav.navigationBar.prefersLargeTitles = true
                self.setRootViewController(nav, animated: animated)
            }
        }
    }


    private func setRootViewController(_ vc: UIViewController, animated: Bool) {
        guard let window = self.window else { return }
        if animated {
            UIView.transition(with: window,
                              duration: 0.25,
                              options: .transitionCrossDissolve,
                              animations: { window.rootViewController = vc },
                              completion: nil)
        } else {
            window.rootViewController = vc
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) { }
    func sceneDidBecomeActive(_ scene: UIScene) { }
    func sceneWillResignActive(_ scene: UIScene) { }
    func sceneWillEnterForeground(_ scene: UIScene) { }
    func sceneDidEnterBackground(_ scene: UIScene) { }
}
