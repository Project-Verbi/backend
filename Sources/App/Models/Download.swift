import Foundation
@preconcurrency import SQLite

/// Model representing a download/install tracking record
public struct Download {
    public let id: Int64?
    public let identifier: String
    public let timestamp: Date
    
    public init(id: Int64? = nil, identifier: String, timestamp: Date = Date()) {
        self.id = id
        self.identifier = identifier
        self.timestamp = timestamp
    }
}

/// SQLite table definition for downloads
public class DownloadsTable {
    public static let table = Table("downloads")
    public static let id = Expression<Int64>("id")
    public static let identifier = Expression<String>("identifier")
    public static let timestamp = Expression<Date>("timestamp")
    
    public static func createTableStatement() -> String {
        return table.create(ifNotExists: true) { t in
            t.column(id, primaryKey: .autoincrement)
            t.column(identifier)
            t.column(timestamp)
            t.unique(identifier) // Ensure unique identifiers
        }
    }
} 