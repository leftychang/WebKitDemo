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
    private var webViewController: WebViewController?
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Initializer
    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    // MARK: - Methods
    func start() {
        containerViewController?.navController?.coordinator = self
        if let startPageViewController = containerViewController?.navController?.viewControllers[0] as? StartPageViewController {
            startPageViewController.coordinator = self
        }
    }
    
    private func fetchWebViewController() -> WebViewController? {
        guard webViewController == nil else {
            return webViewController
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "WebView") as? WebViewController {
            let webViewModel = WebDefaultViewModel(url: URL(string: "https://www.google.com"))
            viewController.viewModel = webViewModel
            viewController.coordinator = self
            webViewController = viewController
        }
        return webViewController
    }
}

// MARK: - CustomTransitioningNavigationCoordinatable
extension AppCoordinator: CustomTransitioningNavigationCoordinatable {
    func customTransitioningNavigationControllerDidRequestBackwardMove(_ viewController: CustomTransitioningNavigationController, animated: Bool) {
        viewController.popViewController(animated: animated)
    }
    
    func customTransitioningNavigationControllerDidRequestForwardMove(_ viewController: CustomTransitioningNavigationController, animated: Bool) {
        if let webViewController = fetchWebViewController() {
            viewController.pushViewController(webViewController, animated: animated)
        }
    }
    
    func customTransitioningNavigationControllerDidEndBackwardMove(_ viewController: CustomTransitioningNavigationController, finished: Bool) {
        
    }
    
    func customTransitioningNavigationControllerDidEndForwardMove(_ viewController: CustomTransitioningNavigationController, finished: Bool) {
        
    }
}

// MARK: - StartPageViewCoordinatable
extension AppCoordinator: StartPageViewCoordinatable {
    func startPageViewControllerDidRequestStartNavigation(_ viewController: StartPageViewController) {
        if let webViewController = fetchWebViewController() {
            viewController.navigationController?.pushViewController(webViewController, animated: false)
        }
    }
    
    func startPageViewControllerForwardMovable(_ viewController: StartPageViewController) -> Bool {
        // TODO: navigation history restoring
        guard webViewController == nil else {
            return true
        }
        return false
    }
}

// MARK: - WebViewCoordinatable
extension AppCoordinator: WebViewCoordinatable {
    func webViewController(_ viewController: WebViewController, didRequestOpenURLInDefaultBrowser url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
