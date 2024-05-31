import SwiftUI
import SwiftData
import Lightcom_Swift
import Crypto

struct ChannelView: View {
    @Environment(\.modelContext) var modelContext
    @State var fetchLimit = 10
    
    @Binding var newMessages: [String: Int]
    @State var messages: [Message] = []
    @State var fromMe: [Bool] = []
    
    var key: SymmetricKey
    var channel: Channel
    var channelUuid: String
    var client: LightcomClient
    
    @State var toBeSent = ""
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                ScrollView {
                    ForEach(Array(self.messages.enumerated()), id: \.offset) { index, message in
                        HStack {
                            if self.fromMe[index] { Spacer() }
                            
                            Text(message.content)
                                .foregroundStyle(Color.white)
                                .padding(15)
                                .background(Color.gray)
                                .cornerRadius(10)
                                .frame(
                                    maxWidth: geometry.size.width * 0.75,
                                    maxHeight: .infinity,
                                    alignment: self.fromMe[index] ? .trailing : .leading)
                                .lineLimit(nil)
                            
                            if !self.fromMe[index] { Spacer() }
                        }
                    }
                }
            }
            
            Spacer()
            HStack {
                TextField("Message", text: self.$toBeSent)
                Button("Send") {
                    Task {
                        let message = Message(content: self.toBeSent, mediaUrls: [])
                        try await self.client.sendMessageAndEncrypt(
                            forUser: self.channel.userId,
                            theirPublicKeyEncoded: self.channel.publicKey,
                            message: message
                        )
                        
                        self.fromMe.append(true)
                        self.messages.append(message)
                        modelContext.insert(
                            EncryptedMessageModel(
                                forChannel: self.channelUuid,
                                fromMe: true,
                                encryptedMessage: try message.encrypt(key: self.key)
                            )
                        )
                        
                        self.toBeSent = ""
                    }
                }
            }
            .padding()
        }
        
        .onChange(of: self.newMessages[self.channel.userId]) {
            Task {
                try await self.refetchMessages()
            }
        }
        
        .onAppear {
            Task {
                try await self.loadMessages()
            }
        }
    }
    
    func refetchMessages() async throws {
        let messages = try await self.client.fetchMessagesAndDecrypt(
            forUser: self.channel.userId,
            theirPublicKeyEncoded: self.channel.publicKey
        )
        
        for message in messages {
            self.fromMe.append(false)
            self.messages.append(message)
            
            modelContext.insert(
                EncryptedMessageModel(
                    forChannel: self.channelUuid,
                    fromMe: false,
                    encryptedMessage: try message.encrypt(key: self.key)
                )
            )
        }
        
        self.newMessages.updateValue(0, forKey: self.channel.userId)
    }
    
    func loadMessages() async throws {
        self.messages = []
        self.fromMe = []
        
        let channelUuid = self.channelUuid
        let predicate = #Predicate<EncryptedMessageModel>{ message in message.forChannel == channelUuid }
        var fetchDescriptor = FetchDescriptor<EncryptedMessageModel>(predicate: predicate)
        fetchDescriptor.fetchLimit = self.fetchLimit
        for encryptedMessage in try modelContext.fetch(fetchDescriptor) {
            let message = try encryptedMessage.decrypt(key: self.key)
            self.fromMe.append(encryptedMessage.fromMe)
            self.messages.append(message)
        }
        
        try await self.refetchMessages()
    }
}
