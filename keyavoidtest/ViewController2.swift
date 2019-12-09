//
//  ViewController2.swift
//  keyavoidtest
//
//  Created by Manolis Katsifarakis on 02/03/2019.
//  Copyright © 2019 Emmanouil Katsifarakis. All rights reserved.
//

import UIKit

class ViewController2: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
    let tview = UIView()
    let tx = UITextField()
    override var inputAccessoryView: UIView? {
        tview.frame = CGRect(
            x: 0,
            y: 0,
            width: 320,
            height: 44
        )
        tview.backgroundColor = UIColor.red

        tx.delegate = self
        tx.textColor = UIColor.black
        tx.backgroundColor = UIColor.white
        tx.frame = CGRect(
            x: 50,
            y: 0,
            width: 200,
            height: 44
        )
        
        tview.addSubview(tx)
        
        return tview
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        becomeFirstResponder() // Required to make sure that `inputAccessoryView` is always visible.
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension ViewController2: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        resignFirstResponder()
    }
}
