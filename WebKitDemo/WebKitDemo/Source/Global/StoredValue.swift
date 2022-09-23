//
//  StoredValue.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/22.
//

import Foundation
import RxSwift
import RxCocoa
import GRDB
import RxGRDB

enum StoredValueError: Error {
    case dbQueueAsNil
}

final class StoredValue {
    static let shared = StoredValue()
    
    // MARK: - Definitions
    enum Keys: String {
        case navigationPage = "NavigationPage"
    }
    
    // MARK: - Properties
    var navigationPage: NavigationPage {
        get {
            if let data = UserDefaults.standard.data(forKey: Keys.navigationPage.rawValue),
               let page = try? JSONDecoder().decode(NavigationPage.self, from: data) {
                return page
            }
            else {
                return .startPage
            }
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: Keys.navigationPage.rawValue)
            }
        }
    }
    
    private var dbPath: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!.appendingPathComponent("webkitdemo.sqlite")
    }
    
    private var dbQueue: DatabaseQueue? {
        if _dbQueue == nil {
            // Open a database connection
            if let dbQueue = try? DatabaseQueue(path: dbPath.absoluteString) {
                // Define the database schema
                do {
                    try dbQueue.write { db in
//                        try? db.drop(table: "history") // test code
                        try History.createDatabaseSchema(db)
                    }
                    
                    _dbQueue = dbQueue
                }
                catch {
                    // TODO: error handling
                    print(error)
                }
            }
        }
        return _dbQueue
    }
    
    private var _dbQueue: DatabaseQueue?
    
    // MARK: - Initializer
    init() {
        if let data = try? JSONEncoder().encode(NavigationPage.startPage) {
            UserDefaults.standard.register(defaults: [Keys.navigationPage.rawValue: data])
        }
    }
    
    // MARK: - Methods
    func saveHistory(_ history: [History], completion: @escaping (Result<Void, Error>) -> Void) {
        if let dbQueue = dbQueue {
            dbQueue.asyncWrite({ db -> Void in
                let request = History.all()
                do {
                    let changeCount = try request.deleteAll(db)
                    print(changeCount)
                }
                catch {
                    // TODO: error handling
                    print(error)
                }
                try history.forEach { navigationHistory in
                    try navigationHistory.save(db)
                }
            }) { db, result in
                completion(result)
            }
        }
        else {
            completion(.failure(StoredValueError.dbQueueAsNil))
        }
    }
    
    func loadHistory(completion: @escaping (Result<[History], Error>) -> Void) {
        if let dbQueue = dbQueue {
            dbQueue.asyncRead { (dbResult: Result<Database, Error>) in
                do {
                    // Maybe read access could not be established
                    let db = try dbResult.get()
                    let request = History.all().order(History.CodingKeys.id.asc)
                    let history = try request.fetchAll(db)
                    completion(.success(history))
                }
                catch {
                    completion(.failure(error))
                }
            }
        }
        else {
            completion(.failure(StoredValueError.dbQueueAsNil))
        }
    }
    
    // Rx Observables, which do not access the database until they are subscribed. They complete on the main dispatch queue by default. (unless you provide a specific scheduler to the observeOn argument.)
    // You can ignore its value and turn it into a Completable with the asCompletable operator.
    func saveHistory(_ history: [History]) -> Single<Int>? {
        if let dbQueue = dbQueue {
            let newHistoryCountObservable = dbQueue.rx.write { db -> Int in
                let request = History.all()
                do {
                    let changeCount = try request.deleteAll(db)
                    print(changeCount)
                }
                catch {
                    // TODO: error handling
                    print(error)
                }
                try history.forEach { navigationHistory in
                    try navigationHistory.save(db)
                }
                return try request.fetchCount(db)
            }
            return newHistoryCountObservable
        }
        return nil
    }
    
    func loadHistory() -> Single<[History]>? {
        if let dbQueue = dbQueue {
            let historyObservable = dbQueue.rx.read { db -> [History] in
                let request = History.all().order(History.CodingKeys.id.asc)
                let history = try request.fetchAll(db)
                return history
            }
            return historyObservable
        }
        return nil
    }
}
