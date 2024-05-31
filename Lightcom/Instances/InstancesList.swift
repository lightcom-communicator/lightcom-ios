import SwiftUI
import SwiftData
import Crypto

struct InstancesList: View {
    @State var key: SymmetricKey
    
    @Environment(\.modelContext) var modelContext
    @Query var encryptedInstances: [EncryptedInstanceModel]
    @Query var encryptedChannels: [EncryptedChannelModel]
    
    @State var new = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.encryptedInstances) { encryptedInstance in
                    if let instance = try? encryptedInstance.decrypt(key: self.key) {
                        NavigationLink(destination: ChannelsList(key: self.key, instance: instance, instanceUuid: encryptedInstance.uuid)) {
                            Text(instance.name)
                        }
                    }
                }
                .onDelete {
                    for index in $0 {
                        let id = self.encryptedInstances[index].uuid
                        if let chs = try? modelContext.fetch(FetchDescriptor<EncryptedChannelModel>(predicate: #Predicate { $0.forInstance == id })) {
                            for ch in chs {
                                let id2 = ch.uuid
                                if let msgs = try? modelContext.fetch(FetchDescriptor<EncryptedMessageModel>(predicate: #Predicate { $0.forChannel == id2 })) {
                                    msgs.forEach {
                                        modelContext.delete($0)
                                    }
                                }
                                modelContext.delete(ch)
                            }
                        }
                        
                        modelContext.delete(self.encryptedInstances[index])
                    }
                }
            }
            
            .navigationTitle("Instances")
            .toolbar {
                Button(action: {
                    Task { self.new = true }
                }, label: {
                    Image(systemName: "plus")
                })
            }
        }
        
        .sheet(isPresented: self.$new) {
            NewInstance(key: self.key) { encryptedInstance in
                modelContext.insert(encryptedInstance)
                self.new = false
            }
        }
    }
}
