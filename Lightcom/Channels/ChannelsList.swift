import SwiftUI
import SwiftData
import Lightcom_Swift
import Crypto
import WebsocketClient

struct ChannelsList: View {
    @Environment(\.modelContext) var modelContext
    @Query var encryptedChannels: [EncryptedChannelModel]
    
    var key: SymmetricKey
    var instance: Instance
    var instanceUuid: String
    @State var client: LightcomClient?
    @State var websocket: Websocket?
    
    @State var newChannel = false
    @State var newMessages: [String: Int] = [:]
    
    var body: some View {
        NavigationView {
            if let client = client {
                List {
                    Section(header: Text("Your data")) {
                        Button("Copy user ID") { UIPasteboard.general.string = client.userId }
                        Button("Copy public key") { UIPasteboard.general.string = client.publicKeyEncoded }
                    }
                    
                    ForEach(self.encryptedChannels) { encryptedChannel in
                        if encryptedChannel.forInstance == self.instanceUuid, let channel = try? encryptedChannel.decrypted(key: self.key) {
                            NavigationLink(destination: ChannelView(
                                newMessages: self.$newMessages,
                                key: self.key,
                                channel: channel,
                                channelUuid: encryptedChannel.uuid,
                                client: client)
                            ) {
                                HStack {
                                    Text(channel.name)
                                    Spacer()
                                    if let newMessagesHere = newMessages[channel.userId], newMessagesHere != 0 {
                                        Text(String(newMessagesHere))
                                    }
                                }
                            }
                        }
                    }
                    
                    .onDelete {
                        for index in $0 {
                            modelContext.delete(self.encryptedChannels[index])
                        }
                    }
                }
                
                .navigationTitle(self.instance.name)
                .toolbar {
                    Button(action: {
                        Task {
                            self.newChannel = true
                        }
                    }, label: {
                        Image(systemName: "plus")
                    })
                }
            }
        }
        
        .onAppear {
            Task {
                self.client = try await self.instance.open()
                self.websocket = try await self.client!.newMessagesWS { new in
                    for (key, value) in new {
                        self.newMessages.updateValue(self.newMessages[key] ?? 0 + value, forKey: key)
                    }
                }
            }
        }
        
        .onDisappear {
            self.websocket?.close()
        }
        
        .sheet(isPresented: self.$newChannel) {
            NewChannel(forInstance: self.instanceUuid, key: self.key) { encryptedChannel in
                modelContext.insert(encryptedChannel)
                self.newChannel = false
            }
        }
    }
}
