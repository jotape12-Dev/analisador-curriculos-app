import SwiftUI

struct PremiumModalView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
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
                        if viewModel.paymentStep == .benefits {
                            benefitsContent
                        } else {
                            pixContent
                        }
                    }
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxxl * 2)
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
        }
        .onDisappear {
            viewModel.resetPaymentState()
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
            
            Text(viewModel.paymentStep == .benefits
                 ? "Eleve o seu perfil profissional com conselhos direcionados."
                 : "Escaneie o QR Code ou copie o código PIX.")
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
            
            // Price card
            VStack(spacing: AppSpacing.sm) {
                Text("PAGAMENTO ÚNICO")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(AppColors.textTertiary)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("R$")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("9,90")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.textPrimary, AppColors.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.gold)
                    Text("Liberação imediata via PIX")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .glassCard()
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.xl)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primary.opacity(0.2), AppColors.gold.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
        }
        .opacity(showContent ? 1 : 0)
    }
    
    // MARK: - PIX Step
    private var pixContent: some View {
        VStack(spacing: AppSpacing.xl) {
            if viewModel.isGeneratingPix {
                // Loading state
                VStack(spacing: AppSpacing.lg) {
                    ProgressView()
                        .tint(AppColors.primary)
                        .scaleEffect(1.5)
                    
                    Text("Gerando PIX único e seguro...")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 300)
                .glassCard()
            } else if viewModel.paymentConfirmed {
                // Success state
                VStack(spacing: AppSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(AppColors.success.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(AppColors.success)
                            .shadow(color: AppColors.success.opacity(0.5), radius: 10)
                    }
                    .pulsingGlow(color: AppColors.success, radius: 25)
                    
                    Text("Pagamento Confirmado! 🎉")
                        .font(AppTypography.title3)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Seu acesso Premium foi liberado.")
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 300)
                .glassCard()
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .stroke(AppColors.success.opacity(0.3), lineWidth: 1)
                )
                .transition(.scale.combined(with: .opacity))
            } else {
                // QR Code display
                VStack(spacing: AppSpacing.lg) {
                    // QR Code
                    VStack(spacing: AppSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: AppRadius.lg)
                                .fill(.white)
                                .frame(width: 220, height: 220)
                                .shadow(color: .white.opacity(0.1), radius: 20)
                            
                            QRCodeView(payload: viewModel.ticketUrl, size: 200)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 14, weight: .bold))
                            Text("Use o leitor de PIX no app do seu banco")
                                .font(AppTypography.captionSmall)
                                .fontWeight(.bold)
                        }
                        .foregroundStyle(AppColors.primary)
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .glassCard()
                    
                    // Copy PIX code
                    VStack(spacing: AppSpacing.md) {
                        Text("PIX COPIA E COLA")
                            .font(.system(size: 10, weight: .black))
                            .tracking(1.5)
                            .foregroundStyle(AppColors.textTertiary)
                        
                        Button {
                            viewModel.copyPixCode()
                        } label: {
                            HStack {
                                Image(systemName: viewModel.pixCopied ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 14, weight: .bold))
                                
                                Text(viewModel.pixCopied ? "Código Copiado!" : "Copiar Código PIX")
                                    .font(.system(size: 14, weight: .bold))
                                
                                Spacer()
                                
                                Text("R$ 9,90")
                                    .font(.system(size: 12, weight: .medium))
                                    .opacity(0.8)
                            }
                            .padding()
                            .background(viewModel.pixCopied ? AppColors.success.opacity(0.2) : AppColors.surfaceLight)
                            .foregroundStyle(viewModel.pixCopied ? AppColors.success : AppColors.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppRadius.md)
                                    .stroke(viewModel.pixCopied ? AppColors.success.opacity(0.5) : AppColors.glassBorder, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        
                        Text("Copie o código acima e cole na seção 'Pix Copia e Cola' do app do seu banco.")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .glassCard()
                    
                    // Status indicator
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                            .tint(AppColors.primary)
                            .scaleEffect(0.8)
                        
                        Text("Verificação automática ativa")
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
        }
    }
    
    // MARK: - Footer Buttons
    private var footerButtons: some View {
        VStack(spacing: AppSpacing.md) {
            Divider()
                .overlay(AppColors.glassBorder)
            
            HStack(spacing: AppSpacing.md) {
                Button {
                    if viewModel.paymentStep == .pix && !viewModel.paymentConfirmed {
                        withAnimation(.spring(response: 0.4)) {
                            viewModel.paymentStep = .benefits
                            viewModel.stopPaymentPolling()
                        }
                    } else {
                        dismiss()
                    }
                } label: {
                    Text(viewModel.paymentStep == .pix && !viewModel.paymentConfirmed ? "Voltar" : "Cancelar")
                        .font(AppTypography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(viewModel.isCheckingPayment || viewModel.isGeneratingPix)
                
                if viewModel.paymentStep == .benefits {
                    Button {
                        viewModel.generatePix()
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            Image(systemName: "qrcode")
                                .font(.system(size: 14, weight: .bold))
                            Text("Pagar com PIX")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .foregroundStyle(AppColors.background)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PremiumButtonStyle())
                } else if !viewModel.paymentConfirmed {
                    Button {
                        viewModel.checkPaymentManually()
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            if viewModel.isCheckingPayment {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                                Text("Liberando...")
                                    .font(.system(size: 15, weight: .bold))
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("Verificar Pagamento")
                                    .font(.system(size: 15, weight: .bold))
                            }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(GlassButtonStyle(isProminent: true))
                    .disabled(viewModel.isCheckingPayment || viewModel.isGeneratingPix)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
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
