import SwiftUI
import SwiftData
import Crypto
import LibCrypto

struct Password: View {
    @Environment(\.modelContext) var modelContext
    @Query var passwordModel: [PasswordModel]
    @State public var password = ""
    @State public var confirmPassword = ""
    
    @State public var onSuccess: (_ key: SymmetricKey) -> ()
    
    var body: some View {
        List {
            if self.passwordModel.count == 0 {
                Section(header: Text("Set up new password")) {
                    SecureField("Password", text: self.$password)
                    SecureField("Confirm password", text: self.$confirmPassword)
                    Button("Set up") {
                        Task {
                            guard self.password == self.confirmPassword else { return }
                            guard let (passwordHash, salt) = try? PasswordModel.hash(password: self.password) else { return }
                            
                            self.modelContext.insert(
                                try PasswordModel(passwordHash: passwordHash, salt: salt)
                            )
                        }
                    }
                }
            } else {
                SecureField("Password", text: self.$password)
                Button("Log in") {
                    Task {
                        guard let key = self.passwordModel[0].verify(password: self.password) else { return }
                        self.onSuccess(try X25519.computeSharedSecret(ourPrivate: key,
                                                                      theirPublic: X25519.fromPrivateKey(privateKey: key).publicKey))
                    }
                }
            }
        }
    }
}
