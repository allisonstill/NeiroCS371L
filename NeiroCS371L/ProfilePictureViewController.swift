//
//  ProfilePictureViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 12/4/25.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

class ProfilePictureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    private let titleLabel = UILabel()
    private let skipButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let currentProfileImageView = UIImageView()
    private let cameraOverlay = UIImageView()
    private let selectAvatarLabel = UILabel()
    private let avatarCollectionView: UICollectionView
    private let saveButton = UIButton(type: .system)
    
    // keep track if coming from settings or sign up
    var isNewUser: Bool = false
    
    // selected image (from phone) or avatar from selection
    private var selectedImage: UIImage?
    private var selectedAvatarName: String?
    
    //list of avatars found within Assets
    private let avatars = ["cat_stock_image", "chick_stock_image", "dog_stock_image", "dolphin_stock_image", "duck_stock_image", "fox_stock_image", "goat_stock_image", "lion_stock_image", "zebra_stock_image"]
    
    init(isNewUser: Bool = false) {
        self.isNewUser = isNewUser
        
        // create collection view
        let collectionLayout = UICollectionViewFlowLayout()
        collectionLayout.scrollDirection = .vertical // don't intend to be scrolling but in case we add additional avatar options post demo
        collectionLayout.minimumInteritemSpacing = 16
        collectionLayout.minimumLineSpacing = 16
        collectionLayout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // add layout to collection view
        self.avatarCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        self.avatarCollectionView.isScrollEnabled = false // change if add more avatars
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Ran into implementation issue at init(coder:) for PPVC")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        
        setupScreen()
        loadProfileImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // new users can skip profile picture selection, it will set to default avatar
    @objc private func skipButtonTapped() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let delegate = scene.delegate as? SceneDelegate {
            delegate.showMainApp(animated: true)
        }
    }
    
    // established users can 'cancel' their idea to change their profile picture, going back to settings
    @objc private func cancelButtonTapped() {
        dismiss(animated: true)
    }
    
    private func setupScreen() {
        
        // title label: Select Profile Picture
        titleLabel.text = "Select Profile Picture"
        titleLabel.font = ThemeColor.Font.titleFont().withSize(36)
        titleLabel.textColor = ThemeColor.Color.titleColor
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // current profile image
        currentProfileImageView.image = UIImage(systemName: "person.crop.circle.fill")
        currentProfileImageView.tintColor = .systemGray3
        currentProfileImageView.contentMode = .scaleAspectFill
        currentProfileImageView.clipsToBounds = true
        currentProfileImageView.isUserInteractionEnabled = true
        currentProfileImageView.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        currentProfileImageView.layer.borderWidth = 2
        currentProfileImageView.layer.borderColor = ThemeColor.Color.titleOutline.withAlphaComponent(0.3).cgColor
        currentProfileImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentProfileImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(currentProfileImageTapped))
        currentProfileImageView.addGestureRecognizer(tapGesture)
        
        // overlay over current profile image
        cameraOverlay.image = UIImage(systemName: "camera.fill")
        cameraOverlay.tintColor = .white
        cameraOverlay.backgroundColor = ThemeColor.Color.titleOutline.withAlphaComponent(0.8)
        cameraOverlay.contentMode = .center
        cameraOverlay.clipsToBounds = true
        cameraOverlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraOverlay)
        
        // choose avatar label
        selectAvatarLabel.text = "Or select an avatar:"
        selectAvatarLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        selectAvatarLabel.textColor = ThemeColor.Color.textColor
        selectAvatarLabel.textAlignment = .center
        selectAvatarLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(selectAvatarLabel)
        
        // collection of suggested avatars
        avatarCollectionView.backgroundColor = .clear
        avatarCollectionView.delegate = self
        avatarCollectionView.dataSource = self
        avatarCollectionView.register(AvatarCell.self, forCellWithReuseIdentifier: "AvatarCell")
        avatarCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(avatarCollectionView)
        
        
        // save button
        saveButton.setTitle("Save Profile", for: .normal)
        saveButton.backgroundColor = ThemeColor.Color.titleOutline
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        saveButton.layer.cornerRadius = 16
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        // constraints
        let screenWidth = UIScreen.main.bounds.width
        let totalPadding: CGFloat = 40 + 32 // 2 * 20 + 2 * 16 (external + internal)
        let availableWidth = screenWidth - totalPadding
        let avatarSize = availableWidth / 3 + 30
        let totalGridHeight = (avatarSize * 3) + (16 * 2) // 3 rows + 2 gaps, need to change for additional avatars if need be
        
        var constraints: [NSLayoutConstraint] = []
        
        constraints.append(contentsOf: [
            
            // title label: Select Profile Picture
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // current profile image
            currentProfileImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            currentProfileImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            currentProfileImageView.widthAnchor.constraint(equalToConstant: 140),
            currentProfileImageView.heightAnchor.constraint(equalToConstant: 140),
            
            // overlay over current profile image
            cameraOverlay.centerXAnchor.constraint(equalTo: currentProfileImageView.centerXAnchor),
            cameraOverlay.centerYAnchor.constraint(equalTo: currentProfileImageView.centerYAnchor),
            cameraOverlay.widthAnchor.constraint(equalToConstant: 70),
            cameraOverlay.heightAnchor.constraint(equalToConstant: 70),
            
            // choose avatar label
            selectAvatarLabel.topAnchor.constraint(equalTo: currentProfileImageView.bottomAnchor, constant: 32),
            selectAvatarLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            selectAvatarLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // collection of suggested avatars
            avatarCollectionView.topAnchor.constraint(equalTo: selectAvatarLabel.bottomAnchor, constant: 16),
            avatarCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            avatarCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            avatarCollectionView.heightAnchor.constraint(equalToConstant: totalGridHeight),
            
            // save button
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            saveButton.heightAnchor.constraint(equalToConstant: 50),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50),
            
        ])
        
        if isNewUser {
            
            // add skip button in nav barfor new users
            skipButton.setTitle("Skip for Now", for: .normal)
            skipButton.backgroundColor = .clear
            skipButton.setTitleColor(ThemeColor.Color.textColor.withAlphaComponent(0.7), for: .normal)
            skipButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            skipButton.addTarget(self, action: #selector(skipButtonTapped), for: .touchUpInside)
            skipButton.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview(skipButton)
            
            constraints.append(contentsOf:[
                skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
                skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                skipButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            // cancel button for existing users
            cancelButton.setTitle("Cancel", for: .normal)
            cancelButton.setTitleColor(ThemeColor.Color.textColor.withAlphaComponent(0.8), for: .normal)
            cancelButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
            cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(cancelButton)
            
            constraints.append(contentsOf: [
                cancelButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
                cancelButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                cancelButton.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        
        // added to make image and overlay more circular
        currentProfileImageView.layer.cornerRadius = 70
        cameraOverlay.layer.cornerRadius = 35
    }
    
    // check the user in the database if they have a profile image (either a custom, personal one from their camera/library or an avatar we have offered)
    private func loadProfileImage() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        db.collection("users").document(userID).getDocument { [weak self] snapshot, error in
            guard let self = self, let data = snapshot?.data() else {return}
            
            // check if user has a profile pic set & set image
            if let imageData = data["profileImageBase64"] as? String,
               let data = Data(base64Encoded: imageData),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.currentProfileImageView.image = image
                    self.currentProfileImageView.contentMode = .scaleAspectFill
                    self.selectedImage = image
                }
            }
            
            // if user has an avatar name set, use the avatar from Assets
            else if let avatarName = data["avatarName"] as? String,
                    let avatarImage = UIImage(named: avatarName) {
                DispatchQueue.main.async {
                    self.currentProfileImageView.image = avatarImage
                    self.currentProfileImageView.contentMode = .scaleAspectFill
                    self.selectedAvatarName = avatarName
                }
            }
        }
    }
    
    @objc private func currentProfileImageTapped() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // take photo
        let cameraAction = UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
            self?.handleTakePhoto()
        }
        alert.addAction(cameraAction)
        
        // choose from library
        let libraryAction = UIAlertAction(title: "Choose Existing from Library", style: .default) { [weak self ] _ in
            self?.showImagePicker(sourceType: .photoLibrary)
        }
        alert.addAction(libraryAction)
        
        //cancel
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // helper for seeing if the user's device has a camera when 'take photo' is selected at the profile image screen
    @objc private func handleTakePhoto() {
        if isBackCameraAvailable() {
            showImagePicker(sourceType: .camera)
        } else {
            // we don't have a camera to take a picture with!
            showAlert(title: "Camera Not Available", message: "This device doesn't have a camera.")
        }
    }
    
    private func isBackCameraAvailable() -> Bool {
        if let _ = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return true
        }
        return false
    }
    
    
    private func showImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    @objc private func saveButtonTapped() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        let hasNewCustomImage = selectedImage != nil
        let hasNewAvatar = selectedAvatarName != nil
        if !hasNewCustomImage && !hasNewAvatar {
            handleNoChanges()
            return
        }
        
        // loading state for the save button
        saveButton.isEnabled = false
        saveButton.setTitle("Saving...", for: .normal)
        
        let db = Firestore.firestore()
        
        // user has a custom image from camera or library
        if let image = selectedImage {
            guard let resized = resizeImage(image, maxDimensions: 1000),
                    let imageData = resized.jpegData(compressionQuality: 0.2) else {
                showAlert(title: "Error", message: "Failed to save chosen image as profile picture")
                resetSave()
                return
            }
            
            let base64String = imageData.base64EncodedString()
            if base64String.count > 900000 {
                // image is too complex/large
                showAlert(title: "Image is Too Larger", message: "Please select a smaller image")
                resetSave()
                return
            }
            
            db.collection("users").document(userID).setData([
                "profileImageBase64": base64String,
                "avatarName": NSNull() // no avatar name if custom image
            ], merge: true) { [weak self] error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showAlert(title: "Error", message: "Could not save profile image: \(error.localizedDescription)")
                        self?.resetSave()
                    } else {
                        self?.handleGoodSave()
                    }
                }
            }
        }
        
        // user chose an avatar
        else if let avatarName = selectedAvatarName {
            db.collection("users").document(userID).setData([
                "avatarName": avatarName,
                "profileImageBase64": NSNull()
            ], merge: true) { [weak self] error in
                guard let self = self else {return}
                DispatchQueue.main.async {
                    if let error = error {
                        self.showAlert(title: "Error", message: "Could not save avatar: \(error.localizedDescription)")
                        self.resetSave()
                    } else {
                        self.handleGoodSave()
                    }
                }
            }
        }
    }
    
    // resizing pictures to fit within firestore limits
    private func resizeImage(_ image: UIImage, maxDimensions: CGFloat = 1000) -> UIImage? {
        let size = image.size
        let aspectRatio = size.width / size.height
        var newSize: CGSize
        if aspectRatio > 1 {
            newSize = CGSize(width: maxDimensions, height: maxDimensions / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimensions * aspectRatio, height: maxDimensions)
        }
        
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
    
    // save button was pressed with no changes to profile picture
    // either send new user to main app or established user back to settings
    private func handleNoChanges() {
        if isNewUser {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let delegate = scene.delegate as? SceneDelegate {
                delegate.showMainApp(animated: true)
            }
        } else {
            dismiss(animated: true)
        }
    }
    
    // save was successful, handles navigation back to settings or main app
    private func handleGoodSave() {
        resetSave()
        let alert = UIAlertController(title: "Success!", message: "Profile picture was saved!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            if self.isNewUser {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let delegate = scene.delegate as? SceneDelegate {
                    delegate.showMainApp(animated: true)
                }
            } else {
                self.dismiss(animated: true)
            }
        })
        present(alert, animated: true)
    }
    
    private func resetSave() {
        saveButton.isEnabled = true
        saveButton.setTitle("Save Profile", for: .normal)
    }
    
    // copied from other files - helper to show alerts easily
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        
        picker.dismiss(animated: true)
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImage = editedImage
            currentProfileImageView.image = editedImage
            currentProfileImageView.contentMode = .scaleAspectFill
            selectedAvatarName = nil
            avatarCollectionView.reloadData()
            
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImage = originalImage
            currentProfileImageView.image = originalImage
            currentProfileImageView.contentMode = .scaleAspectFill
            selectedAvatarName = nil
            avatarCollectionView.reloadData()
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}


