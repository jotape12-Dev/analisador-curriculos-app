import SwiftUI

@main
struct LapidaAIApp: App {
    @State private var viewModel = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .preferredColorScheme(.dark)
        }
    }
}
