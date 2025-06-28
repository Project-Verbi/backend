import Hummingbird
import Logging
@preconcurrency import SQLite

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable. 
/// Any variables added here also have to be added to `App` in App.swift and 
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
    var databasePath: String? { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "backend")
        logger.logLevel = 
            arguments.logLevel ??
            environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) } ??
            .info
        return logger
    }()
    
    // Initialize database service
    let databaseService: DatabaseService
    if let databasePath = arguments.databasePath {
        databaseService = try await DatabaseService(path: databasePath, logger: logger)
    } else {
        databaseService = try await DatabaseService(logger: logger)
    }
    
    let router = try await buildRouter(databaseService: databaseService)
    let app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "backend"
        ),
        logger: logger
    )
    return app
}

/// Build router
func buildRouter(databaseService: DatabaseService) async throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    
    // Initialize controllers
    let downloadController = DownloadController(databaseService: databaseService)
    
    // Add default endpoint
    router.get("/") { _,_ in
        return "Hello!"
    }
    
    // Add download tracking endpoints
    router.post("/track-download", use: downloadController.trackDownload)
    router.get("/download-stats", use: downloadController.getDownloadStats)
    
    return router
}
