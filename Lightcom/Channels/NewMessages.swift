import Foundation
import WebsocketClient
import Lightcom_Swift

class NewMessages: ObservableObject {
    @Published public var websocket: Websocket?
    @Published public var newMessages: [String: Int]
    
    init(client: LightcomClient) async throws {
        self.newMessages = [:]
        self.websocket = try await client.newMessagesWS { messages in
            for (key, val) in messages {
                self.newMessages.updateValue(self.newMessages[key] ?? 0 + val, forKey: key)
            }
        }
    }
}
