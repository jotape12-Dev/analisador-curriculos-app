import SwiftUI

// MARK: - Glass Card Modifier
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.xl
    var borderWidth: CGFloat = 0.5
    var padding: CGFloat = AppSpacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Base glass fill
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                    
                    // Subtle overlay
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppColors.glassFill)
                    
                    // Top shimmer highlight
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(AppGradients.cardShimmer)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(AppGradients.glassBorder, lineWidth: borderWidth)
            )
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassCard(
        cornerRadius: CGFloat = AppRadius.xl,
        borderWidth: CGFloat = 0.5,
        padding: CGFloat = AppSpacing.lg
    ) -> some View {
        modifier(GlassCardModifier(
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            padding: padding
        ))
    }
}

// MARK: - Glass Button Style
struct GlassButtonStyle: ButtonStyle {
    var isProminent: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .background(
                ZStack {
                    if isProminent {
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.primary, AppColors.primaryDark],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                        
                        RoundedRectangle(cornerRadius: AppRadius.lg)
                            .fill(AppColors.glassFill)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(
                        isProminent
                            ? LinearGradient(colors: [AppColors.primaryLight.opacity(0.5), AppColors.primary.opacity(0.2)], startPoint: .top, endPoint: .bottom)
                            : AppGradients.glassBorder,
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: isProminent ? AppColors.primary.opacity(0.3) : .black.opacity(0.15),
                radius: configuration.isPressed ? 5 : 10,
                x: 0,
                y: configuration.isPressed ? 2 : 5
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Premium Button Style (Gold Glow)
struct PremiumButtonStyle: ButtonStyle {
    @State private var glowPhase: CGFloat = 0
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, 14)
            .background(
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(AppColors.gold.opacity(0.15 + CGFloat(sin(Double(glowPhase))) * 0.08))
                        .blur(radius: 8)
                    
                    // Main fill
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.gold, AppColors.goldLight, AppColors.gold],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Shimmer
                    RoundedRectangle(cornerRadius: AppRadius.lg)
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.2),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: CGFloat(sin(Double(glowPhase * 0.5))) * 50)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.goldLight.opacity(0.6), AppColors.gold.opacity(0.2)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: AppColors.gold.opacity(0.3 + CGFloat(sin(Double(glowPhase))) * 0.1),
                radius: 15,
                x: 0,
                y: 5
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowPhase = .pi * 2
                }
            }
    }
}

// MARK: - Pulsing Glow Modifier
struct PulsingGlowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var isGlowing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isGlowing ? 0.4 : 0.15),
                radius: isGlowing ? radius : radius * 0.5,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                    isGlowing = true
                }
            }
    }
}

extension View {
    func pulsingGlow(color: Color = AppColors.primary, radius: CGFloat = 15) -> some View {
        modifier(PulsingGlowModifier(color: color, radius: radius))
    }
}
