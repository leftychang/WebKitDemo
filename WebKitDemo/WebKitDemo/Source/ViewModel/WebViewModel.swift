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
    
    func didNavigate(to url: URL, webView: WKWebView)
}

@objc
protocol WebViewModelDelegate: NSObjectProtocol {

}

// MARK: - Web Implementation
final class WebDefaultViewModel: NSObject, WebViewModel {
    
    // MARK: - Properties
    weak var delegate: WebViewModelDelegate?
    private(set) var url: URL?
    
    // MARK: - Initializer
    convenience init(url: URL?) {
        self.init()
        self.url = url
    }
    
    func didNavigate(to url: URL, webView: WKWebView) {
    }
}
