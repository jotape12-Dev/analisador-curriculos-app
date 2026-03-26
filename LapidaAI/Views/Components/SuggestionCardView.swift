import SwiftUI

struct SuggestionCardView: View {
    let suggestion: Suggestion
    let isPremiumUser: Bool
    let onPremiumTap: () -> Void
    
    @State private var isExpanded = false
    
    private var priorityColor: Color {
        Color(hex: suggestion.priority.color)
    }
    
    private var isLocked: Bool {
        suggestion.isPremium && !isPremiumUser
    }
    
    var body: some View {
        Button {
            if isLocked {
                onPremiumTap()
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }
        } label: {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Header row
                HStack(spacing: AppSpacing.md) {
                    // Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: AppRadius.sm)
                            .fill(
                                isLocked
                                    ? AppColors.gold.opacity(0.12)
                                    : priorityColor.opacity(0.12)
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: isLocked ? "lock.fill" : suggestion.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(
                                isLocked ? AppColors.gold : priorityColor
                            )
                    }
                    
                    // Title & category
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(AppTypography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundStyle(
                                isLocked ? AppColors.textTertiary : AppColors.textPrimary
                            )
                            .lineLimit(isExpanded ? nil : 1)
                        
                        HStack(spacing: AppSpacing.sm) {
                            // Priority badge
                            Text(suggestion.priority.label)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(priorityColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(priorityColor.opacity(0.12))
                                )
                            
                            // Category
                            Text(suggestion.category)
                                .font(AppTypography.captionSmall)
                                .foregroundStyle(AppColors.textTertiary)
                            
                            if isLocked {
                                Text("PREMIUM")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundStyle(AppColors.gold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(AppColors.gold.opacity(0.12))
                                            .overlay(
                                                Capsule()
                                                    .stroke(AppColors.gold.opacity(0.3), lineWidth: 0.5)
                                            )
                                    )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Expand indicator
                    Image(systemName: isLocked ? "sparkles" : (isExpanded ? "chevron.up" : "chevron.down"))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            isLocked ? AppColors.gold : AppColors.textTertiary
                        )
                }
                
                // Expanded description
                if isExpanded && !isLocked {
                    Text(suggestion.description)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineSpacing(4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Locked overlay text
                if isLocked {
                    Text("Desbloqueie o Premium para acessar")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.gold.opacity(0.7))
                        .italic()
                }
            }
            .glassCard(
                cornerRadius: AppRadius.lg,
                borderWidth: isLocked ? 0.8 : 0.5,
                padding: AppSpacing.md
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(
                        isLocked
                            ? LinearGradient(
                                colors: [AppColors.gold.opacity(0.3), AppColors.gold.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom),
                        lineWidth: isLocked ? 0.8 : 0
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        VStack(spacing: 12) {
            SuggestionCardView(
                suggestion: Suggestion(
                    title: "Adicione métricas de impacto",
                    description: "Quantifique seus resultados com números concretos.",
                    priority: .critical,
                    category: "Conteúdo",
                    icon: "chart.line.uptrend.xyaxis"
                ),
                isPremiumUser: false,
                onPremiumTap: {}
            )
            
            SuggestionCardView(
                suggestion: Suggestion(
                    title: "Plano de ação personalizado",
                    description: "Desbloqueie...",
                    priority: .high,
                    category: "Premium",
                    icon: "star.fill",
                    isPremium: true
                ),
                isPremiumUser: false,
                onPremiumTap: {}
            )
        }
        .padding()
    }
}
