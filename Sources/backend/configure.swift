import NIOSSL
import Fluent
import FluentSQLiteDriver
import Vapor

// configures your application
public func configure(_ app: Application) async throws {
    setupDatabase(app)

    app.migrations.add(CreateDownload())
    
    // Apply SQLite performance pragmas after migrations
    let appEnvironment = AppEnvironment(from: app.environment)
    await applySQLitePragmas(app, environment: appEnvironment)

    // Setup authentication middleware (must be before routes)
    setupAuthentication(app, environment: appEnvironment)

    // register routes
    try routes(app)
}

private func setupDatabase(_ app: Application) {
    let appEnvironment = AppEnvironment(from: app.environment)
    
    // Configure SQLite database using the environment's configuration
    app.databases.use(.sqlite(appEnvironment.sqliteConfiguration), as: .sqlite)
    
    let dbType = appEnvironment.usesInMemoryDatabase ? "in-memory" : "file-based"
    app.logger.info("SQLite database configured: \(dbType) (\(appEnvironment))")
}

private func applySQLitePragmas(_ app: Application, environment: AppEnvironment) async {
    guard let sqliteDB = app.db(.sqlite) as? any SQLiteDatabase else {
        app.logger.warning("Failed to cast database to SQLiteDatabase, pragmas not applied")
        return
    }
    
    let pragmas = environment.sqlitePragmas
    
    for pragma in pragmas {
        do {
            try await sqliteDB.sql().raw(SQLQueryString(pragma)).run()
        } catch {
            app.logger.error("Failed to apply SQLite pragma '\(pragma)': \(error)")
        }
    }
    
    let dbType = environment.usesInMemoryDatabase ? "in-memory" : "file-based"
    app.logger.info("SQLite performance pragmas applied to \(dbType) database (\(environment)): \(pragmas.joined(separator: ", "))")
}

private func setupAuthentication(_ app: Application, environment: AppEnvironment) {
    guard let authToken = environment.authToken else {
        app.logger.warning("AUTH_TOKEN environment variable not set - some routes might be unavailable")
        return
    }
    
    // Store the auth token in application storage for selective route protection
    app.storage[AuthTokenKey.self] = authToken
    app.logger.info("Bearer authentication configured")
}

