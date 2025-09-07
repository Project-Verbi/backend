import Fluent
import Vapor

struct DownloadController {

    @Sendable
    func track(req: Request) async throws -> Response {
        let downloadDTO = try req.content.decode(DownloadDTO.self)
        
        guard let id = downloadDTO.id else {
            throw Abort(.badRequest, reason: "Download ID is required")
        }
        
        let download = downloadDTO.toModel()
        download.id = id
        
        do {
            try await download.save(on: req.db)
            return Response(status: .created)
        } catch let error as any DatabaseError where error.isConstraintFailure {
            return Response(status: .conflict)
        } catch {
            throw error
        }
    }
    
    @Sendable
    func getTotalCount(req: Request) async throws -> [String: Int] {
        let count = try await Download.query(on: req.db).count()
        return ["count": count]
    }
}