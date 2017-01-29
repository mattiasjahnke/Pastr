//
//  ViewController.swift
//  iOS Example
//
//  Created by Mattias Jähnke on 2017-01-25.
//  Copyright © 2017 Mattias Jähnke. All rights reserved.
//

import UIKit
import Pastr

class ViewController: UIViewController {
    
    @IBOutlet weak var apiKeyTextField: UITextField!
    @IBOutlet weak var userKeyTextField: UITextField!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var pasteKeyTextField: UITextField!
    @IBOutlet weak var fetchButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
    @IBOutlet weak var scopeSegment: UISegmentedControl!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    fileprivate var buttonsEnabled: Bool {
        set {
            fetchButton.isEnabled = newValue
            postButton.isEnabled = newValue
        }
        get { return postButton.isEnabled }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultTextView.text = ""
        apiKeyTextField.text = UserDefaults.standard.string(forKey: "api-key")
        userKeyTextField.text = UserDefaults.standard.string(forKey: "user-key")
    }
    
    @IBAction func postPasteButtonTapped(_ sender: UIButton) {
        updateConfiguration()
        
        let scope: PastrScope
        switch scopeSegment.selectedSegmentIndex {
        case 0: scope = .unlisted
        case 1: scope = .public
        case 2: scope = .private
        default: fatalError()
        }
        
        buttonsEnabled = false
        Pastr.post(text: textView.text) { result in
            defer { self.buttonsEnabled = true }
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let key): self.pasteKeyTextField.text = key
            }
        }
    }
    
    @IBAction func fetchPasteButtonTapped(_ sender: UIButton) {
        updateConfiguration()
        
        Pastr.get(paste: pasteKeyTextField.text!) { result in
            defer { self.buttonsEnabled = true }
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let content): self.resultTextView.text = content
            }
        }
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        updateConfiguration()
        
        Pastr.login(username: usernameTextField.text!, password: passwordTextField.text!) { result in
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let key): self.userKeyTextField.text = key
            }
        }
    }
    
    @IBAction func getUserInfoTapped(_ sender: Any) {
        updateConfiguration()
        
        Pastr.getUserInfo { result in
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let info): self.resultTextView.text = info
            }
        }
    }
    
    @IBAction func getTrendingTapped(_ sender: Any) {
        updateConfiguration()
        
        Pastr.getTrendingPastes { result in
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let info): self.resultTextView.text = info
            }
        }
    }
    
    @IBAction func getPasteListTapped(_ sender: Any) {
        updateConfiguration()
        
        Pastr.getUserPastes(limit: 4) { result in
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let info): self.resultTextView.text = info
            }
        }
    }
    
    
    fileprivate func displayErrorAlert(_ error: Error) {
        let controller = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(controller, animated: true, completion: nil)
    }
    
    fileprivate func updateConfiguration() {
        Pastr.pastebinApiKey = apiKeyTextField.text!
        Pastr.pastebinUserKey = userKeyTextField.text!.isEmpty ? nil : userKeyTextField.text
        
        UserDefaults.standard.set(apiKeyTextField.text, forKey: "api-key")
        UserDefaults.standard.set(userKeyTextField.text, forKey: "user-key")
    }
}


