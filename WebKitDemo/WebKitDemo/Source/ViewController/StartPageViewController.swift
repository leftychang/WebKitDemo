//
//  StartPageViewController.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/19.
//

import UIKit

final class StartPageViewController: UIViewController {

}

// MARK: - CustomTransitioningNavigationTarget
extension StartPageViewController: CustomTransitioningNavigationTarget {
    var backwardMovable: Bool { false }
    var forwardMovable: Bool { true }
}
