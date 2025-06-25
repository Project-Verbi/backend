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
            // Test track download endpoint
            try await client.execute(
                uri: "/track-download",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: """
                {"identifier": "integration-test-device"}
                """)
            ) { response in
                #expect(response.status == .ok)
                let data = Data(buffer: response.body)
                let responseData = try JSONDecoder().decode(TrackDownloadResponse.self, from: data)
                #expect(responseData.success == true)
                #expect(responseData.isNewDownload == true)
                #expect(responseData.totalUniqueDownloads == 1)
            }
            
            // Test duplicate download
            try await client.execute(
                uri: "/track-download",
                method: .post,
                headers: [.contentType: "application/json"],
                body: ByteBuffer(string: """
                {"identifier": "integration-test-device"}
                """)
            ) { response in
                #expect(response.status == .ok)
                let data = Data(buffer: response.body)
                let responseData = try JSONDecoder().decode(TrackDownloadResponse.self, from: data)
                #expect(responseData.success == true)
                #expect(responseData.isNewDownload == false)
                #expect(responseData.totalUniqueDownloads == 1)
            }
            
            // Test stats endpoint
            try await client.execute(uri: "/download-stats", method: .get) { response in
                #expect(response.status == .ok)
                let data = Data(buffer: response.body)
                let responseData = try JSONDecoder().decode(DownloadStatsResponse.self, from: data)
                #expect(responseData.totalUniqueDownloads == 1)
            }
        }
    }
} 