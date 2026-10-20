import SwiftUI

struct ShortcutsTab: View {
    @ObservedObject var model: AppModel

    var body: some View {
        Form {
            Text("Global shortcuts arrive in the next task.")
        }
        .formStyle(.grouped)
    }
}
