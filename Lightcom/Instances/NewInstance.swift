import SwiftUI
import Crypto

struct NewInstance: View {    
    @State var key: SymmetricKey
    @State var onCompletion: (_ encryptedInstance: EncryptedInstanceModel) -> ()
    
    @State var name = ""
    @State var serverUrl = ""
    @State var register = true
    
    @State var userId = ""
    @State var privateKey = ""
    
    var body: some View {
        List {
            TextField("Instance name", text: self.$name)
            TextField("Server URL", text: self.$serverUrl)
                .autocorrectionDisabled()
                .autocapitalization(.none)
            
            Picker(selection: self.$register, label: Text("")) {
                Text("Register a new account").tag(true)
                Text("Use an existing account").tag(false)
            }
            
            if !self.register {
                TextField("User ID", text: self.$userId)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                TextField("Private key", text: self.$privateKey)
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
            }
            
            Button("Confirm") {
                Task {
                    let instance: Instance
                    if self.register {
                        (instance, _) = try await Instance.register(name: self.name, serverUrl: self.serverUrl)
                    } else {
                        instance = Instance(
                            name: self.name,
                            serverUrl: self.serverUrl,
                            userId: self.userId,
                            privateKey: self.privateKey
                        )
                        
                        instance.accessToken = try await instance.open().accessToken
                    }
                    
                    self.onCompletion(try EncryptedInstanceModel(
                        instanceData: instance.encrypt(key: self.key)
                    ))
                }
            }
        }
    }
}
