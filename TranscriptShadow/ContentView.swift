// @implements TECH-001
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Transcript Shadow")
                .font(.title)
            Text("Scaffold — EPIC-01")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(minWidth: 360, minHeight: 200)
    }
}

#Preview {
    ContentView()
}
