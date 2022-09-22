//
//  History.swift
//  WebKitDemo
//
//  Created by Lefty Chang on 2022/9/22.
//

import Foundation
import GRDB

enum NavigationPage: Codable {
    case startPage
    case webPage
}

// NavigationPage.startPage would be encoded to.
//
// {
//   "startPage": {}
// }

struct History: Codable {
    var id: Int
    var data: Data
    
    enum CodingKeys: String, CodingKey, ColumnExpression {
        case id
        case data
    }
    
    static func createDatabaseSchema(_ db: Database) throws {
        if try db.tableExists("history") {
            return
        }
        try db.create(table: "history", ifNotExists: true) { t in
            t.column("id", .integer).primaryKey().notNull()
            t.column("data", .blob)
        }
    }
    
    static func startPageRepresentation() -> History? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        guard let data = try? encoder.encode(NavigationPage.startPage) else {
            return nil
        }
        if let jsonString = String(data: data, encoding: .utf8) {
            print(jsonString)
        }
        return History(id: 0, data: data)
    }
    
    static func webViewRepresentation(_ data: Data) -> History {
        History(id: 1, data: data)
    }
}

// MARK: - Equatable
extension History: Equatable {
    public static func == (lhs: History, rhs: History) -> Bool {
        return lhs.id == rhs.id && lhs.data == rhs.data
    }
}

// MARK: - FetchableRecord
extension History: FetchableRecord {
}

// MARK: - PersistableRecord
extension History: PersistableRecord {
}

