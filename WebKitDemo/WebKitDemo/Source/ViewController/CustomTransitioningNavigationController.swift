//
//  CustomTransitioningNavigationController.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/19.
//

import UIKit
import RxSwift
import RxGesture

protocol CustomTransitioningNavigationTarget: AnyObject {
    var backwardMovable: Bool { get }
    var forwardMovable: Bool { get }
}

protocol CustomTransitioningNavigationCoordinatable: AnyObject {
    func customTransitioningNavigationControllerDidRequestBackwardMove(_ viewController: CustomTransitioningNavigationController, animated: Bool)
    func customTransitioningNavigationControllerDidRequestForwardMove(_ viewController: CustomTransitioningNavigationController, animated: Bool)
    func customTransitioningNavigationControllerDidEndBackwardMove(_ viewController: CustomTransitioningNavigationController, finished: Bool)
    func customTransitioningNavigationControllerDidEndForwardMove(_ viewController: CustomTransitioningNavigationController, finished: Bool)
}

final class CustomTransitioningNavigationController: UINavigationController {
    
    let disposeBag = DisposeBag()
    
    // MARK: - Properties
    weak var coordinator: CustomTransitioningNavigationCoordinatable?
    
    private lazy var setupView: Void = {
        interactivePopGestureRecognizer?.isEnabled = false
        addCustomTransitioning()
    }()
    
    private lazy var initialBinginds: Void = {
        let screenEdgePanHandler: (CustomTransitioningNavigationController, UIScreenEdgePanGestureRecognizer) -> Void = { owner, gestureRecognizer in
            // Here we handle our screen edge pan gesture. There are few cases — once we begin our gesture we create an instance of UIPercentDrivenInteractiveTransition and start popping our controller. On finger move, we update the progress of back gesture and finally, on gesture’s end we either finish the transition (if we moved controller by at least a half-width and gesture was not canceled in meantime) or cancel it — in both cases, we clear the interactionController.
            guard let gestureRecognizerView = gestureRecognizer.view else {
                owner.transitionCoordinatorHelper?.interactionController = nil
                return
            }

            let percent = gestureRecognizer.translation(in: gestureRecognizerView).x / gestureRecognizerView.bounds.size.width

            switch gestureRecognizer.state {
            case .began:
                owner.transitionCoordinatorHelper?.interactionController = UIPercentDrivenInteractiveTransition()
                if gestureRecognizer.edges.contains(.left) {
                    owner.coordinator?.customTransitioningNavigationControllerDidRequestBackwardMove(owner, animated: true)
                }
                else if gestureRecognizer.edges.contains(.right) {
                    owner.coordinator?.customTransitioningNavigationControllerDidRequestForwardMove(owner, animated: true)
                }
                
            case .changed:
                if gestureRecognizer.edges.contains(.left) {
                    owner.transitionCoordinatorHelper?.interactionController?.update(percent)
                }
                else if gestureRecognizer.edges.contains(.right) {
                    owner.transitionCoordinatorHelper?.interactionController?.update(-percent)
                }
                
            case .ended, .cancelled:
                if gestureRecognizer.edges.contains(.left) {
                    if percent > 0.5 && gestureRecognizer.state != .cancelled {
                        owner.transitionCoordinatorHelper?.interactionController?.finish()
                        owner.coordinator?.customTransitioningNavigationControllerDidEndBackwardMove(owner, finished: true)
                    }
                    else {
                        owner.transitionCoordinatorHelper?.interactionController?.cancel()
                        owner.coordinator?.customTransitioningNavigationControllerDidEndBackwardMove(owner, finished: false)
                    }
                }
                else if gestureRecognizer.edges.contains(.right) {
                    if percent < -0.5 && gestureRecognizer.state != .cancelled {
                        owner.transitionCoordinatorHelper?.interactionController?.finish()
                        owner.coordinator?.customTransitioningNavigationControllerDidEndForwardMove(owner, finished: true)
                    }
                    else {
                        owner.transitionCoordinatorHelper?.interactionController?.cancel()
                        owner.coordinator?.customTransitioningNavigationControllerDidEndForwardMove(owner, finished: false)
                    }
                }
                owner.transitionCoordinatorHelper?.interactionController = nil
                
            default:
                break
            }
        }
        
        let registerScreenEdgePanGesture: (UIRectEdge) -> Void = { [unowned self] edge in
            self.view.rx
                .screenEdgePanGesture { [weak self] screenEdgePanGestureRecognizer, delegate in
                    screenEdgePanGestureRecognizer.edges = edge
                    screenEdgePanGestureRecognizer.delegate = self
                }
                .when(.began, .changed, .ended, .cancelled)
                .withUnretained(self)
                .subscribe { owner, gestureRecognizer in
                    screenEdgePanHandler(owner, gestureRecognizer)
                }
                .disposed(by: self.disposeBag)
        }
        registerScreenEdgePanGesture(.left)
        registerScreenEdgePanGesture(.right)
    }()
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = setupView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _ = initialBinginds
    }
}

// MARK: - UIGestureRecognizerDelegate
extension CustomTransitioningNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let screenEdgePan = gestureRecognizer as? UIScreenEdgePanGestureRecognizer else {
            return false
        }
        if let target = topViewController as? CustomTransitioningNavigationTarget {
            if screenEdgePan.edges.contains(.left) && target.backwardMovable {
                return true
            }
            else if screenEdgePan.edges.contains(.right) && target.forwardMovable {
                return true
            }
        }
        return false
    }
}

// MARK: - TransitionCoordinator
extension CustomTransitioningNavigationController {
    // MARK: - Properties
    // Just a static key which will be used to associate an object
    static private var coordinatorHelperKey = "CustomTransitioningNavigationController.TransitionCoordinatorHelper"

    // MARK: - Methods
    // A computed property that will return our associated TransitionCoordinator object.
    var transitionCoordinatorHelper: TransitionCoordinator? {
        return objc_getAssociatedObject(self, &CustomTransitioningNavigationController.coordinatorHelperKey) as? TransitionCoordinator
    }

    func addCustomTransitioning() {
        // Create an instance of TransitionCoordinator and associate it with the mentioned key.
        var object = objc_getAssociatedObject(self, &CustomTransitioningNavigationController.coordinatorHelperKey)

        guard object == nil else {
            return
        }

        object = TransitionCoordinator()
        let nonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
        objc_setAssociatedObject(self, &CustomTransitioningNavigationController.coordinatorHelperKey, object, nonatomic)

        // Set associated object as a delegate of UINavigationController.
        delegate = object as? TransitionCoordinator
    }
}
