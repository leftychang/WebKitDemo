# WebKitDemo

This project demonstrates an iOS native WebKit based browser which includes pages navigation and pages zoom features.
This README would document how different requirements were tackled.

## System Requirement

* Xcode 14
* Min. iOS version supported: 13.0
* Use UIKit
* Supported device orientations: portrait, landscape
* Supported device types: iPhone, iPad

## App Architecture

* `MVVM-C`. Since there're not many things other than coordination and UI behaviors, only one view controller has its view model. 

## Navigation and Transitioning

1. `ContainerViewController` is designed as the root view controller with a toolbar at the bottom. The toolbar has back and forward bar button items and has corresponding back and forward navigation actions.
1. There's a `CustomTransitioningNavigationController`, which is a UINavigationController's subclass, containing two view controllers, one for start page and the other for web page. The navigation controller is embedded in `ContainerViewController`, with top, leading, trailing anchor constraints equal to superview, and bottom anchor constraint equal to safe area. Since navigation controllers will remain their own safe area constraints, the WKWebView, as a subview of navigation controller, will be full screen (top to safe area, bottom to toolbar.topAnchor).
1. The toolbar's bar button items will be automatically enabled or disabled based on current navigation status. There are two drivers of RxSwift framework defined in `AppCoordinator`, `canGoBack` and `canGoForward`, binded to the bar button items' status. Whenever the `didShow` control event for `CustomTransitioningNavigationController` is triggered, the two drivers will be updated.
1. Also the web view's `canGoForward` property is observed by Combine framework and binded to `canGoForward` driver.
1. Touching up inside the toolbar button item will trigger pushing web view controller without animation, just like the behavior of clicking a link in a web page and navigate to another web page.
1. Two `UIScreenEdgePanGestureRecognizer` with left and right edges are registered to `CustomTransitioningNavigationController`'s view. The gestures' began, changed, ended, and cancelled states are used to update `UIPercentDrivenInteractiveTransition`. After the left edge gesture ended, the navigation controller will finish poping view controller, while the right gesture associated with pushing view controller.
1. The `WebViewController` is owned by `AppCoordinator`. So even if it is popped by `CustomTransitioningNavigationController`, the loaded website and status will be kept and ready to be pushed again.

## History

1. I have thought about how to save `webView.backForwardList`. First, it is not KVO compliant, so we cannot use Combine framework to observe the latest data. Second, it does not conform to Codable, so we have to design our own data structure and convert from it. Third, the update strategy for the property is unknown. I have tried to observe webView.url and found that sometimes `backForwardList` is lag to reflect the current state. 
1. It is also hard to record `backForwardList` by observing the flow in `WKNavigationDelegate`. When there's url changed by pushstate javasript, the delegate functions never get called. So url without observed may get lost.
1. Observation of url by Combine framework cannot be determinate because we don't know the direction is forward or backward, especially for pushstate javasript. It can be tested by searching keywords on google and clicking the filtered results.
1. Even if the backForwardList is saved, it is not a good user experience to restore it. There's no
API to directly assign it to web views. We can only load url request one by one. Futhermore, we cannot load all url requests immediately. We must wait for a few seconds to make sure it is recorded into backForwardList.
1. For the above reasons, we should have some other tricks to restore backForwardList. One is [Mozilla's solution](https://stackoverflow.com/a/31538352), loading a special html page from a local web server (running on localhost) that modifies the push state of the page and pushes previously visited URLs on the history stack. It is complicated.
1. For iOS 15, WKWebView has a property `interactionState` which can be used to save and restore current session. Nice.
1. How about iOS 13 and 14? There're [private APIs] (https://github.com/WebKit/webkit/blob/main/Source/WebKit/UIProcess/API/Cocoa/WKWebView.mm) `\_sessionStateData` and `\_restoreFromSessionStateData:`, which means it will be rejected by Apple. Also there's a comment saying that using the legacy session state encoder should be fixed. 
1. I still don't have a good answer, so I temporarily use private APIs to achieve the goal. It works.

## Zoom

1. The requirement is to implement page zoom feature which behaves exactly like in iOS Safari. I've tried tuning the properties of `webView.scrollView`, conforming `UIScrollViewDelegate`, and finding private APIs. Nothing works.
1. Adding `meta viewport` by javascript also failed.
1. Changing [css style](https://webkit.org/blog/5610/more-responsive-tapping-on-ios/) is in vain.
1. [WKWebViewConfiguration's ignoresViewportScaleLimits property](https://webkit.org/blog/7367/new-interaction-behaviors-in-ios-10/) seems good, but not for all situations.
1. Finally I found [adding event listeners](https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/HandlingEvents/HandlingEvents.html) `gesturestart`, `gesturechange`, `gestureend` works. After some trial and error, I found handling `gesturestart` and setting zoom scale for scroll view behave like Safari the most.

* That's all. Any feedback is welcome.



 
