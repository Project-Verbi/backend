# backend

💧 A project built with the Vapor web framework.

## Prerequisites

1. **Environment Configuration**: Create a `.env` file in the project root with the required authentication token:
   ```bash
   cp .env.example .env
   ```
   Then edit `.env` and set your `AUTH_TOKEN`:
   ```
   AUTH_TOKEN=your-secret-bearer-token-here
   ```

2. **API Authentication**: 
   - **Public endpoints** (no authentication required): `POST /downloads/track`
   - **Protected endpoints** (require Bearer authentication): `GET /admin/downloads/count`

## API Usage Examples

### Swift Examples

**Track a download (public endpoint):**
```swift
import Foundation

struct DownloadRequest: Codable {
    let id: UUID
}

func trackDownload(downloadId: UUID) async throws {
    let url = URL(string: "http://localhost:8080/downloads/track")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let downloadRequest = DownloadRequest(id: downloadId)
    request.httpBody = try JSONEncoder().encode(downloadRequest)
    
    let (_, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 201 else {
        throw URLError(.badServerResponse)
    }
}
```

**Get download count (protected endpoint):**
```swift
struct CountResponse: Codable {
    let count: Int
}

func getDownloadCount(authToken: String) async throws -> Int {
    let url = URL(string: "http://localhost:8080/admin/downloads/count")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    let countResponse = try JSONDecoder().decode(CountResponse.self, from: data)
    return countResponse.count
}
```

### cURL Examples

```bash
# Public endpoint - no authentication required
curl -X POST http://localhost:8080/downloads/track \
     -H "Content-Type: application/json" \
     -d '{"id":"550e8400-e29b-41d4-a716-446655440000"}'

# Protected endpoint - requires authentication
curl -H "Authorization: Bearer your-secret-bearer-token-here" \
     -X GET http://localhost:8080/admin/downloads/count
```

## Getting Started

To build the project using the Swift Package Manager, run the following command in the terminal from the root of the project:
```bash
swift build
```

To run the project and start the server, use the following command:
```bash
swift run
```

To execute tests, use the following command:
```bash
swift test
```

### See more

- [Vapor Website](https://vapor.codes)
- [Vapor Documentation](https://docs.vapor.codes)
- [Vapor GitHub](https://github.com/vapor)
- [Vapor Community](https://github.com/vapor-community)
