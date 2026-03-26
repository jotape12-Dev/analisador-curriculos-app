import SwiftUI

struct ContentView: View {
    @Environment(AppViewModel.self) private var viewModel
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedMeshBackground()
                .ignoresSafeArea()
            
            // Screen content
            Group {
                if !viewModel.isAuthenticated {
                    LoginView()
                        .transition(.opacity)
                } else {
                    switch viewModel.currentScreen {
                    case .landing:
                        LandingView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                    case .loading:
                        AnalysisLoadingView()
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.9).combined(with: .opacity),
                                removal: .scale(scale: 1.1).combined(with: .opacity)
                            ))
                        
                    case .result:
                        ResultDashboardView()
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }
            .animation(.spring(response: 0.7, dampingFraction: 0.85), value: viewModel.currentScreen)
            .animation(.easeInOut, value: viewModel.isAuthenticated)
        }
        .onAppear {
            viewModel.checkSession()
        }
        .onOpenURL { url in
            if url.scheme == "lapidaai" && url.host == "auth-callback" {
                viewModel.handleAuthCallback(url: url)
            }
        }
        .alert("Erro", isPresented: Binding(
            get: { viewModel.showError },
            set: { viewModel.showError = $0 }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "Ocorreu um erro inesperado.")
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showPremiumModal },
            set: { viewModel.showPremiumModal = $0 }
        )) {
            PremiumModalView()
                .environment(viewModel)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
                .interactiveDismissDisabled(viewModel.isGeneratingPix || viewModel.isCheckingPayment)
        }
    }
}

#Preview {
    ContentView()
        .environment(AppViewModel())
}
