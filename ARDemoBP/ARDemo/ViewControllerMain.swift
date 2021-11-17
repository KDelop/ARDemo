//
//  ViewControllerMain.swift
//  ARDemoBP
//
//  Created by Stephen Brown on 3/14/21.
//

import UIKit

class ViewControllerMain: UIViewController {

    @IBAction func segm(_ sender: UISegmentedControl) {
        
        let defaults = UserDefaults.standard
        
        switch sender.selectedSegmentIndex {
        case 0:
            print("Sneakertopia Case")
            defaults.set("Sneakertopia", forKey: "Showing")
        case 1:
            print("Presentation Case")
            defaults.set("Presentation", forKey: "Showing")
        case 2:
            print("Website Case")
            defaults.set("Website", forKey: "Showing")
        default:
            print("Did not find case")
            defaults.set("Sneakertopia", forKey: "Showing")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaults = UserDefaults.standard
        defaults.set("Sneakertopia", forKey: "Showing")
        
        
    }
    
}
