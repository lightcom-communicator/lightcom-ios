import Foundation
import SwiftData
import LibCrypto
import Lightcom_Swift
import Crypto

@Model
class PasswordModel {
    var publicKey: String
    var salt: Data
    
    static func hash(password: String, salt: Salt = Salt.generate()) throws -> (String, Salt)  {
        let passwordHash = try Argon2().hashPasswordString(password: password, salt: salt)
        return (passwordHash.hexString(), salt)
    }
    
    init(passwordHash: String, salt: Salt) throws {
        self.publicKey = try X25519.fromPrivateKey(privateKey: passwordHash).publicKey
        self.salt = salt.bytes
    }
    
    func verify(password: String) -> String? {
        guard
            let (passwordHash, salt) = try? Self.hash(password: password, salt: Salt(bytes: salt)),
            let passwordModel = try? PasswordModel(passwordHash: passwordHash, salt: salt),
            passwordModel.publicKey == self.publicKey else {
            return nil
        }
        
        return passwordHash
    }
}

@Model
class EncryptedInstanceModel: Identifiable {
    @Attribute(.unique) var uuid: String
    var instanceData: String
    
    init(uuid: String = UUID().uuidString, instanceData: String) {
        self.instanceData = instanceData
        self.uuid = uuid
    }
    
    func decrypt(key: SymmetricKey) throws -> Instance {
        let decrypted = try AesGcm.decrypt(instanceData, key: key)
        return try JSONDecoder().decode(Instance.self, from: decrypted.data(using: .utf8)!)
    }
}

class Instance: Codable {
    public var name: String
    
    public var serverUrl: String
    public var userId: String
    public var privateKey: String
    public var accessToken: String?
    
    init(name: String, serverUrl: String, userId: String, privateKey: String, accessToken: String? = nil) {
        self.name = name
        self.serverUrl = serverUrl
        self.userId = userId
        self.privateKey = privateKey
        self.accessToken = accessToken
    }
    
    static func register(name: String, serverUrl: String) async throws -> (Instance, LightcomClient) {
        let client = try await LightcomClient(serverUrl: serverUrl)
        
        return (
            Instance(
                name: name,
                serverUrl: serverUrl,
                userId: client.userId,
                privateKey: client.privateKeyEncoded,
                accessToken: client.accessToken
            ),
            client
        )
    }
    
    func encrypt(key: SymmetricKey) throws -> String {
        return try AesGcm.encrypt(
            String(decoding: try JSONEncoder().encode(self), as: UTF8.self),
            key: key
        )
    }
    
    func open() async throws -> LightcomClient {
        if let accessToken = self.accessToken {
            return try LightcomClient(
                serverUrl: self.serverUrl,
                userId: self.userId,
                privateKeyEncoded: self.privateKey,
                accessToken: accessToken
            )
        } else {
            return try await LightcomClient(
                serverUrl: self.serverUrl,
                userId: self.userId,
                privateKeyEncoded: self.privateKey
            )
        }
    }
}
