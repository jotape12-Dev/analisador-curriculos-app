import SwiftUI

struct ResultDashboardView: View {
    @Environment(AppViewModel.self) private var viewModel
    @State private var selectedTab: ResultTab = .overview
    @State private var showScoreAnimation = false
    @State private var headerOffset: CGFloat = -30
    @State private var headerOpacity: CGFloat = 0
    
    enum ResultTab: String, CaseIterable {
        case overview = "Visão Geral"
        case suggestions = "Sugestões"
        case details = "Detalhes"
    }
    
    private var result: AnalysisResult? { viewModel.analysisResult }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {
                    // MARK: - Score Header
                    scoreHeader
                    
                    // MARK: - Tab Selector
                    tabSelector
                    
                    // MARK: - Tab Content
                    switch selectedTab {
                    case .overview:
                        overviewContent
                    case .suggestions:
                        suggestionsContent
                    case .details:
                        detailsContent
                    }
                    
                    // Premium CTA (if not premium)
                    if !viewModel.userProfile.isPremium {
                        premiumCTA
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, AppSpacing.xl)
                .padding(.top, AppSpacing.lg)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        viewModel.resetToLanding()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Nova Análise")
                                .font(AppTypography.caption)
                        }
                        .foregroundStyle(AppColors.textSecondary)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.userProfile.isPremium {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text("PREMIUM")
                                .font(.system(size: 9, weight: .black))
                        }
                        .foregroundStyle(AppColors.gold)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(AppColors.gold.opacity(0.12))
                                .overlay(Capsule().stroke(AppColors.gold.opacity(0.3), lineWidth: 0.5))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Score Header
    private var scoreHeader: some View {
        VStack(spacing: AppSpacing.lg) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(AppColors.surfaceLight.opacity(0.3), lineWidth: 10)
                    .frame(width: 140, height: 140)
                
                // Score ring
                Circle()
                    .trim(from: 0, to: showScoreAnimation ? CGFloat(result?.overallScore ?? 0) / 100 : 0)
                    .stroke(
                        AngularGradient(
                            colors: scoreGradientColors,
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                
                // Score text
                VStack(spacing: 2) {
                    Text("\(result?.overallScore ?? 0)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .contentTransition(.numericText())
                    
                    Text("de 100")
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textTertiary)
                }
            }
            .pulsingGlow(color: scoreColor, radius: 20)
            
            VStack(spacing: AppSpacing.xs) {
                Text(scoreLabel)
                    .font(AppTypography.title3)
                    .foregroundStyle(scoreColor)
                
                Text("Análise concluída com sucesso")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
        .offset(y: headerOffset)
        .opacity(headerOpacity)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                headerOffset = 0
                headerOpacity = 1
            }
            withAnimation(.spring(response: 1.5, dampingFraction: 0.8).delay(0.3)) {
                showScoreAnimation = true
            }
        }
    }
    
    private var scoreColor: Color {
        let score = result?.overallScore ?? 0
        if score >= 80 { return AppColors.success }
        if score >= 60 { return AppColors.primary }
        if score >= 40 { return AppColors.warning }
        return AppColors.danger
    }
    
    private var scoreGradientColors: [Color] {
        let score = result?.overallScore ?? 0
        if score >= 80 { return [AppColors.success, AppColors.primaryLight, AppColors.success] }
        if score >= 60 { return [AppColors.primary, AppColors.primaryLight, AppColors.primary] }
        if score >= 40 { return [AppColors.warning, AppColors.gold, AppColors.warning] }
        return [AppColors.danger, AppColors.warning, AppColors.danger]
    }
    
    private var scoreLabel: String {
        let score = result?.overallScore ?? 0
        if score >= 80 { return "Excelente! 🎉" }
        if score >= 60 { return "Bom, mas pode melhorar" }
        if score >= 40 { return "Precisa de ajustes" }
        return "Necessita atenção urgente"
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(ResultTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(AppTypography.caption)
                        .fontWeight(selectedTab == tab ? .bold : .medium)
                        .foregroundStyle(
                            selectedTab == tab ? AppColors.textPrimary : AppColors.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedTab == tab
                                ? RoundedRectangle(cornerRadius: AppRadius.sm)
                                    .fill(AppColors.primary.opacity(0.12))
                                : nil
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .glassCard(cornerRadius: AppRadius.md, borderWidth: 0.3, padding: 0)
    }
    
    // MARK: - Overview Content
    private var overviewContent: some View {
        VStack(spacing: AppSpacing.xl) {
            // Radar Chart
            if let dims = result?.dimensions, !dims.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Text("Desempenho por Área")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    RadarChartView(dimensions: dims, size: 240)
                        .frame(maxWidth: .infinity)
                        .glassCard(cornerRadius: AppRadius.xl, padding: AppSpacing.lg)
                }
            }
            
            // Dimension bars
            if let dims = result?.dimensions {
                VStack(spacing: AppSpacing.md) {
                    Text("Scores Individuais")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ForEach(dims) { dim in
                        DimensionBarView(dimension: dim)
                    }
                }
            }
        }
    }
    
