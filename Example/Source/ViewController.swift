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
        
        Pastr.get(paste: pasteKeyTextField.text!, isPrivate: true) { result in
            defer { self.buttonsEnabled = true }
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let content): self.resultTextView.text = content
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


