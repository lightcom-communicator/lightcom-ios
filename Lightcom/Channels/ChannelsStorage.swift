import Foundation
import SwiftData
import Crypto
import LibCrypto

@Model
class EncryptedChannelModel: Identifiable {
    @Attribute(.unique) var uuid: String
    var forInstance: String
    var encryptedContent: String
    
    init(uuid: String = UUID().uuidString, forInstance: String, encryptedContent: String) {
        self.forInstance = forInstance
        self.encryptedContent = encryptedContent
        self.uuid = uuid
    }
    
    func decrypted(key: SymmetricKey) throws -> Channel {
        let decrypted = try AesGcm.decrypt(self.encryptedContent, key: key).data(using: .utf8)!
        return try JSONDecoder().decode(Channel.self, from: decrypted)
    }
}

class Channel: Codable {
    var name: String
    var userId: String
    var publicKey: String

    init(name: String, userId: String, publicKey: String) {
        self.name = name
        self.userId = userId
        self.publicKey = publicKey
    }
    
    func encrypt(key: SymmetricKey) throws -> String {
        let jsoned = try String(decoding: JSONEncoder().encode(self), as: UTF8.self)
        let encrypted = try AesGcm.encrypt(jsoned, key: key)
        
        return encrypted
    }
}
