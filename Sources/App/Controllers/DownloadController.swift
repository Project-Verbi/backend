import Hummingbird
import Foundation

/// Request and response models
public struct TrackDownloadRequest: Decodable {
    let identifier: String
}

public struct TrackDownloadResponse: Codable, ResponseEncodable {
    let success: Bool
    let message: String
}

/// Controller for download tracking endpoints
public struct DownloadController: Sendable {
    let databaseService: DatabaseService
    
    public init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }
    
    /// Track a download/install
    /// POST /track-download
    /// Body: { "identifier": "some-unique-string" }
    /// Returns: 200 OK for success (both new and existing downloads), 400 Bad Request for invalid input, 500 Internal Server Error for database errors
    public func trackDownload(_ request: Request, context: some RequestContext) async throws -> Response {
        let trackRequest: TrackDownloadRequest
        do {
            trackRequest = try await request.decode(as: TrackDownloadRequest.self, context: context)
        } catch {
            return Response(status: .badRequest)
        }
        
        // Validate identifier is not empty
        guard !trackRequest.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return Response(status: .badRequest)
        }
        
        do {
            let _ = try await databaseService.trackDownload(identifier: trackRequest.identifier)
            return Response(status: .ok)
        } catch {
            return Response(status: .internalServerError)
        }
    }
    
    /// Get download statistics
    /// GET /download-stats
    /// Returns: 200 OK with total count, 500 Internal Server Error for database errors
    public func getDownloadStats(_ request: Request, context: some RequestContext) async throws -> Response {
        do {
            let totalCount = try await databaseService.getUniqueDownloadCount()
            let response = ["totalUniqueDownloads": totalCount]
            let jsonData = try JSONEncoder().encode(response)
            return Response(status: .ok, headers: [.contentType: "application/json"], body: ResponseBody(byteBuffer: ByteBuffer(bytes: jsonData)))
        } catch {
            return Response(status: .internalServerError)
        }
    }
} 