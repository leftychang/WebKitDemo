//
//  Coordinator.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/22.
//

import Foundation

protocol Coordinator: AnyObject {
    
    // The array containing any child Coordinators
    var childCoordinators: [Coordinator] { get set }
    
}

extension Coordinator {
    
    // Add a child coordinator to the parent
    func addChildCoordinator(_ childCoordinator: Coordinator) {
        self.childCoordinators.append(childCoordinator)
    }
    
    // Remove a child coordinator from the parent
    func removeChildCoordinator(_ childCoordinator: Coordinator) {
        self.childCoordinators = self.childCoordinators.filter { $0 !== childCoordinator }
    }
    
    // Remove all child coordinators from the parent
    func removeAllChildCoordinators() {
        self.childCoordinators = []
    }
    
}
