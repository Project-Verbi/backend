import Fluent
import Vapor

struct DownloadController {

    @Sendable
    func track(req: Request) async throws -> Response {
        let downloadDTO = try req.content.decode(DownloadDTO.self)
        
        guard let id = downloadDTO.id else {
            throw Abort(.badRequest, reason: "Download ID is required")
        }
        
        // Check if download with this ID already exists
        if let existingDownload = try await Download.find(id, on: req.db) {
            return try await existingDownload.toDTO().encodeResponse(status: .conflict, for: req)
        }
        
        let download = downloadDTO.toModel()
        download.id = id
        
        try await download.save(on: req.db)
        return try await download.toDTO().encodeResponse(status: .created, for: req)
    }
    
    @Sendable
    func getTotalCount(req: Request) async throws -> [String: Int] {
        let count = try await Download.query(on: req.db).count()
        return ["count": count]
    }
}