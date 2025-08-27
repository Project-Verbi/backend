import FluentSQLiteDriver
import Vapor

// Custom environment enum that includes integration testing
enum AppEnvironment {
    case development
    case testing
    case integrationTesting
    case production
    
    init(from vaporEnvironment: Environment) {
        if Environment.get("INTEGRATION_TESTING") == "true" {
            self = .integrationTesting
        } else {
            switch vaporEnvironment {
            case .testing:
                self = .testing
            case .production:
                self = .production
            default:
                self = .development
            }
        }
    }
    
    var usesInMemoryDatabase: Bool {
        switch self {
        case .testing, .integrationTesting:
            return true
        case .development, .production:
            return false
        }
    }
    
    var sqliteConfiguration: SQLiteConfiguration {
        switch self {
        case .testing, .integrationTesting:
            return .memory
        case .production:
            return .file("/data/db.sqlite")
        case .development:
            return .file("db.sqlite")
        }
    }
    
    var sqlitePragmas: [String] {
        // Common pragmas for all databases
        var pragmas = [
            "PRAGMA synchronous = NORMAL",
            "PRAGMA cache_size = 1000", 
            "PRAGMA temp_store = MEMORY"
        ]
        
        // File-based database specific pragmas
        switch self {
        case .development, .production:
            pragmas.append("PRAGMA journal_mode = WAL")
            pragmas.append("PRAGMA mmap_size = 268435456")
        case .testing, .integrationTesting:
            // In-memory databases don't support WAL mode or mmap
            break
        }
        
        return pragmas
    }
}
