//
//  StartPageViewController.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/19.
//

import UIKit

protocol StartPageViewCoordinatable: AnyObject {
    func startPageViewControllerDidRequestStartNavigation(_ viewController: StartPageViewController)
    func startPageViewControllerForwardMovable(_ viewController: StartPageViewController) -> Bool
}

final class StartPageViewController: UIViewController {

    // MARK: - Properties
    weak var coordinator: StartPageViewCoordinatable?
    
    // MARK: - Actions
    @IBAction func startNavigation(_ sender: Any) {
        coordinator?.startPageViewControllerDidRequestStartNavigation(self)
    }
}

// MARK: - CustomTransitioningNavigationTarget
extension StartPageViewController: CustomTransitioningNavigationTarget {
    var backwardMovable: Bool { false }
    var forwardMovable: Bool {
        coordinator?.startPageViewControllerForwardMovable(self) ?? false
    }
}
