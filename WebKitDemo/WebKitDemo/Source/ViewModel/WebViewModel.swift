//
//  WebViewModel.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/22.
//

import Foundation
import RxSwift
import RxCocoa
import WebKit

// MARK: - Web Protocols
protocol WebViewModel: HasDelegate where Delegate: WebViewModelDelegate {
    var url: URL? { get }
    var history: Data? { get set }

    func didNavigate(to url: URL, webView: WKWebView)
}

@objc
protocol WebViewModelDelegate: NSObjectProtocol {
    func updateHistory(_ data: Data)
}

// MARK: - Web Implementation
final class WebDefaultViewModel: NSObject, WebViewModel {
    
    // MARK: - Properties
    weak var delegate: WebViewModelDelegate?
    private(set) var url: URL?
    var history: Data?
    
    // MARK: - Initializer
    required override init() {
        super.init()
    }
    
    convenience init(url: URL?, history: Data?) {
        self.init()
        self.url = url
        self.history = history
    }
    
    func didNavigate(to url: URL, webView: WKWebView) {
        // NOTE: not proper to save webView.backForwardList here
        // since WKNavigationDelegate won't handle pushstate js change
        // REF: https://stackoverflow.com/questions/71581701/observe-backforwardlist-changes-of-wkwebview
    }
}
