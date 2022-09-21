//
//  AppCoordinator.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/22.
//

import UIKit
import RxSwift

final class AppCoordinator: RootViewCoordinator {
    
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController
    private var containerViewController: ContainerViewController? {
        rootViewController as? ContainerViewController
    }
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    // MARK: - Methods
    func start() {
        containerViewController?.navController?.coordinator = self
    }
}

// MARK: - CustomTransitioningNavigationCoordinatable
extension AppCoordinator: CustomTransitioningNavigationCoordinatable {
    func customTransitioningNavigationControllerDidRequestBackwardMove(_ viewController: CustomTransitioningNavigationController, animated: Bool) {
        viewController.popViewController(animated: animated)
    }
    
    func customTransitioningNavigationControllerDidRequestForwardMove(_ viewController: CustomTransitioningNavigationController, animated: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let webViewController = storyboard.instantiateViewController(withIdentifier: "WebView") as? WebViewController {
            viewController.pushViewController(webViewController, animated: animated)
        }
    }
    
    func customTransitioningNavigationControllerDidEndBackwardMove(_ viewController: CustomTransitioningNavigationController, finished: Bool) {
        
    }
    
    func customTransitioningNavigationControllerDidEndForwardMove(_ viewController: CustomTransitioningNavigationController, finished: Bool) {
        
    }
}
