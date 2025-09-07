import Fluent
import Vapor

func routes(_ app: Application) throws {
    let downloadController = DownloadController()
    
    // Public routes (no authentication required)
    let publicRoutes = app.grouped("downloads")
    publicRoutes.post("track", use: downloadController.track)
    
    // Protected routes (authentication required)
    if let authToken = app.storage[AuthTokenKey.self] {
        let protectedRoutes = app.grouped(BearerAuthenticationMiddleware(expectedToken: authToken))
        let adminRoutes = protectedRoutes.grouped("admin")
        adminRoutes.get("downloads", "count", use: downloadController.getTotalCount)
    }
}

