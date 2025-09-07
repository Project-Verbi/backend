import Fluent
import struct Foundation.UUID
import struct Foundation.Date

/// Property wrappers interact poorly with `Sendable` checking, causing a warning for the `@ID` property
/// It is recommended you write your model with sendability checking on and then suppress the warning
/// afterwards with `@unchecked Sendable`.
final class Download: Model, @unchecked Sendable {
    static let schema = "downloads"
    
    @ID(key: .id)
    var id: UUID?

    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?

    init() { }

    init(id: UUID? = nil) {
        self.id = id
    }
    
    func toDTO() -> DownloadDTO {
        .init(
            id: self.id,
            createdAt: self.createdAt
        )
    }
}