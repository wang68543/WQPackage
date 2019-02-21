//
//  ViewController.swift
//  WQPackage
//
//  Created by wang68543 on 02/18/2019.
//  Copyright (c) 2019 wang68543. All rights reserved.
//

import UIKit
import WQPackage
public let sevice = RxMoyaService(metroProvider)
class ViewController: UIViewController  {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sevice.request(.citymaplist).subscribe(onSuccess: { response in
            
        }) { error in
            
        }.disposed(by: self.rx.)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

