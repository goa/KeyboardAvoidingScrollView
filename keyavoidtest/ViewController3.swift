//
//  ViewController3.swift
//  keyavoidtest
//
//  Created by Manolis Katsifarakis on 02/03/2019.
//  Copyright © 2019 Emmanouil Katsifarakis. All rights reserved.
//

import UIKit

class ViewController3: UIViewController {
    
    @IBOutlet weak var textField: UITextField!
    
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