extension ProfilePictureViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return avatars.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AvatarCell", for: indexPath) as! AvatarCell
        let avatarName = avatars[indexPath.item]
        if let avatarImage = UIImage(named: avatarName) {
            cell.configure(with: avatarImage, isSelected: avatarName == selectedAvatarName)
        } else {
            let systemImage = UIImage(systemName: "person.crop.circle.fill")
            cell.configure(with: systemImage, isSelected: avatarName == selectedAvatarName)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let avatarName = avatars[indexPath.item]
        selectedAvatarName = avatarName
        selectedImage = nil
        if let avatarImage = UIImage(named: avatarName) {
            currentProfileImageView.image = avatarImage
            currentProfileImageView.contentMode = .scaleAspectFill
        }
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let spacing: CGFloat = 16
        let columns: CGFloat = 3
        let totalSpacing = spacing * (columns - 1)
        let availableWidth = collectionView.bounds.width - totalSpacing
        let itemWidth = availableWidth / columns
        return CGSize(width: itemWidth, height: itemWidth)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

class AvatarCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let selectionView = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) wasn't implemented in AvatarCell")
    }
    
    private func setupCell() {
        
        // avatar image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        
        // the border around the avatar when selected
        selectionView.layer.borderWidth = 4
        selectionView.layer.borderColor = ThemeColor.Color.titleOutline.cgColor
        selectionView.backgroundColor = .clear
        selectionView.isHidden = true
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(selectionView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            selectionView.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.layer.cornerRadius = bounds.width / 2
        selectionView.layer.cornerRadius = bounds.width / 2
    }
    
    func configure(with image: UIImage?, isSelected: Bool) {
        imageView.image = image
        selectionView.isHidden = !isSelected
    }
}
