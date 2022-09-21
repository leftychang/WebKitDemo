//
//  WebViewController.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/19.
//

import UIKit
import WebKit

protocol WebViewCoordinatable: AnyObject {
    func webViewController(_ viewController: WebViewController, didRequestOpenURLInDefaultBrowser url: URL)
}

final class WebViewController: UIViewController {
    
    // MARK: - Properties
    weak var coordinator: WebViewCoordinatable?
    var viewModel: (any WebViewModel)?
    @IBOutlet private var webViewContainer: UIView!
    @IBOutlet private var activityIndicator: UIActivityIndicatorView!
    
    private lazy var webView: WKWebView = {
        let webConfiguration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        preferences.javaScriptCanOpenWindowsAutomatically = false
        
        webConfiguration.userContentController = contentController
        webConfiguration.preferences = preferences
        webConfiguration.allowsInlineMediaPlayback = true
        webConfiguration.allowsAirPlayForMediaPlayback = true
        webConfiguration.mediaTypesRequiringUserActionForPlayback = []
        webConfiguration.dataDetectorTypes = []
        webConfiguration.allowsPictureInPictureMediaPlayback = true
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.autoresizingMask = []
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }()
    
    private lazy var setupView: Void = {
        webViewContainer.addSubview(webView)
        let leading = webViewContainer.leadingAnchor.constraint(equalTo: webView.leadingAnchor)
        let trailing = webViewContainer.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        let top = webViewContainer.topAnchor.constraint(equalTo: webView.topAnchor)
        let bottom = webViewContainer.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        NSLayoutConstraint.activate([leading, trailing, top, bottom])
    }()
    
    private lazy var initialBindings: Void = {
        if let url = viewModel?.url {
            webView.load(URLRequest(url: url))
        }
    }()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = setupView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _ = initialBindings
    }
}

// MARK: - WKNavigationDelegate
extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            if navigationAction.targetFrame == nil {
                // allowed to open with a new window navigation
                if url.absoluteString.range(of: "http://") != nil ||
                    url.absoluteString.range(of: "https://") != nil ||
                    url.absoluteString.range(of: "mailto://") != nil {
                    coordinator?.webViewController(self, didRequestOpenURLInDefaultBrowser: url)
                    decisionHandler(.allow)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
                
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        if let url = webView.url {
            viewModel?.didNavigate(to: url, webView: webView)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
}

// MARK: - CustomTransitioningNavigationTarget
extension WebViewController: CustomTransitioningNavigationTarget {
    var backwardMovable: Bool { true }
    var forwardMovable: Bool { false }
}
