//
//  DescribeLLMViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/12/25.
//

import UIKit

class DescribeLLMViewController: UIViewController, UITextViewDelegate {
    
    // Callback to return a new playlist to the list VC
    var onCreate: ((Playlist) -> Void)?
    
    private let describeLabel = UILabel()
    private let textArea = UITextView()
    private let createButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Describe Playlist"
        view.backgroundColor = ThemeColor.Color.backgroundColor
        textArea.delegate = self
        
        setupScreen()
    }
    
    private func setupScreen() {
        describeLabel.text = "Describe the type of playlist you would like to create in 1-2 sentences."
        describeLabel.numberOfLines = 0
        describeLabel.textAlignment = .center
        describeLabel.font = .systemFont(ofSize: 16, weight: .regular)
        describeLabel.textColor = .white
        describeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(describeLabel)
        
        textArea.font = .systemFont(ofSize: 16)
        textArea.layer.cornerRadius = 8
        textArea.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
        textArea.layer.borderWidth = 1
        textArea.layer.borderColor = UIColor.secondaryLabel.cgColor
        textArea.translatesAutoresizingMaskIntoConstraints = false
        textArea.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        view.addSubview(textArea)
        
        setupCreateButton()
        
        NSLayoutConstraint.activate([
            
            
            describeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 48),
            describeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            describeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            textArea.topAnchor.constraint(equalTo: describeLabel.bottomAnchor, constant: 24),
            textArea.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textArea.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            textArea.heightAnchor.constraint(equalToConstant: 150),
            
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            
        ])
        
        
    }
    
    private func setupCreateButton() {
        createButton.setTitle("Generate Playlist", for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        createButton.backgroundColor = .systemBlue
        createButton.setTitleColor(.white, for: .normal)
        createButton.layer.cornerRadius = 8
        createButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        
        createButton.addTarget(self, action: #selector(createPlaylistTapped), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton)
    }
    
    @objc private func createPlaylistTapped() {
        
        let alert = UIAlertController(title: "Coming Soon!", message: "This feature will be implemented soon.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }

        func textFieldShouldReturn(_ textField:UITextField) -> Bool {
            textArea.resignFirstResponder()
            return true
        }
        
        // Called when the user clicks on the view outside of the UITextField
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }


}
