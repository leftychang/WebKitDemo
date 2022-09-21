//
//  TransitionCoordinator.swift
//  WebKitDemo
//
//  Created by Artur Rymarz on 01.08.2018.
//  Copyright © 2018 OpenSource. All rights reserved.
//  Modified by Lefty Chang on 2022/9/19.
//

import UIKit

final class TransitionCoordinator: NSObject, UINavigationControllerDelegate {
    // MARK: - Properties
    var interactionController: UIPercentDrivenInteractiveTransition?

    // MARK: - Methods
    // We return here our custom animator depending on operation being either pop or push.
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return TransitionAnimator(presenting: true)
            
        case .pop:
            return TransitionAnimator(presenting: false)
            
        default:
            return nil
        }
    }

    // Returns interactionController to handle interactive transitioning.
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}

