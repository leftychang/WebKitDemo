//
//  AppCoordinator.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/22.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit
import Combine

final class AppCoordinator: RootViewCoordinator {
    
    // MARK: - Properties
    var childCoordinators: [Coordinator] = []
    
    var rootViewController: UIViewController
    private var containerViewController: ContainerViewController? {
        rootViewController as? ContainerViewController
    }
    private var webViewController: WebViewController?
    
    var canGoBack: Driver<Bool> {
        canGoBackRelay.asDriver()
    }
    private let canGoBackRelay = BehaviorRelay<Bool>(value: false)
    
    var canGoForward: Driver<Bool> {
        canGoForwardRelay.asDriver()
    }
    private let canGoForwardRelay = BehaviorRelay<Bool>(value: false)
    
    private let disposeBag = DisposeBag()
    private var cancellables: Set<AnyCancellable> = []
    
    private lazy var initialBindings: Void = {
        if let customTransitioningNavigationController = containerViewController?.navController {
            _ = customTransitioningNavigationController.rx
                .didShow
                .take(until: customTransitioningNavigationController.rx.deallocated)
                .subscribe(onNext: { [weak self] showEvent in
                    if let webViewController = showEvent.viewController as? WebViewController {
                        self?.canGoBackRelay.accept(true)
                        self?.canGoForwardRelay.accept(webViewController.webView.canGoForward)
                        StoredValue.shared.navigationPage = .webPage
                    }
                    else if showEvent.viewController is StartPageViewController {
                        self?.canGoBackRelay.accept(false)
                        self?.canGoForwardRelay.accept(self?.webViewController != nil)
                        StoredValue.shared.navigationPage = .startPage
                    }
                })
        }
    }()
    
    // MARK: - Initializer
    init(rootViewController: UIViewController) {
        self.rootViewController = rootViewController
    }
    
    // MARK: - Methods
    func start() {
        containerViewController?.coordinator = self
        containerViewController?.navController?.coordinator = self
        if let startPageViewController = containerViewController?.navController?.viewControllers[0] as? StartPageViewController {
            startPageViewController.coordinator = self
        }
        
        _ = initialBindings
        _ = containerViewController?.initialBindings
        
        // restore web view and do webViewBindings if needed
        // restore current session
        StoredValue.shared.loadHistory { [weak self] result in
            switch result {
            case let .success(history):
                if history.count > 1 {
                    DispatchQueue.main.async {
                        if let webViewController = self?.fetchWebViewController(with: history[1].data),
                           case .webPage = StoredValue.shared.navigationPage {
                            self?.containerViewController?.navController?.pushViewController(webViewController, animated: false)
                        }
                    }
                }
            case let .failure(error):
                print(error)
            }
        }
    }
    
    private func fetchWebViewController(with history: Data? = nil) -> WebViewController? {
        guard webViewController == nil else {
            return webViewController
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let viewController = storyboard.instantiateViewController(withIdentifier: "WebView") as? WebViewController {
            let webViewModel = WebDefaultViewModel(url: Setting.homePageURL, history: history)
            viewController.viewModel = webViewModel
            webViewModel.delegate = viewController
            viewController.coordinator = self
            webViewController = viewController
            
            webViewBindings(viewController.webView)
        }
        return webViewController
    }
    
    private func webViewBindings(_ webView: WKWebView) {
        webView.publisher(for: \.canGoForward)
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] canGoForward in
                if self.containerViewController?.navController?.topViewController is WebViewController {
                    self.canGoForwardRelay.accept(canGoForward)
                }
            }
            .store(in: &cancellables)
    }
    
    private func saveCurrentSession(_ webView: WKWebView) {
        // NOTE: not proper to save webView.backForwardList here
        // since somehow url is changed prior to backForwardList
        // may mess the history up
        // REF: https://stackoverflow.com/questions/71581701/observe-backforwardlist-changes-of-wkwebview
        // store session states instead
        // REF: https://stackoverflow.com/questions/73305403/wkwebview-history-serialization-on-ios
        var sessionData: Data?
        if #available(iOS 15.0, *) {
            sessionData = webView.interactionState as? Data
        }
        // NOTE: private API, may be rejected from Apple
        // REF: https://stackoverflow.com/questions/33017888/convert-unmanagedanyobject-to-bool-in-swift
        // REF: https://github.com/WebKit/webkit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm
        
        // IMPROVEMENT: mozilla solution https://stackoverflow.com/questions/26817420/why-i-cant-save-wkwebview-to-nsuserdefaults-standarduserdefaults/
        else if webView.responds(to: NSSelectorFromString("_sessionStateData")) {
            sessionData = webView.value(forKey: "_sessionStateData") as? Data
        }
        if let data = sessionData {
            var history: [History] = []
            if let startPage = History.startPageRepresentation() {
                history.append(startPage)
            }
            history.append(History.webViewRepresentation(data))
            StoredValue.shared.saveHistory(history) { result in
                switch result {
                case .success:
                    break
                case let .failure(error):
                    print(error)
                }
            }
        }
    }
}

// MARK: - ContainerViewCoordinatable
extension AppCoordinator: ContainerViewCoordinatable {
    func containerViewControllerCanGoBackDriver(_ viewController: ContainerViewController) -> Driver<Bool> {
        canGoBack
    }
    
    func containerViewControllerCanGoForwardDriver(_ viewController: ContainerViewController) -> Driver<Bool> {
        canGoForward
    }
    
    func containerViewControllerDidRequestBackwardMove(_ viewController: ContainerViewController) {
        guard canGoBackRelay.value else {
            return
        }
        if let webViewController = fetchWebViewController() {
            if webViewController.webView.canGoBack {
                webViewController.webView.goBack()
            }
            else {
                viewController.navController?.popViewController(animated: false)
            }
        }
    }
    
    func containerViewControllerDidRequestForwardMove(_ viewController: ContainerViewController) {
        guard canGoForwardRelay.value else {
            return
        }

        if let webViewController = fetchWebViewController() {
            if viewController.navController?.topViewController is StartPageViewController {
                viewController.navController?.pushViewController(webViewController, animated: false)
            }
            else {
                if webViewController.webView.canGoForward {
                    webViewController.webView.goForward()
                }
            }
        }
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
    
    func webViewController(_ viewController: WebViewController, didChangeURL url: URL?) {
        saveCurrentSession(viewController.webView)
    }
}
