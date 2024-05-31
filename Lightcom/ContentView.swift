import SwiftUI
import SwiftData
import Crypto

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State var key: SymmetricKey?
    
    var body: some View {
        if let key = self.key {
            InstancesList(key: key)
        } else {
            Password { key in
                self.key = key
            }
        }
    }
}
