import SwiftUI

struct AnalysisLoadingView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var ringRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var innerRingProgress: CGFloat = 0
    @State private var particleOpacity: CGFloat = 0
    
    var body: some View {
        VStack(spacing: AppSpacing.xxxl) {
            Spacer()
            
            // MARK: - Animated Ring
            ZStack {
                // Outer rotating ring
                Circle()
                    .stroke(
                        AngularGradient(
                            colors: [
                                AppColors.primary.opacity(0),
                                AppColors.primary.opacity(0.1),
                                AppColors.primaryLight.opacity(0.6),
                                AppColors.primary.opacity(0.1),
                                AppColors.primary.opacity(0)
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(ringRotation))
                
                // Middle progress ring
                Circle()
                    .trim(from: 0, to: viewModel.loadingProgress)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 130, height: 130)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: viewModel.loadingProgress)
                
                // Inner pulse
                Circle()
                    .fill(AppColors.primary.opacity(0.08))
                    .frame(width: 100, height: 100)
                    .scaleEffect(pulseScale)
                
                // Center icon
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: AppColors.primary.opacity(0.5), radius: 10)
                
                // Floating particles
                FloatingParticlesView(count: 6, color: AppColors.primary.opacity(0.4))
                    .frame(width: 200, height: 200)
                    .opacity(particleOpacity)
            }
            
            // MARK: - Loading Text
            VStack(spacing: AppSpacing.lg) {
                Text(viewModel.loadingMessage)
                    .font(AppTypography.headline)
                    .foregroundStyle(AppColors.textPrimary)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.loadingMessage)
                    .id(viewModel.loadingMessage) // Force view refresh for animation
                    .transition(.push(from: .bottom))
                
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: AppRadius.full)
                            .fill(AppColors.surfaceLight.opacity(0.5))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: AppRadius.full)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * viewModel.loadingProgress, height: 4)
                            .animation(.easeInOut(duration: 0.8), value: viewModel.loadingProgress)
                        
                        // Glow dot at progress tip
                        Circle()
                            .fill(AppColors.primaryLight)
                            .frame(width: 8, height: 8)
                            .shadow(color: AppColors.primaryLight.opacity(0.8), radius: 6)
                            .offset(x: geo.size.width * viewModel.loadingProgress - 4)
                            .animation(.easeInOut(duration: 0.8), value: viewModel.loadingProgress)
                    }
                }
                .frame(height: 8)
                .padding(.horizontal, AppSpacing.xxxl)
                
                Text("\(Int(viewModel.loadingProgress * 100))%")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .monospacedDigit()
            }
            
            Spacer()
            
            // Bottom hint
            VStack(spacing: AppSpacing.sm) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(AppColors.gold.opacity(0.6))
                
                Text("Nossa IA está analisando cada\ndetalhe do seu currículo")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, AppSpacing.xxxl)
        }
        .padding(.horizontal, AppSpacing.xl)
        .onAppear {
            // Ring rotation
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                ringRotation = 360
            }
            
            // Pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
            
            // Particles fade in
            withAnimation(.easeIn(duration: 1).delay(0.5)) {
                particleOpacity = 1
            }
        }
    }
}

#Preview {
    ZStack {
        AnimatedMeshBackground().ignoresSafeArea()
        AnalysisLoadingView()
    }
    .environment({
        let vm = AppViewModel()
        vm.loadingProgress = 0.6
        vm.loadingMessage = "Consultando Inteligência Artificial..."
        return vm
    }())
}
