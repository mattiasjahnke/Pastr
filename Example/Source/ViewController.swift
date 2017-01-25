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
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var resultTextView: UITextView!
    @IBOutlet weak var pasteKeyTextField: UITextField!
    @IBOutlet weak var fetchButton: UIButton!
    @IBOutlet weak var postButton: UIButton!
    
    fileprivate var buttonsEnabled: Bool {
        set {
            fetchButton.isEnabled = newValue
            postButton.isEnabled = newValue
        }
        get { return postButton.isEnabled }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ******************* TODO: ADD YOUR API KEY HERE *******************
        
        pasteBinApiKey = "<Your API key>"
        
        resultTextView.text = ""
    }
    
    @IBAction func postPasteButtonTapped(_ sender: UIButton) {
        buttonsEnabled = false
        PasteRequest(content: textView.text).post { result in
            defer { self.buttonsEnabled = true }
            switch result {
            case .failure(let error): self.displayErrorAlert(error)
            case .success(let key): self.pasteKeyTextField.text = key
            }
        }
    }
    
    @IBAction func fetchPasteButtonTapped(_ sender: UIButton) {
        getPaste(for: pasteKeyTextField.text!) { result in
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
}


