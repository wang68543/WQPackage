//
//  ViewController.swift
//  WQPackage
//
//  Created by wang68543 on 02/18/2019.
//  Copyright (c) 2019 wang68543. All rights reserved.
//

import UIKit
import WQPackage
import RxSwift
import RxCocoa
public let sevice = RxMoyaService(metroProvider)
class ViewController: UIViewController  {
    let bag: DisposeBag = DisposeBag()
    override func viewDidLoad() {
        super.viewDidLoad()
        
//       let obserable =  sevice.request(.citymaplist)
//        .debug().mapJSON().subscribe(onSuccess: <#T##((Any) -> Void)?##((Any) -> Void)?##(Any) -> Void#>, onError: <#T##((Error) -> Void)?##((Error) -> Void)?##(Error) -> Void#>)
////         print("Resource count \(RxSwift.Resources.total)")
//        obserable.dispose()
////         print("Resource count \(RxSwift.Resources.total)")
//        debugPrint("***************")
////        obserable.disposed(by: bag)
//        
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3) {
//            print("Resource count \(RxSwift.Resources.total)")
//        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

