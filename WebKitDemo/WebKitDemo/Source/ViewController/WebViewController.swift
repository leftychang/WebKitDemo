//
//  WebViewController.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/19.
//

import UIKit

final class WebViewController: UIViewController {
    
}

// MARK: - CustomTransitioningNavigationTarget
extension WebViewController: CustomTransitioningNavigationTarget {
    var backwardMovable: Bool { true }
    var forwardMovable: Bool { false }
}
