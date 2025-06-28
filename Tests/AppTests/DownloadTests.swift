import Foundation
import Hummingbird
import HummingbirdTesting
import Logging
@preconcurrency import SQLite
import Testing

@testable import App

@Suite("Download Tests")
struct DownloadTests {
    
    @Test("Database service unique constraint")
    func databaseServiceUniqueConstraint() async throws {
        let connection = try Connection(":memory:")
        let logger = Logger(label: "test")
        let databaseService = try await DatabaseService(connection: connection, logger: logger)
        
        // First download should be new
        let isNew1 = try await databaseService.trackDownload(identifier: "test-device")
        #expect(isNew1 == true)
        
        // Second download with same identifier should not be new
        let isNew2 = try await databaseService.trackDownload(identifier: "test-device")
        #expect(isNew2 == false)
        
        // Count should be 1
        let count = try await databaseService.getUniqueDownloadCount()
        #expect(count == 1)
        
        // Different identifier should be new
        let isNew3 = try await databaseService.trackDownload(identifier: "another-device")
        #expect(isNew3 == true)
        
        // Count should be 2
        let finalCount = try await databaseService.getUniqueDownloadCount()
        #expect(finalCount == 2)
    }
    
    @Test("Integration with full application")
    func integrationWithFullApplication() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        
        try await app.test(.router) { client in
            // Test track download endpoint - should return 200 OK for success
            try await client.execute(
                uri: "/track-download",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: """
                {"identifier": "integration-test-device"}
                """)
            ) { response in
                #expect(response.status == .ok)
            }
            
            // Test duplicate download - should still return 200 OK (success even if already exists)
            try await client.execute(
                uri: "/track-download",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: """
                {"identifier": "integration-test-device"}
                """)
            ) { response in
                #expect(response.status == .ok)
            }
            
            // Test invalid request - empty identifier should return 400 Bad Request
            try await client.execute(
                uri: "/track-download",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: """
                {"identifier": ""}
                """)
            ) { response in
                #expect(response.status == .badRequest)
            }
            
            // Test invalid JSON should return 400 Bad Request
            try await client.execute(
                uri: "/track-download",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: "invalid json")
            ) { response in
                #expect(response.status == .badRequest)
            }
            
            // Test stats endpoint - should return 200 OK with JSON containing count
            try await client.execute(uri: "/download-stats", method: .get) { response in
                #expect(response.status == .ok)
                let data = Data(response.body.readableBytesView)
                let responseData = try JSONDecoder().decode([String: Int].self, from: data)
                #expect(responseData["totalUniqueDownloads"] == 1)
            }
        }
    }
} 