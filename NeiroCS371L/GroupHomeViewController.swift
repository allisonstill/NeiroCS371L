//
//  GroupHomeViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

final class GroupHomeViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let createButton = UIButton(type: .system)
    private let joinButton = UIButton(type: .system)
    private let mapContainerView = UIView()
    private let mapTitleLabel = UILabel()
    private let mapView = MKMapView()
    private let requestButton = UIButton(type: .system)
    
    private let locationManager = CLLocationManager()
    private var publicGroups: [LocalGroup] = []
    private var selectedGroup: LocalGroup?
    private var currentUserLocation: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        title = "Group Sessions"
        navigationItem.largeTitleDisplayMode = .always
        
        setupLocationManager()
        configureLabels()
        configureButtons()
        configureMapView()
        layoutUI()
        
        print("GroupHomeVC loaded")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("GroupHomeVC appeared")
        
        // Run cleanup to catch any stale empty groups
        GroupManager.shared.cleanupEmptyGroups { deletedCount in
            if deletedCount > 0 {
                print("Cleaned up \(deletedCount) empty groups on view appear") // check for leftover stale groups
            }
        }
        
        startListeningToPublicGroups()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        GroupManager.shared.stopListeningToPublicGroups()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        
        let status = locationManager.authorizationStatus
        print("Location status: \(status.rawValue)")
        
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if status == .authorizedWhenInUse || status == .authorizedAlways {
            locationManager.requestLocation()
        }
    }
    
    private func configureLabels() {
        subtitleLabel.text = "Create a playlist with friends based on everyone's mood."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.8)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        mapTitleLabel.text = "Join via Map"
        mapTitleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        mapTitleLabel.textColor = .white
        mapTitleLabel.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func configureButtons() {
        // Create button
        stylePrimary(createButton, title: "Create Session")
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        
        // Join button
        styleSecondary(joinButton, title: "Join Session")
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
        
        // Request button (initially hidden)
        requestButton.translatesAutoresizingMaskIntoConstraints = false
        requestButton.setTitle("Request to Join", for: .normal)
        requestButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        requestButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        requestButton.setTitleColor(.white, for: .normal)
        requestButton.layer.cornerRadius = 14
        requestButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        requestButton.addTarget(self, action: #selector(requestTapped), for: .touchUpInside)
        requestButton.isHidden = true
    }
    
    private func stylePrimary(_ button: UIButton, title: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
    
    private func styleSecondary(_ button: UIButton, title: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    
    private func configureMapView() {
        mapContainerView.translatesAutoresizingMaskIntoConstraints = false
        mapContainerView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.3)
        mapContainerView.layer.cornerRadius = 12
        mapContainerView.clipsToBounds = true
        
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.layer.cornerRadius = 12
        
        // Enable user interaction
        mapView.isUserInteractionEnabled = true
        mapView.isMultipleTouchEnabled = true
        
        // Set initial region
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 30.2672, longitude: -97.7431),
            latitudinalMeters: 10000,
            longitudinalMeters: 10000
        )
        mapView.setRegion(region, animated: false)
    }
    
    private func layoutUI() {
        let buttonStack = UIStackView(arrangedSubviews: [createButton, joinButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        
        mapContainerView.addSubview(mapView)
        
        let mainStack = UIStackView(arrangedSubviews: [
            subtitleLabel,
            buttonStack,
            mapTitleLabel,
            mapContainerView,
            requestButton
        ])
        mainStack.axis = .vertical
        mainStack.spacing = 18
        mainStack.alignment = .fill
        mainStack.setCustomSpacing(12, after: mapTitleLabel)
        mainStack.setCustomSpacing(12, after: mapContainerView)
        
        view.addSubview(mainStack)
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            mapContainerView.heightAnchor.constraint(equalToConstant: 300),
            
            mapView.topAnchor.constraint(equalTo: mapContainerView.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapContainerView.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapContainerView.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapContainerView.bottomAnchor)
        ])
    }
    
    // MARK: - Public Groups Real-Time Listener
    
    private func startListeningToPublicGroups() {
        guard let location = currentUserLocation else {
            print("No location yet, will start listener when location is available")
            return
        }
        
        print("Starting real-time listener for public groups")
        
        GroupManager.shared.listenToPublicGroups(near: location, radiusInKm: 50) { [weak self] groups in
            DispatchQueue.main.async {
                guard let self = self else { return }
                print("Real-time update: \(groups.count) nearby groups")
                self.publicGroups = groups
                self.updateMapAnnotations()
            }
        }
    }
    
    private func updateMapAnnotations() {
        // Remove old annotations
        let oldAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(oldAnnotations)
        
        print("Updating map with \(publicGroups.count) pins")
        
        // Add new annotations
        for group in publicGroups {
            if let coordinate = group.coordinate {
                let annotation = GroupAnnotation(group: group)
                mapView.addAnnotation(annotation)
                print(" '\(group.sessionName)' - \(group.members.count) members")
            }
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let groupAnnotation = annotation as? GroupAnnotation else {
            return nil
        }
        
        let identifier = "GroupPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            annotationView?.isEnabled = true
        } else {
            annotationView?.annotation = annotation
        }
        
        // Show member count
        let memberCount = groupAnnotation.group.members.count
        annotationView?.markerTintColor = .systemBlue
        annotationView?.glyphText = "\(memberCount)"
        
        // NO info button - removed
        annotationView?.rightCalloutAccessoryView = nil
        
        return annotationView
    }
    
    // Remove the callout accessory handler since we don't have the button anymore
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? GroupAnnotation else {
            return
        }
        
        selectedGroup = annotation.group
        requestButton.isHidden = false
        
        print("Selected: '\(annotation.group.sessionName)' (\(annotation.group.members.count) members)")
        
        // Animate button
        requestButton.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.requestButton.alpha = 1
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        selectedGroup = nil
        requestButton.isHidden = true
    }
        
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            currentUserLocation = location.coordinate
            
            let region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: 10000,
                longitudinalMeters: 10000
            )
            mapView.setRegion(region, animated: true)
            
            print("Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // Start listening now that we have location
            startListeningToPublicGroups()
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
        }
    }
    
    // MARK: - Actions
    
    @objc private func createTapped() {
        let vc = CreateGroupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func joinTapped() {
        let vc = JoinGroupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    // request group
    @objc private func requestTapped() {
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
        
        guard let group = selectedGroup else {
            return
        }
        
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
        
        print("Sending join request: \(userName) → '\(group.sessionName)'")
        
        requestButton.isEnabled = false
        requestButton.setTitle("Requesting...", for: .normal)
        
        GroupManager.shared.sendJoinRequest(to: group.sessionCode, userName: userName) { [weak self] success in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                self.requestButton.isEnabled = true
                self.requestButton.setTitle("Request to Join", for: .normal)
                
                if success {
                    self.showRequestSentAlert(groupCode: group.sessionCode)
                } else {
                    self.showErrorAlert(message: "Failed to send join request. Please try again.")
                }
            }
        }
    }
    
    private func showRequestSentAlert(groupCode: String) {
        let alert = UIAlertController(
            title: "Request Sent! ✉️",
            message: "Waiting for the host to accept your request...",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.listenForRequestStatus(groupCode: groupCode)
        })
        
        present(alert, animated: true)
    }
    
    private func listenForRequestStatus(groupCode: String) {
        guard let userId = GroupManager.shared.currentUserId else { return }
        
        print("Listening for request status")
        
        GroupManager.shared.listenToJoinRequestStatus(groupCode: groupCode, userId: userId) { [weak self] status in
            guard let self = self, let status = status else { return }
            
            // Immediately act on the latest status
            if status == "accepted" {
                GroupManager.shared.stopListening()
                self.showAcceptedAlert(groupCode: groupCode)
            } else if status == "denied" {
                GroupManager.shared.stopListening()
                self.showDeniedAlert(groupCode: groupCode)
            }
        }
    }

    
    private func showAcceptedAlert(groupCode: String) {
        let alert = UIAlertController(
            title: "Accepted! Joining Soon...",
            message: "The host accepted your request! Prepare to submit your moods!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Let's Go!", style: .default) { [weak self] _ in
            self?.joinAcceptedGroup(code: groupCode)
        })
        
        present(alert, animated: true)
    }
    
    private func showDeniedAlert(groupCode: String) {
        let alert = UIAlertController(
            title: "Declined Invite",
            message: "The host declined your request. Maybe next time!",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            if let userId = GroupManager.shared.currentUserId {
                        GroupManager.shared.clearJoinRequestState(groupCode: groupCode, userId: userId)
                    }
        })
        present(alert, animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func joinAcceptedGroup(code: String) {
        print("Joining group: \(code)")
        let db = Firestore.firestore()
        db.collection("groups").document(code).getDocument { [weak self] snapshot, error in
            guard let self = self,
                  let snapshot = snapshot,
                  let group = LocalGroup(document: snapshot) else {
                print("Failed to fetch group")
                return
            }
            
            DispatchQueue.main.async {
                let hostVC = GroupHostViewController(group: group)
                self.navigationController?.pushViewController(hostVC, animated: true)
            }
        }
    }
}

// MARK: - Custom Annotation

class GroupAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let group: LocalGroup
    
    init(group: LocalGroup) {
        self.group = group
        self.coordinate = group.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.title = group.sessionName
        
        let memberCount = group.members.count
        let memberText = memberCount == 1 ? "1 member" : "\(memberCount) members"
        self.subtitle = "Host: \(group.hostName) • \(memberText)"
        
        super.init()
    }
}
