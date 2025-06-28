import Hummingbird
import Foundation

/// Request and response models
public struct TrackDownloadRequest: Decodable {
    let identifier: String
}

public struct TrackDownloadResponse: Codable, ResponseEncodable {
    let success: Bool
    let message: String
    let isNewDownload: Bool
    let totalUniqueDownloads: Int
}

public struct DownloadStatsResponse: Codable, ResponseEncodable {
    let totalUniqueDownloads: Int
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
    public func trackDownload(_ request: Request, context: some RequestContext) async throws -> TrackDownloadResponse {
        let trackRequest = try await request.decode(as: TrackDownloadRequest.self, context: context)
        
        // Validate identifier is not empty
        guard !trackRequest.identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return TrackDownloadResponse(
                success: false,
                message: "Identifier cannot be empty",
                isNewDownload: false,
                totalUniqueDownloads: 0
            )
        }
        
        do {
            let isNewDownload = try await databaseService.trackDownload(identifier: trackRequest.identifier)
            let totalCount = try await databaseService.getUniqueDownloadCount()
            
            return TrackDownloadResponse(
                success: true,
                message: isNewDownload ? "Download tracked successfully" : "Download already exists",
                isNewDownload: isNewDownload,
                totalUniqueDownloads: totalCount
            )
        } catch {
            return TrackDownloadResponse(
                success: false,
                message: "Failed to track download: \(error.localizedDescription)",
                isNewDownload: false,
                totalUniqueDownloads: 0
            )
        }
    }
    
    /// Get download statistics
    /// GET /download-stats
    public func getDownloadStats(_ request: Request, context: some RequestContext) async throws -> DownloadStatsResponse {
        let totalCount = try await databaseService.getUniqueDownloadCount()
        return DownloadStatsResponse(totalUniqueDownloads: totalCount)
    }
} 