import SwiftData
import Foundation
import Lightcom_Swift
import Crypto
import LibCrypto

@Model
class EncryptedMessageModel: Identifiable {
    @Attribute(.unique) var uuid: String
    var forChannel: String
    var fromMe: Bool
    var encryptedMessage: String
    
    init(uuid: String = UUID().uuidString, forChannel: String, fromMe: Bool, encryptedMessage: String) {
        self.uuid = uuid
        self.forChannel = forChannel
        self.fromMe = fromMe
        self.encryptedMessage = encryptedMessage
    }
    
    func decrypt(key: SymmetricKey) throws -> Message {
        let decrypted = try AesGcm.decrypt(self.encryptedMessage, key: key)
        return try JSONDecoder().decode(Message.self, from: decrypted.data(using: .utf8)!)
    }
}

extension Message: Identifiable {
    func encrypt(key: SymmetricKey) throws -> String {
        let jsoned = try String(decoding: JSONEncoder().encode(self), as: UTF8.self)
        return try AesGcm.encrypt(jsoned, key: key)
    }
}
