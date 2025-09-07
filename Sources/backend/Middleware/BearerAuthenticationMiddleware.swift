import Vapor

struct BearerAuthenticationMiddleware: AsyncMiddleware {
    private let expectedToken: String
    
    init(expectedToken: String) {
        self.expectedToken = expectedToken
    }
    
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        guard let bearerHeader = request.headers.bearerAuthorization else {
            throw Abort(.unauthorized, reason: "Bearer token required")
        }
        
        guard bearerHeader.token == expectedToken else {
            throw Abort(.unauthorized, reason: "Invalid bearer token")
        }
        
        return try await next.respond(to: request)
    }
}