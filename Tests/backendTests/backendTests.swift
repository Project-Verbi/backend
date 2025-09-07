@testable import backend
import VaporTesting
import Testing
import Fluent

@Suite("App Tests with DB", .serialized)
struct backendTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        // Set test authentication token
        setenv("AUTH_TOKEN", "test-token-12345", 1)
        
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        } catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
        
        // Clean up environment
        unsetenv("AUTH_TOKEN")
    }
    
    @Test("Tracking a Download")
    func trackDownload() async throws {
        let downloadId = UUID()
        let newDTO = DownloadDTO(id: downloadId, createdAt: nil)
        
        try await withApp { app in
            try await app.testing().test(.POST, "downloads/track", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .created)
                let responseDTO = try res.content.decode(DownloadDTO.self)
                #expect(responseDTO.id == downloadId)
                #expect(responseDTO.createdAt != nil)
                
                let models = try await Download.query(on: app.db).all()
                #expect(models.count == 1)
                #expect(models[0].id == downloadId)
            })
        }
    }
    
    @Test("Tracking a Download with Duplicate ID Returns Conflict")
    func trackDuplicateDownload() async throws {
        let downloadId = UUID()
        let newDTO = DownloadDTO(id: downloadId, createdAt: nil)
        
        try await withApp { app in
            // First request should succeed
            try await app.testing().test(.POST, "downloads/track", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .created)
            })
            
            // Second request with same ID should return conflict
            try await app.testing().test(.POST, "downloads/track", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .conflict)
                
                // Should still only have one record
                let models = try await Download.query(on: app.db).all()
                #expect(models.count == 1)
            })
        }
    }
    
    @Test("Tracking a Download without ID Returns Bad Request")
    func trackDownloadWithoutId() async throws {
        let newDTO = DownloadDTO(id: nil, createdAt: nil)
        
        try await withApp { app in
            try await app.testing().test(.POST, "downloads/track", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .badRequest)
                
                let models = try await Download.query(on: app.db).all()
                #expect(models.count == 0)
            })
        }
    }
    
    @Test("Admin route requires authentication")
    func adminRouteRequiresAuthentication() async throws {
        try await withApp { app in
            // Request without authentication should fail
            try await app.testing().test(.GET, "admin/downloads/count", afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }
    
    @Test("Admin route works with valid authentication")
    func adminRouteWorksWithValidAuth() async throws {
        let downloadId = UUID()
        let newDTO = DownloadDTO(id: downloadId, createdAt: nil)
        
        try await withApp { app in
            // First create a download
            try await app.testing().test(.POST, "downloads/track", beforeRequest: { req in
                try req.content.encode(newDTO)
            }, afterResponse: { res async throws in
                #expect(res.status == .created)
            })
            
            // Then access admin route with correct token
            try await app.testing().test(.GET, "admin/downloads/count", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: "test-token-12345")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode([String: Int].self)
                #expect(response["count"] == 1)
            })
        }
    }
    
    @Test("Admin route fails with invalid authentication")
    func adminRouteFailsWithInvalidAuth() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "admin/downloads/count", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: "wrong-token")
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }
}
