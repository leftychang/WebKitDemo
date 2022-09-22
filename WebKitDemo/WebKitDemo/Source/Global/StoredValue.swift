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
    
    // MARK: - Properties
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
    
    // MARK: - Methods
    func saveHistory(_ history: [/*Navigation*/History], completion: @escaping (Result<Void, Error>) -> Void) {
        if let dbQueue = dbQueue {
            dbQueue.asyncWrite({ db -> Void in
                let request = /*Navigation*/History.all()
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
    
    func loadHistory(completion: @escaping (Result<[/*Navigation*/History], Error>) -> Void) {
        if let dbQueue = dbQueue {
            dbQueue.asyncRead { (dbResult: Result<Database, Error>) in
                do {
                    // Maybe read access could not be established
                    let db = try dbResult.get()
                    let request = /*Navigation*/History.all().order(/*Navigation*/History.CodingKeys.id.asc)
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
    func saveHistory(_ history: [/*Navigation*/History]) -> Single<Int>? {
        if let dbQueue = dbQueue {
            let newHistoryCountObservable = dbQueue.rx.write { db -> Int in
                let request = /*Navigation*/History.all()
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
    
    func loadHistory() -> Single<[/*Navigation*/History]>? {
        if let dbQueue = dbQueue {
            let historyObservable = dbQueue.rx.read { db -> [/*Navigation*/History] in
                let request = /*Navigation*/History.all().order(/*Navigation*/History.CodingKeys.id.asc)
                let history = try request.fetchAll(db)
                return history
            }
            return historyObservable
        }
        return nil
    }
}
