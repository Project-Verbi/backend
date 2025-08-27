import Fluent

struct CreateDownload: AsyncMigration {
    func prepare(on database: any Database) async throws {
        try await database.schema("downloads")
            .id()
            .field("created_at", .datetime, .required)
            .unique(on: "id")
            .create()
    }

    func revert(on database: any Database) async throws {
        try await database.schema("downloads").delete()
    }
}