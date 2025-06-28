import Foundation
@preconcurrency import SQLite
import Logging

/// Service for managing database operations
public actor DatabaseService {
    private let db: Connection
    private let logger: Logger
    
    public init(path: String = "./downloads.db", logger: Logger) async throws {
        self.logger = logger
        self.db = try Connection(path)
        try await setupDatabase()
    }
    
    public init(connection: Connection, logger: Logger) async throws {
        self.db = connection
        self.logger = logger
        try await setupDatabase()
    }
    
    private func setupDatabase() async throws {
        try db.execute(DownloadsTable.createTableStatement())
        logger.info("Database initialized successfully")
    }
    
    /// Track a download/install by identifier
    /// Returns true if this is a new unique download, false if already exists
    public func trackDownload(identifier: String) async throws -> Bool {
        // Check if identifier already exists
        let existingCount = try db.scalar(
            DownloadsTable.table.filter(DownloadsTable.identifier == identifier).count
        )
        
        if existingCount > 0 {
            logger.info("Download already tracked", metadata: ["identifier": .string(identifier)])
            return false
        }
        
        // Insert new download record
        let insert = DownloadsTable.table.insert(
            DownloadsTable.identifier <- identifier,
            DownloadsTable.timestamp <- Date()
        )
        
        let rowId = try db.run(insert)
        logger.info("New download tracked", metadata: [
            "identifier": .string(identifier),
            "rowId": .stringConvertible(rowId)
        ])
        return true
    }
    
    /// Get total count of unique downloads
    public func getUniqueDownloadCount() async throws -> Int {
        let count = try db.scalar(DownloadsTable.table.count)
        return count
    }
    
    /// Get all downloads (for testing purposes)
    public func getAllDownloads() async throws -> [Download] {
        var downloads: [Download] = []
        
        for row in try db.prepare(DownloadsTable.table) {
            let download = Download(
                id: row[DownloadsTable.id],
                identifier: row[DownloadsTable.identifier],
                timestamp: row[DownloadsTable.timestamp]
            )
            downloads.append(download)
        }
        
        return downloads
    }
    
    /// Clear all downloads (for testing purposes)
    public func clearAllDownloads() async throws {
        try db.run(DownloadsTable.table.delete())
        logger.info("All downloads cleared")
    }
} 