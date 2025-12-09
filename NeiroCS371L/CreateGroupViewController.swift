//
//  CreateGroupViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

final class CreateGroupViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    private let sessionNameField = UITextField()
    private let sessionNameLabel = UILabel()
    private let visibilityLabel = UILabel()
    private let visibilityControl = UISegmentedControl(items: ["Public", "Private"])
    private let continueButton = UIButton(type: .system)
    
    private let locationManager = CLLocationManager()
    private var currentLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        title = "Create Session"
        navigationItem.largeTitleDisplayMode = .never
        
        setupLocationManager()
        configureSessionNameField()
        configureLabels()
        configureVisibilityControl()
        configureContinueButton()
        layoutUI()
        applyButtonState()
        
        // Request location immediately if permission already granted
        let status = locationManager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    private func configureSessionNameField() {
        sessionNameField.translatesAutoresizingMaskIntoConstraints = false
        sessionNameField.placeholder = "Enter Session Name"
        sessionNameField.font = .systemFont(ofSize: 16)
        sessionNameField.textColor = .white
        sessionNameField.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        sessionNameField.layer.cornerRadius = 10
        sessionNameField.setLeftPaddingPoints(12)
        sessionNameField.setRightPaddingPoints(12)
        sessionNameField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        sessionNameField.delegate = self
        sessionNameField.returnKeyType = .done
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func configureLabels() {
        sessionNameLabel.text = "Session Name"
        sessionNameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        sessionNameLabel.textColor = .white
        sessionNameLabel.translatesAutoresizingMaskIntoConstraints = false

        visibilityLabel.text = "Session Type"
        visibilityLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        visibilityLabel.textColor = .white
        visibilityLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureVisibilityControl() {
        visibilityControl.selectedSegmentIndex = 1 // Default to Private
        visibilityControl.addTarget(self, action: #selector(visibilityChanged), for: .valueChanged)
        visibilityControl.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureContinueButton() {
        continueButton.setTitle("Start Your Session!", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        continueButton.layer.cornerRadius = 14
        continueButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        continueButton.addTarget(self, action: #selector(startSessionTapped), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func layoutUI() {
        let infoLabel = UILabel()
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.text = "Public sessions appear on the map for others nearby to join. Private sessions require a code."
        infoLabel.font = .systemFont(ofSize: 13, weight: .regular)
        infoLabel.textColor = .white.withAlphaComponent(0.7)
        infoLabel.numberOfLines = 0
        
        let stack = UIStackView(arrangedSubviews: [
            sessionNameLabel,
            sessionNameField,
            visibilityLabel,
            visibilityControl,
            infoLabel,
            continueButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.setCustomSpacing(8, after: visibilityLabel)
        stack.setCustomSpacing(24, after: infoLabel)
        
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sessionNameField.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
    
    private func applyButtonState() {
        let hasName = !(sessionNameField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        
        continueButton.isEnabled = hasName
        continueButton.backgroundColor = hasName ? UIColor.systemBlue.withAlphaComponent(0.9) : UIColor.systemBlue.withAlphaComponent(0.4)
        continueButton.setTitleColor(.white, for: .normal)
    }
    
    @objc private func textDidChange() {
        applyButtonState()
    }
    
    @objc private func visibilityChanged() {
        let isPublic = visibilityControl.selectedSegmentIndex == 0
        
        if isPublic {
            // Request location permission for public sessions
            let status = locationManager.authorizationStatus
            
            if status == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            } else if status == .authorizedWhenInUse || status == .authorizedAlways {
                locationManager.requestLocation()
            } else {
                showLocationAlert()
            }
        }
    }
    
    // need location to use map
    private func showLocationAlert() {
        let alert = UIAlertController(
            title: "Location Required",
            message: "Public sessions require location access to appear on the map. Please enable location in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Use Private Instead", style: .cancel) { [weak self] _ in
            self?.visibilityControl.selectedSegmentIndex = 1
        })
        present(alert, animated: true)
    }
    
    @objc private func startSessionTapped() {
        
        //guard against users who aren't logged into spotify
        guard SpotifyUserAuthorization.shared.isConnected else {
                let alert = UIAlertController(
                    title: "Connect Spotify",
                    message: "You need to connect your Spotify account before starting a group session so we can build a playlist from everyone's vibe.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                return
            }
        
        
        let sessionName = (sessionNameField.text ?? "").trimmingCharacters(in: .whitespaces)
        guard !sessionName.isEmpty else { return }
        
        let isPublic = visibilityControl.selectedSegmentIndex == 0
        
        var userName = "User"
        if let currentUser = Auth.auth().currentUser {
            if let displayName = currentUser.displayName, !displayName.isEmpty {
                userName = displayName
            } else if let email = currentUser.email {
                userName = email.components(separatedBy: "@").first ?? "User"
            } else {
                userName = "User-\(String(currentUser.uid.prefix(4)))"
            }
        }
        
        print("Creating session - Name: \(sessionName), Public: \(isPublic), User: \(userName)")
        
        // Prepare location for public sessions
        var geoPoint: GeoPoint? = nil
        if isPublic {
            if let loc = currentLocation {
                geoPoint = GeoPoint(latitude: loc.latitude, longitude: loc.longitude)
                print("Using location: \(loc.latitude), \(loc.longitude)")
            } else {
                print("No location for public session")
                let alert = UIAlertController(
                    title: "Location Unavailable",
                    message: "We couldn't get your location yet. Try again or create a private session.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Try Again", style: .default) { [weak self] _ in
                    self?.locationManager.requestLocation()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.startSessionTapped()
                    }
                })
                alert.addAction(UIAlertAction(title: "Create Private", style: .default) { [weak self] _ in
                    self?.visibilityControl.selectedSegmentIndex = 1
                    self?.startSessionTapped()
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
                return
            }
        }
        
        // Disable button
        continueButton.isEnabled = false
        continueButton.setTitle("Creating...", for: .normal)
        
        // Create group
        GroupManager.shared.createGroup(
            sessionName: sessionName,
            isPublic: isPublic,
            location: geoPoint,
            userName: userName
        ) { [weak self] newGroup in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.continueButton.isEnabled = true
                self.continueButton.setTitle("Start Your Session!", for: .normal)
                
                if let group = newGroup {
                    print("Group created: \(group.sessionCode)")
                    let hostVC = GroupHostViewController(group: group)
                    self.navigationController?.pushViewController(hostVC, animated: true)
                } else {
                    print("Failed to create group")
                    self.showErrorAlert()
                }
            }
        }
    }
    
    private func showErrorAlert() {
        let alert = UIAlertController(
            title: "Error",
            message: "Failed to create session. Check internet and try again.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentLocation = location.coordinate
            print("Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("Location auth: \(status.rawValue)")
        
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        } else if status == .denied || status == .restricted {
            if visibilityControl.selectedSegmentIndex == 0 {
                showLocationAlert()
            }
        }
    }
}

private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.height))
        leftView = paddingView
        leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.height))
        rightView = paddingView
        rightViewMode = .always
    }
}
