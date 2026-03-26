import SwiftUI
import Supabase

struct LoginView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var isLoggingIn = false
    
    var body: some View {
        VStack(spacing: AppSpacing.xxl) {
            Spacer()
            
            // Header
            VStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .blur(radius: 15)
                    
                    Image(systemName: "person.badge.shield.checkmark.fill")
                        .font(.custom("Icon", size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.primaryLight, AppColors.primary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("Boas-vindas ao LapidaAI")
                    .font(AppTypography.largeTitle)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(AppColors.textPrimary)
                
                Text("Faça login para desbloquear seu potencial e salvar suas análises com segurança.")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
            }
            
            Spacer()
            
            // Google Login Button
            Button {
                isLoggingIn = true
                viewModel.signInWithGoogle()
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image("google_logo") // Você precisará dos assets
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .fallbackIcon("g.circle.fill")
                    
                    Text("Continuar com Google")
                        .font(AppTypography.headline)
                }
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .glassCard(cornerRadius: AppRadius.lg)
            }
            .disabled(isLoggingIn)
            .opacity(isLoggingIn ? 0.7 : 1)
            
            // GitHub Login Button
            Button {
                isLoggingIn = true
                viewModel.signInWithGitHub()
            } label: {
                HStack(spacing: AppSpacing.md) {
                    Image(systemName: "curlybraces.square.fill")
                        .font(.system(size: 20))
                    
                    Text("Continuar com GitHub")
                        .font(AppTypography.headline)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
            }
            .disabled(isLoggingIn)
            .opacity(isLoggingIn ? 0.7 : 1)
            
            // Terms & Privacy Link
            VStack(spacing: AppSpacing.xs) {
                Text("Ao continuar, você concorda com nossos")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textTertiary)
                
                Link("Termos de Uso e Política de Privacidade", destination: URL(string: "https://west-countess-f4d.notion.site/Pol-tica-de-Privacidade-LapidaAI-32fc6b9cebbe807fb0d5e8966a22e4cc")!)
                    .font(AppTypography.captionSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.primary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, AppSpacing.xl)
            
            Spacer().frame(height: AppSpacing.lg)
        }
        .padding(AppSpacing.xl)
        .background(
            ZStack {
                AppColors.background.ignoresSafeArea()
                AnimatedMeshBackground()
            }
        )
    }
}

// Helper para ícones que podem não existir nos assets ainda
extension View {
    func fallbackIcon(_ name: String) -> some View {
        self.overlay(
            Image(systemName: name)
                .font(.system(size: 20))
                .foregroundColor(.gray)
        )
    }
}

#Preview {
    LoginView()
        .environment(AppViewModel())
}
