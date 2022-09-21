//
//  TransitionAnimator.swift
//  WebKitDemo
//
//  Created by Artur Rymarz on 01.08.2018.
//  Copyright © 2018 OpenSource. All rights reserved.
//  Modified by Lefty Chang on 2022/9/19.
//

import UIKit

final class TransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    // MARK: - Properties
    // Property that indicates if the animator is being responsible for a push or a pop navigation.
    let presenting: Bool

    // MARK: - Initializer
    init(presenting: Bool) {
        self.presenting = presenting
    }

    // MARK: - Methods
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        // You can set any custom duration as you wish. I have used constant from UINavigationController to fit other (hiding/showing bar) animations in the application.
        return TimeInterval(UINavigationController.hideShowBarDuration)
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        // We need a controller’s views that will be animated and we can access them through UIViewControllerContextTransitioning’s method viewController(forKey: ).
        guard let fromViewController = transitionContext.viewController(forKey: .from),
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromView = fromViewController.view,
            let toView = toViewController.view else {
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            return
        }

        // Since we already defined our duration in another method simply we access it here.
        let duration = transitionDuration(using: transitionContext)

        // We access containerView here which acts as the superview for the views involved in the transition. Depending if we present or dismiss view controller we either add destination view to our container or add it below source (fromView) view.
        let container = transitionContext.containerView

        container.insertSubview(toView, belowSubview: fromView)
        toView.isUserInteractionEnabled = false

        // Here we set an initial frame for our destination view which in my sample it is being a little bit to the left or right of source view — that will allow us to create smooth slide/move animation. Also, it is the place where “magic” happens — create any animation you want here. I have created fade animation for first half part of the whole animation and slide/move animation for the whole duration of it.
        let toViewFrame = toView.frame
        toView.frame = CGRect(x: presenting ? 0 : -toView.frame.width, y: toView.frame.origin.y, width: toView.frame.width, height: toView.frame.height)

        let animations = {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1) {
                toView.frame = toViewFrame
                fromView.frame = CGRect(x: self.presenting ? -fromView.frame.width : fromView.frame.width, y: fromView.frame.origin.y, width: fromView.frame.width, height: fromView.frame.height)
            }
        }

        UIView.animateKeyframes(withDuration: duration,
                                delay: 0,
                                options: .calculationModeLinear,
                                animations: animations,
                                completion: { finished in
                                    // In case of transition being canceled we have to clean up everything that we have done during the process — I simply remove added destination view from the container.
                                    toView.isUserInteractionEnabled = true
                                    if !transitionContext.transitionWasCancelled {
                                        container.bringSubviewToFront(toView)
                                    }
                                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}

