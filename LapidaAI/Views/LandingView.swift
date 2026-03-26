import SwiftUI
import UniformTypeIdentifiers

struct LandingView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var showTextEditor = false
    @State private var heroOpacity: CGFloat = 0
    @State private var cardsOffset: CGFloat = 50
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        @Bindable var vm = viewModel
        
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xxl) {
                // MARK: - Header & Profile
                headerSection
                
                // MARK: - Hero Section
                heroSection
                
                // MARK: - Input Method Selection
                inputMethodSection
                
                // MARK: - Text Input (if selected)
                if showTextEditor {
                    textInputSection
                }
                
                // MARK: - Features Grid
                featuresGrid
                
                // MARK: - Premium CTA
                if !viewModel.userProfile.isPremium {
                    premiumCTASection
                }
                
                // MARK: - Footer
                footerSection
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.bottom, AppSpacing.xxxl)
        }
        .fileImporter(
            isPresented: $vm.isFileImporterPresented,
            allowedContentTypes: [UTType.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.handleFileImport(.success(url))
                }
            case .failure(let error):
                viewModel.handleFileImport(.failure(error))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                heroOpacity = 1
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2)) {
                cardsOffset = 0
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Spacer()
            
            Menu {
                if !viewModel.userProfile.isPremium {
                    Button {
                        viewModel.showPremiumModal = true
                    } label: {
                        Label("Torne-se Premium", systemImage: "star.fill")
                    }
                }
                
                Button(role: .destructive) {
                    viewModel.signOut()
                } label: {
                    Label("Sair da Conta", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if !viewModel.userProfile.isPremium {
                        Text("\(viewModel.userProfile.analysisCount)/3")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textTertiary)
                            .padding(.horizontal, AppSpacing.sm)
                            .padding(.vertical, 2)
                            .background(AppColors.glassBorder.opacity(0.3))
                            .clipShape(Capsule())
                    }
                    
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.textSecondary)
                        
                        if viewModel.userProfile.isPremium {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "FFD700"), Color(hex: "FFA500")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .offset(x: 8, y: -8)
                                .shadow(color: .black.opacity(0.3), radius: 2)
                        }
                    }
                    .padding(AppSpacing.xs)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                }
            }
        }
        .padding(.top, AppSpacing.md)
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer().frame(height: AppSpacing.xxl)
            
            // App Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .blur(radius: 10)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.primaryLight, AppColors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: AppColors.primary.opacity(0.4), radius: 10)
            }
            
            // Title
            VStack(spacing: AppSpacing.sm) {
                Text("LapidaAI")
                    .font(AppTypography.largeTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.textPrimary, AppColors.primaryLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Analisador de Currículos com IA")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)
            }
            
            // Subtitle
            Text("Descubra como os recrutadores\nveem o seu currículo.")
                .font(AppTypography.body)
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .opacity(heroOpacity)
    }
    
    // MARK: - Input Method
    private var inputMethodSection: some View {
        VStack(spacing: AppSpacing.lg) {
            // PDF Upload Button
            Button {
                viewModel.isFileImporterPresented = true
            } label: {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.primary.opacity(0.15))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.primaryLight)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Importar PDF")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Selecione o arquivo do seu currículo")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .glassCard(cornerRadius: AppRadius.xl, padding: AppSpacing.lg)
            }
            .buttonStyle(.plain)
            
            // Divider
            HStack {
                Rectangle()
                    .fill(AppColors.glassBorder)
                    .frame(height: 0.5)
                Text("ou")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
                    .padding(.horizontal, AppSpacing.md)
                Rectangle()
                    .fill(AppColors.glassBorder)
                    .frame(height: 0.5)
            }
            
            // Text Input Button
            Button {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    showTextEditor.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(AppColors.gold.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "text.cursor")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(AppColors.goldLight)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Colar Texto")
                            .font(AppTypography.headline)
                            .foregroundStyle(AppColors.textPrimary)
                        Text("Cole o conteúdo do seu currículo")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: showTextEditor ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.textTertiary)
                }
                .glassCard(cornerRadius: AppRadius.xl, padding: AppSpacing.lg)
            }
            .buttonStyle(.plain)
        }
        .offset(y: cardsOffset)
    }
    
    // MARK: - Text Input Section
    private var textInputSection: some View {
        @Bindable var vm = viewModel
        
        return VStack(spacing: AppSpacing.lg) {
            // Text editor
            ZStack(alignment: .topLeading) {
                if viewModel.inputText.isEmpty {
                    Text("Cole aqui o texto do seu currículo...\n\nExemplo:\nJoão Silva — Desenvolvedor Full Stack\n3 anos de experiência em React e Node.js...")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textTertiary.opacity(0.5))
                        .padding(.top, 8)
                        .padding(.leading, 4)
                }
                
                TextEditor(text: $vm.inputText)
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textPrimary)
                    .scrollContentBackground(.hidden)
                    .focused($isTextEditorFocused)
                    .frame(minHeight: 200, maxHeight: 300)
            }
            .glassCard(cornerRadius: AppRadius.lg, padding: AppSpacing.md)
            
            // Character count & Analyze button
            HStack {
                Text("\(viewModel.inputText.count) caracteres")
                    .font(AppTypography.captionSmall)
                    .foregroundStyle(AppColors.textTertiary)
                
                Spacer()
                
                Button {
                    isTextEditorFocused = false
                    viewModel.startAnalysis()
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .bold))
                        Text("Analisar")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
                .buttonStyle(GlassButtonStyle(isProminent: true))
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Features Grid
    private var featuresGrid: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Como funciona")
                .font(AppTypography.title3)
                .foregroundStyle(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppSpacing.md),
                GridItem(.flexible(), spacing: AppSpacing.md)
            ], spacing: AppSpacing.md) {
                FeatureCard(
                    icon: "cpu",
                    title: "Análise ATS",
                    description: "Verificamos a compatibilidade com robôs de triagem.",
                    color: AppColors.primary
                )
                
                FeatureCard(
                    icon: "chart.bar.fill",
                    title: "Pontuação",
                    description: "Score detalhado em múltiplas dimensões.",
                    color: AppColors.success
                )
                
                FeatureCard(
                    icon: "lightbulb.fill",
                    title: "Sugestões IA",
                    description: "Recomendações personalizadas de melhoria.",
                    color: AppColors.warning
                )
                
                FeatureCard(
                    icon: "star.fill",
                    title: "Premium",
                    description: "Plano de ação exclusivo gerado por IA.",
                    color: AppColors.gold
                )
            }
        }
        .offset(y: cardsOffset * 0.5)
    }
    
    // MARK: - Premium CTA Section
    private var premiumCTASection: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.gold.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.gold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("LapidaAI Premium")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Análises ilimitadas e plano de ação")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                
                Spacer()
            }
            
            Button {
                viewModel.showPremiumModal = true
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text("Assinar Premium — R$ 9,90")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(AppColors.background)
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PremiumButtonStyle())
        }
        .glassCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl)
                .stroke(
                    LinearGradient(
                        colors: [AppColors.gold.opacity(0.4), AppColors.gold.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .offset(y: cardsOffset * 0.3)
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                Text("Seus dados são processados com segurança")
            }
            .font(AppTypography.captionSmall)
            .foregroundStyle(AppColors.textTertiary)
            
            Text("Powered by AI · v1.0")
                .font(AppTypography.captionSmall)
                .foregroundStyle(AppColors.textTertiary.opacity(0.5))
        }
        .padding(.top, AppSpacing.lg)
    }
}

// MARK: - Feature Card Component
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: AppRadius.sm)
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(AppTypography.caption)
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)
            
            Text(description)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(AppColors.textTertiary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard(cornerRadius: AppRadius.lg, padding: AppSpacing.md)
    }
}

#Preview {
    ZStack {
        AnimatedMeshBackground()
            .ignoresSafeArea()
        LandingView()
    }
    .environment(AppViewModel())
}
