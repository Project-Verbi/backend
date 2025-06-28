import Hummingbird
import HummingbirdTesting
import Logging
import Testing

@testable import App

struct TestArguments: AppArguments {
    let hostname = "127.0.0.1"
    let port = 0
    let logLevel: Logger.Level? = .trace
    let databasePath: String? = ":memory:"
}

@Suite("App Tests")
struct AppTests {
    @Test("Basic app functionality")
    func app() async throws {
        let args = TestArguments()
        let app = try await buildApplication(args)
        try await app.test(.router) { client in
            try await client.execute(uri: "/", method: .get) { response in
                #expect(response.body == ByteBuffer(string: "Hello!"))
            }
        }
    }
}
