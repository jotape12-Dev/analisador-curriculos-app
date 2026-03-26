import SwiftUI

// MARK: - Color Palette
struct AppColors {
    // Backgrounds
    static let background = Color(hex: "09090b")        // Zinc 950
    static let surface = Color(hex: "18181b")            // Zinc 900
    static let surfaceLight = Color(hex: "27272a")       // Zinc 800
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "a1a1aa")      // Zinc 400
    static let textTertiary = Color(hex: "71717a")       // Zinc 500
    
    // Accent
    static let primary = Color(hex: "06b6d4")            // Cyan 500
    static let primaryLight = Color(hex: "22d3ee")       // Cyan 400
    static let primaryDark = Color(hex: "0891b2")        // Cyan 600
    
    // Premium
    static let gold = Color(hex: "f59e0b")               // Amber 500
    static let goldLight = Color(hex: "fbbf24")          // Amber 400
    
    // Status
    static let success = Color(hex: "22c55e")            // Green 500
    static let warning = Color(hex: "f97316")            // Orange 500
    static let danger = Color(hex: "ef4444")             // Red 500
    static let info = Color(hex: "3b82f6")               // Blue 500
    
    // Glass
    static let glassBorder = Color.white.opacity(0.08)
    static let glassFill = Color.white.opacity(0.04)
    static let glassHighlight = Color.white.opacity(0.12)
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
struct AppTypography {
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headline = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 17, weight: .regular)
    static let bodyMedium = Font.system(size: 15, weight: .medium)
    static let caption = Font.system(size: 13, weight: .medium)
    static let captionSmall = Font.system(size: 11, weight: .semibold)
    static let mono = Font.system(size: 12, weight: .regular, design: .monospaced)
}

// MARK: - Gradients
struct AppGradients {
    static let primaryGlow = LinearGradient(
        colors: [AppColors.primary.opacity(0.6), AppColors.primaryLight.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let premiumGlow = LinearGradient(
        colors: [AppColors.gold.opacity(0.6), AppColors.goldLight.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let backgroundMesh = LinearGradient(
        colors: [
            AppColors.background,
            AppColors.primary.opacity(0.05),
            AppColors.background,
            AppColors.gold.opacity(0.03),
            AppColors.background
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let glassBorder = LinearGradient(
        colors: [
            Color.white.opacity(0.15),
            Color.white.opacity(0.05),
            Color.white.opacity(0.02),
            Color.white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardShimmer = LinearGradient(
        colors: [
            Color.white.opacity(0.0),
            Color.white.opacity(0.05),
            Color.white.opacity(0.0)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Spacing & Radius
struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

struct AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let full: CGFloat = 100
}
