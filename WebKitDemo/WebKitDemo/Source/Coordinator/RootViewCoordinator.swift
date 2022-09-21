//
//  RootViewCoordinator.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/22.
//

import UIKit

protocol RootViewControllerProvider: AnyObject {
    // The coordinators 'rootViewController'. It helps to think of this as the view
    // controller that can be used to dismiss the coordinator from the view hierarchy.
    var rootViewController: UIViewController { get }
}

// A Coordinator type that provides a root UIViewController
typealias RootViewCoordinator = Coordinator & RootViewControllerProvider
