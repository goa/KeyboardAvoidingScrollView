//
//  ViewController4.swift
//  keyavoidtest
//
//  Created by Manolis Katsifarakis on 08/03/2019.
//  Copyright © 2019 Emmanouil Katsifarakis. All rights reserved.
//

import UIKit

class MyViewController: UIViewController {
    /// You could also add your text field or text view programmatically,
    /// but let's say it's coming from a .xib for now...
    @IBOutlet private weak var myTextField: UITextField!
    
    /// This is required for the inputAccessoryView to work.
    override internal var canBecomeFirstResponder: Bool {
        return true
    }
    
    /// Here's a nice empty red view that will be used as an
    /// input accessory.
    private lazy var accessoryView: UIView = {
        let accessoryView = UIView()
        accessoryView.backgroundColor = UIColor.red
        accessoryView.frame.size = CGSize(
            width: view.frame.size.width,
            height: 45
        )
        
        return accessoryView
    } ()
    
    override var inputAccessoryView: UIView? {
        return accessoryView
    }
    
    /// This is required to avoid leaking the `inputAccessoryView`
    /// when the keyboard is open and the `UIViewController`
    /// is deallocated.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        myTextField.inputAccessoryView = nil
    }
}
