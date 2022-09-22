//
//  ContainerViewController.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/18.
//

import UIKit
import RxSwift
import RxCocoa

protocol ContainerViewCoordinatable: AnyObject {
    func containerViewControllerCanGoBackDriver(_ viewController: ContainerViewController) -> Driver<Bool>
    func containerViewControllerCanGoForwardDriver(_ viewController: ContainerViewController) -> Driver<Bool>
    func containerViewControllerDidRequestBackwardMove(_ viewController: ContainerViewController)
    func containerViewControllerDidRequestForwardMove(_ viewController: ContainerViewController)
}

final class ContainerViewController: UIViewController {

    // MARK: - Properties
    weak var coordinator: ContainerViewCoordinatable?
    var navController: CustomTransitioningNavigationController?
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        .portrait
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .all
    }
    
    override var shouldAutorotate: Bool {
        true
    }
    
    private let disposeBag = DisposeBag()
    
    @IBOutlet private weak var backwardBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var forwardBarButtonItem: UIBarButtonItem!
    
    lazy var initialBindings: Void = {
        coordinator?.containerViewControllerCanGoBackDriver(self)
            .drive(backwardBarButtonItem.rx.isEnabled)
            .disposed(by: disposeBag)
        coordinator?.containerViewControllerCanGoForwardDriver(self)
            .drive(forwardBarButtonItem.rx.isEnabled)
            .disposed(by: disposeBag)
    }()
    
    // MARK: - View Life Cycle
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let viewController = segue.destination as? CustomTransitioningNavigationController {
            navController = viewController
        }
    }
    
    // MARK: - Actions
    @IBAction func backwardMove(_ sender: Any) {
        coordinator?.containerViewControllerDidRequestBackwardMove(self)
    }
    
    @IBAction func forwardMove(_ sender: Any) {
        coordinator?.containerViewControllerDidRequestForwardMove(self)
    }
}

