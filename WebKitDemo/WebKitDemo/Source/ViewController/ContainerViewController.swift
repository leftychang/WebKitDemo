//
//  ContainerViewController.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/18.
//

import UIKit

final class ContainerViewController: UIViewController {

    // MARK: - Properties
    var navController: CustomTransitioningNavigationController?
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
    
    override var shouldAutorotate: Bool {
        true
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CustomTransitioningNavigationController {
            navController = viewController
        }
    }
}