    // MARK: - Suggestions Content
    private var suggestionsContent: some View {
        VStack(spacing: AppSpacing.md) {
            if let suggestions = result?.suggestions {
                // Free suggestions
                let freeSuggestions = suggestions.filter { !$0.isPremium }
                let premiumSuggestions = suggestions.filter { $0.isPremium }
                
                ForEach(freeSuggestions) { suggestion in
                    SuggestionCardView(
                        suggestion: suggestion,
                        isPremiumUser: viewModel.userProfile.isPremium,
                        onPremiumTap: { viewModel.showPremiumModal = true }
                    )
                }
                
                if !premiumSuggestions.isEmpty {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.gold)
                        Text("Conteúdo Premium")
                            .font(AppTypography.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(AppColors.gold)
                        
                        Rectangle()
                            .fill(AppColors.gold.opacity(0.2))
                            .frame(height: 0.5)
                    }
                    .padding(.top, AppSpacing.sm)
                    
                    ForEach(premiumSuggestions) { suggestion in
                        SuggestionCardView(
                            suggestion: suggestion,
                            isPremiumUser: viewModel.userProfile.isPremium,
                            onPremiumTap: { viewModel.showPremiumModal = true }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Details Content
    private var detailsContent: some View {
        VStack(spacing: AppSpacing.lg) {
            // Metadata card
            if let meta = result?.metadata {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Detalhes da Análise")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    DetailRow(icon: "calendar", label: "Analisado em", value: meta.analyzedAt.formatted(date: .abbreviated, time: .shortened))
                    DetailRow(icon: "doc.text", label: "Tipo de entrada", value: meta.inputType == .pdf ? "PDF" : "Texto")
                    DetailRow(icon: "textformat.123", label: "Total de palavras", value: "\(meta.wordCount)")
                    DetailRow(icon: "list.bullet", label: "Seções encontradas", value: "\(meta.sectionsFound.count)")
                    
                    // Sections list
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        ForEach(meta.sectionsFound, id: \.self) { section in
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.success)
                                Text(section)
                                    .font(AppTypography.bodyMedium)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                        }
                    }
                    .padding(.top, AppSpacing.xs)
                }
                .glassCard()
            }
            
            // Action Plan (Premium)
            if let plan = result?.actionPlan, viewModel.userProfile.isPremium {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundStyle(AppColors.gold)
                        Text("Plano de Ação")
                            .font(AppTypography.title3)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    
                    Text(plan.summary)
                        .font(AppTypography.bodyMedium)
                        .foregroundStyle(AppColors.textSecondary)
                        .lineSpacing(4)
                    
                    ForEach(plan.steps) { step in
                        HStack(alignment: .top, spacing: AppSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.primary.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Text("\(step.order)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppColors.primaryLight)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title)
                                    .font(AppTypography.bodyMedium)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppColors.textPrimary)
                                
                                Text(step.description)
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineSpacing(3)
                                
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 9, weight: .bold))
                                    Text(step.estimatedImpact)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundStyle(AppColors.success)
                                .padding(.top, 2)
                            }
                        }
                    }
                    
                    // Insights
                    if !plan.insights.isEmpty {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("💡 Insights")
                                .font(AppTypography.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(AppColors.gold)
                            
                            ForEach(plan.insights, id: \.self) { insight in
                                Text("• \(insight)")
                                    .font(AppTypography.caption)
                                    .foregroundStyle(AppColors.textSecondary)
                                    .lineSpacing(3)
                            }
                        }
                        .padding(.top, AppSpacing.sm)
                    }
                }
                .glassCard()
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.xl)
                        .stroke(
                            LinearGradient(
                                colors: [AppColors.gold.opacity(0.3), AppColors.gold.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
            }
        }
    }
    
    // MARK: - Premium CTA
    private var premiumCTA: some View {
        VStack(spacing: AppSpacing.lg) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: "star.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AppColors.gold)
                    .shadow(color: AppColors.gold.opacity(0.5), radius: 8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Desbloqueie o Premium")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)
                    
                    Text("Plano de ação exclusivo + sugestões ilimitadas")
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
                    Text("Acessar Premium — R$ 9,90")
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
        .padding(.top, AppSpacing.md)
    }
}

// MARK: - Dimension Bar
struct DimensionBarView: View {
    let dimension: AnalysisDimension
    @State private var animatedWidth: CGFloat = 0
    
    private var barColor: Color {
        if dimension.score >= 0.8 { return AppColors.success }
        if dimension.score >= 0.6 { return AppColors.primary }
        if dimension.score >= 0.4 { return AppColors.warning }
        return AppColors.danger
    }
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: dimension.icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(barColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(dimension.name)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Spacer()
                    Text("\(dimension.percentage)%")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(barColor)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.surfaceLight.opacity(0.5))
                            .frame(height: 6)
                        
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [barColor, barColor.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedWidth, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.2)) {
                animatedWidth = CGFloat(dimension.score)
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.primary)
                .frame(width: 20)
            
            Text(label)
                .font(AppTypography.bodyMedium)
                .foregroundStyle(AppColors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AppTypography.bodyMedium)
                .fontWeight(.medium)
                .foregroundStyle(AppColors.textPrimary)
        }
    }
}

#Preview {
    let vm = AppViewModel()
    vm.loadDemoData()
    return ZStack {
        AnimatedMeshBackground().ignoresSafeArea()
        ResultDashboardView()
    }
    .environment(vm)
}
