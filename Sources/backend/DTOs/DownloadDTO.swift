import Fluent
import Vapor
import struct Foundation.Date

struct DownloadDTO: Content, Equatable {
    var id: UUID?
    var createdAt: Date?
    
    func toModel() -> Download {
        let model = Download()
        
        model.id = self.id
        return model
    }
}
