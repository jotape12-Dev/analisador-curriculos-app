import SwiftUI

struct RadarChartView: View {
    let dimensions: [AnalysisDimension]
    let size: CGFloat
    
    @State private var animatedScores: [CGFloat] = []
    @State private var showLabels = false
    
    private let gridLevels = 5
    
    init(dimensions: [AnalysisDimension], size: CGFloat = 280) {
        self.dimensions = dimensions
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Grid circles
            ForEach(1...gridLevels, id: \.self) { level in
                RadarGridShape(
                    sides: dimensions.count,
                    scale: CGFloat(level) / CGFloat(gridLevels)
                )
                .stroke(AppColors.glassBorder, lineWidth: 0.5)
            }
            
            // Axis lines
            ForEach(0..<dimensions.count, id: \.self) { index in
                let angle = angleFor(index: index)
                Path { path in
                    path.move(to: CGPoint(x: size / 2, y: size / 2))
                    path.addLine(to: pointOnCircle(angle: angle, radius: size / 2))
                }
                .stroke(AppColors.glassBorder, lineWidth: 0.5)
            }
            
            // Data polygon fill
            if !animatedScores.isEmpty {
                RadarDataShape(
                    scores: animatedScores,
                    sides: dimensions.count
                )
                .fill(
                    LinearGradient(
                        colors: [
                            AppColors.primary.opacity(0.25),
                            AppColors.primaryLight.opacity(0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Data polygon stroke
                RadarDataShape(
                    scores: animatedScores,
                    sides: dimensions.count
                )
                .stroke(
                    LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                
                // Data points
                ForEach(0..<dimensions.count, id: \.self) { index in
                    let score = index < animatedScores.count ? animatedScores[index] : 0
                    let angle = angleFor(index: index)
                    let point = dataPoint(angle: angle, score: score)
                    
                    Circle()
                        .fill(AppColors.primaryLight)
                        .frame(width: 8, height: 8)
                        .shadow(color: AppColors.primaryLight.opacity(0.6), radius: 4)
                        .position(point)
                }
            }
            
            // Labels
            ForEach(0..<dimensions.count, id: \.self) { index in
                let angle = angleFor(index: index)
                let labelPos = pointOnCircle(angle: angle, radius: size / 2 + 30)
                
                VStack(spacing: 2) {
                    Image(systemName: dimensions[index].icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppColors.primary)
                    
                    Text(dimensions[index].name)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(AppColors.textSecondary)
                    
                    Text("\(dimensions[index].percentage)%")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(AppColors.primaryLight)
                }
                .position(labelPos)
                .opacity(showLabels ? 1 : 0)
            }
        }
        .frame(width: size + 80, height: size + 80)
        .onAppear {
            // Initialize with zeros
            animatedScores = Array(repeating: 0, count: dimensions.count)
            
            // Animate to actual scores
            withAnimation(.spring(response: 1.2, dampingFraction: 0.7).delay(0.3)) {
                animatedScores = dimensions.map { CGFloat($0.score) }
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showLabels = true
            }
        }
    }
    
    // MARK: - Geometry Helpers
    private func angleFor(index: Int) -> CGFloat {
        let sliceAngle = (2 * .pi) / CGFloat(dimensions.count)
        return sliceAngle * CGFloat(index) - .pi / 2
    }
    
    private func pointOnCircle(angle: CGFloat, radius: CGFloat) -> CGPoint {
        let centerX = (size + 80) / 2
        let centerY = (size + 80) / 2
        return CGPoint(
            x: centerX + cos(angle) * radius,
            y: centerY + sin(angle) * radius
        )
    }
    
    private func dataPoint(angle: CGFloat, score: CGFloat) -> CGPoint {
        let radius = (size / 2) * score
        let centerX = (size + 80) / 2
        let centerY = (size + 80) / 2
        return CGPoint(
            x: centerX + cos(angle) * radius,
            y: centerY + sin(angle) * radius
        )
    }
}

// MARK: - Radar Grid Shape
struct RadarGridShape: Shape {
    let sides: Int
    let scale: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale
        
        for i in 0..<sides {
            let angle = (2 * .pi / CGFloat(sides)) * CGFloat(i) - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

// MARK: - Radar Data Shape
struct RadarDataShape: Shape {
    var scores: [CGFloat]
    let sides: Int
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get {
            AnimatablePair(
                scores.first ?? 0,
                scores.count > 1 ? scores[1] : 0
            )
        }
        set {
            // Simplified: full animation handled externally
        }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2
        
        for i in 0..<sides {
            let angle = (2 * .pi / CGFloat(sides)) * CGFloat(i) - .pi / 2
            let score = i < scores.count ? scores[i] : 0
            let radius = maxRadius * score
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        RadarChartView(dimensions: [
            AnalysisDimension(name: "ATS", score: 0.78, maxScore: 1.0, label: "ATS", icon: "cpu"),
            AnalysisDimension(name: "Design", score: 0.65, maxScore: 1.0, label: "Design", icon: "paintbrush"),
            AnalysisDimension(name: "Experiência", score: 0.82, maxScore: 1.0, label: "Exp", icon: "briefcase"),
            AnalysisDimension(name: "Habilidades", score: 0.7, maxScore: 1.0, label: "Hab", icon: "star"),
            AnalysisDimension(name: "Formação", score: 0.6, maxScore: 1.0, label: "Form", icon: "graduationcap"),
            AnalysisDimension(name: "Impacto", score: 0.45, maxScore: 1.0, label: "Impacto", icon: "chart.bar"),
        ])
    }
}
