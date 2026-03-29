import SwiftUI

struct PremiumModalView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    // StoreService is @Observable, but we need to reference it as a @State 
    // to ensure this view observes its updates properly.
    @State private var storeService = StoreService.shared
    
    @State private var benefitAnimations: [Bool] = Array(repeating: false, count: 4)
    @State private var showContent = false
    
    private let benefits = [
        (icon: "text.document.fill", text: "Acesso total ao Plano de Ação exclusivo escrito pela Inteligência Artificial."),
        (icon: "text.badge.checkmark", text: "Sugestões textuais práticas para melhorar o seu currículo e suas chances."),
        (icon: "cpu", text: "Entenda quais seções críticas os robôs (ATS) não conseguiram analisar."),
        (icon: "infinity", text: "Análises ilimitadas — sem restrição de uso."),
    ]
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background.opacity(0.95)
                .ignoresSafeArea()
            
            // Ambient glow
            Circle()
                .fill(AppColors.gold.opacity(0.06))
                .frame(width: 300, height: 300)
                .blur(radius: 100)
                .offset(y: -100)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                headerSection
                
                // MARK: - Content
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        benefitsContent
                        
                        // Price card
                        VStack(spacing: AppSpacing.sm) {
                            Text("ACESSO VITALÍCIO")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .tracking(2)
                                .foregroundStyle(AppColors.textTertiary)
                            
                            if storeService.isLoadingProducts && storeService.products.isEmpty {
                                ProgressView()
                                    .tint(AppColors.gold)
                                    .padding(.vertical, AppSpacing.md)
                            } else if let product = storeService.premiumProduct {
                                Text(product.displayPrice)
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [AppColors.textPrimary, AppColors.gold],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            } else {
                                Text("R$ 9,90") // Fallback
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                    .opacity(0.5)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .glassCard()
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxxl)
                }
                
                // MARK: - Footer Buttons
                footerButtons
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            animateBenefits()
            
            // Garante que os produtos sejam carregados ao abrir o modal
            Task {
                await storeService.fetchProducts()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: AppSpacing.sm) {
            // Star icon
            ZStack {
                Circle()
                    .fill(AppColors.gold.opacity(0.15))
                    .frame(width: 60, height: 60)
                    .pulsingGlow(color: AppColors.gold, radius: 20)
                
                Image(systemName: "star.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.goldLight, AppColors.gold],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: AppColors.gold.opacity(0.5), radius: 8)
            }
            .padding(.top, AppSpacing.xl)
            
            Text("LapidaAI Premium")
                .font(AppTypography.title)
                .foregroundStyle(AppColors.textPrimary)
            
            Text("Eleve o seu perfil profissional com conselhos direcionados.")
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
    }
    
    // MARK: - Benefits Step
    private var benefitsContent: some View {
        VStack(spacing: AppSpacing.xl) {
            // Benefits list
            VStack(spacing: AppSpacing.md) {
                ForEach(Array(benefits.enumerated()), id: \.offset) { index, benefit in
                    HStack(alignment: .top, spacing: AppSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.success.opacity(0.12))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppColors.success)
                        }
                        
                        Text(benefit.text)
                            .font(AppTypography.bodyMedium)
                            .foregroundStyle(AppColors.textPrimary.opacity(0.9))
                            .lineSpacing(4)
                        
                        Spacer()
                    }
                    .opacity(benefitAnimations.indices.contains(index) && benefitAnimations[index] ? 1 : 0)
                    .offset(x: benefitAnimations.indices.contains(index) && benefitAnimations[index] ? 0 : -20)
                }
            }
            .glassCard()
        }
        .opacity(showContent ? 1 : 0)
    }
    
    // MARK: - Footer Buttons
    private var footerButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                viewModel.purchasePremium()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    if viewModel.isPurchasing {
                        ProgressView()
                            .tint(AppColors.background)
                        Text("Processando...")
                    } else if storeService.isLoadingProducts && storeService.products.isEmpty {
                        ProgressView()
                            .tint(AppColors.background)
                        Text("Buscando Preço...")
                    } else {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 14, weight: .bold))
                        Text("Assinar Premium Agora")
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(AppColors.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AppSpacing.lg)
                .background(
                    LinearGradient(
                        colors: [AppColors.goldLight, AppColors.gold],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg))
                .shadow(color: AppColors.gold.opacity(0.3), radius: 10)
            }
            .padding(.horizontal, AppSpacing.xl)
            
            HStack(spacing: AppSpacing.xl) {
                Button {
                    Task { await storeService.updatePurchasedProducts() }
                } label: {
                    Text("Restaurar Compras")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
                
                Button {
                    dismiss()
                } label: {
                    Text("Agora não")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .background(.ultraThinMaterial.opacity(0.8))
    }
    
    // MARK: - Animations
    private func animateBenefits() {
        for index in benefits.indices {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.12 + 0.3)) {
                if benefitAnimations.indices.contains(index) {
                    benefitAnimations[index] = true
                }
            }
        }
    }
}
