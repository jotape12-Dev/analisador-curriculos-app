import SwiftUI

// MARK: - Animated Background
struct AnimatedMeshBackground: View {
    @State private var phase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base dark
            AppColors.background
                .ignoresSafeArea()
            
            // Animated gradient orbs
            GeometryReader { geo in
                // Primary orb (top-right)
                Circle()
                    .fill(AppColors.primary.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(
                        x: geo.size.width * 0.3 + CGFloat(sin(Double(phase * 0.7))) * 30,
                        y: -50 + CGFloat(cos(Double(phase * 0.5))) * 20
                    )
                
                // Gold orb (bottom-left)
                Circle()
                    .fill(AppColors.gold.opacity(0.04))
                    .frame(width: 250, height: 250)
                    .blur(radius: 70)
                    .offset(
                        x: -80 + CGFloat(cos(Double(phase * 0.6))) * 20,
                        y: geo.size.height * 0.6 + CGFloat(sin(Double(phase * 0.8))) * 25
                    )
                
                // Secondary orb (center)
                Circle()
                    .fill(AppColors.primaryLight.opacity(0.03))
                    .frame(width: 200, height: 200)
                    .blur(radius: 60)
                    .offset(
                        x: geo.size.width * 0.4 + CGFloat(cos(Double(phase))) * 15,
                        y: geo.size.height * 0.35 + CGFloat(sin(Double(phase * 0.9))) * 15
                    )
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                phase = .pi * 2
            }
        }
    }
}

// MARK: - Animated Ring
struct AnimatedRingView: View {
    let progress: CGFloat
    let lineWidth: CGFloat
    let gradient: [Color]
    
    @State private var animatedProgress: CGFloat = 0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Track
            Circle()
                .stroke(AppColors.surfaceLight.opacity(0.5), lineWidth: lineWidth)
            
            // Progress
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: gradient + [gradient.first ?? .clear],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Glow dot at end
            Circle()
                .fill(gradient.last ?? .clear)
                .frame(width: lineWidth * 1.6, height: lineWidth * 1.6)
                .shadow(color: (gradient.last ?? .clear).opacity(0.6), radius: 8)
                .offset(y: -((UIScreen.main.bounds.width * 0.3) / 2))  // approximate radius
                .rotationEffect(.degrees(Double(animatedProgress) * 360 - 90))
                .opacity(animatedProgress > 0.02 ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8)) {
                animatedProgress = progress
            }
        }
    }
}

// MARK: - Typing Text Animation
struct TypingTextView: View {
    let messages: [String]
    let interval: TimeInterval
    
    @State private var currentIndex = 0
    @State private var displayedText = ""
    @State private var opacity: CGFloat = 1
    
    var body: some View {
        Text(displayedText)
            .font(AppTypography.bodyMedium)
            .foregroundStyle(AppColors.textSecondary)
            .opacity(opacity)
            .onAppear {
                startCycle()
            }
    }
    
    private func startCycle() {
        guard !messages.isEmpty else { return }
        displayedText = messages[currentIndex]
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            withAnimation(.easeInOut(duration: 0.3)) {
                opacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                currentIndex = (currentIndex + 1) % messages.count
                displayedText = messages[currentIndex]
                withAnimation(.easeInOut(duration: 0.3)) {
                    opacity = 1
                }
            }
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.08),
                        .clear
                    ],
                    startPoint: .init(x: phase - 0.5, y: phase - 0.5),
                    endPoint: .init(x: phase + 0.5, y: phase + 0.5)
                )
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Floating Particles
struct FloatingParticlesView: View {
    let count: Int
    let color: Color
    
    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { index in
                ParticleView(
                    color: color,
                    size: CGFloat.random(in: 2...5),
                    containerSize: geo.size,
                    delay: Double(index) * 0.3
                )
            }
        }
    }
}

private struct ParticleView: View {
    let color: Color
    let size: CGFloat
    let containerSize: CGSize
    let delay: Double
    
    @State private var position: CGPoint = .zero
    @State private var opacity: Double = 0
    
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: size, height: size)
            .blur(radius: 1)
            .position(position)
            .opacity(opacity)
            .onAppear {
                position = CGPoint(
                    x: CGFloat.random(in: 0...containerSize.width),
                    y: CGFloat.random(in: 0...containerSize.height)
                )
                
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeInOut(duration: Double.random(in: 3...6)).repeatForever(autoreverses: true)) {
                        position = CGPoint(
                            x: CGFloat.random(in: 0...containerSize.width),
                            y: CGFloat.random(in: 0...containerSize.height)
                        )
                        opacity = Double.random(in: 0.2...0.6)
                    }
                }
            }
    }
}
