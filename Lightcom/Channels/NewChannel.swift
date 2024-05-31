import SwiftUI
import SwiftData
import Crypto

struct NewChannel: View {
    var forInstance: String
    var key: SymmetricKey
    var onCompletion: (_ encryptedChannel: EncryptedChannelModel) -> ()
    
    @State var name = ""
    @State var userId = ""
    @State var publicKey = ""
    
    var body: some View {
        List {
            TextField("Name", text: self.$name)
            TextField("User ID", text: self.$userId)
            TextField("Public key", text: self.$publicKey)
            Button("Add") {
                Task {
                    let channel = Channel(name: self.name, userId: self.userId, publicKey: self.publicKey)
                    
                    self.onCompletion(
                        EncryptedChannelModel(
                            forInstance: self.forInstance,
                            encryptedContent: try channel.encrypt(key: self.key)
                        )
                    )
                }
            }
        }
    }
}
