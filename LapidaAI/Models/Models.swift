import Foundation

// MARK: - Analysis Result
struct AnalysisResult: Codable, Identifiable {
    let id: UUID
    let overallScore: Int
    let dimensions: [AnalysisDimension]
    let suggestions: [Suggestion]
    let actionPlan: ActionPlan?
    let metadata: AnalysisMetadata
    
    init(
        id: UUID = UUID(),
        overallScore: Int,
        dimensions: [AnalysisDimension],
        suggestions: [Suggestion],
        actionPlan: ActionPlan? = nil,
        metadata: AnalysisMetadata
    ) {
        self.id = id
        self.overallScore = overallScore
        self.dimensions = dimensions
        self.suggestions = suggestions
        self.actionPlan = actionPlan
        self.metadata = metadata
    }
}

// MARK: - Analysis Dimension (for Radar Chart)
struct AnalysisDimension: Codable, Identifiable {
    var id: String { name }
    let name: String
    let score: Double       // 0.0 to 1.0
    let maxScore: Double    // usually 1.0
    let label: String
    let icon: String        // SF Symbol name
    
    var percentage: Int {
        Int(score * 100)
    }
}

// MARK: - Suggestion
struct Suggestion: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let priority: SuggestionPriority
    let category: String
    let icon: String        // SF Symbol name
    let isPremium: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        priority: SuggestionPriority,
        category: String,
        icon: String,
        isPremium: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.priority = priority
        self.category = category
        self.icon = icon
        self.isPremium = isPremium
    }
}

enum SuggestionPriority: String, Codable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var color: String {
        switch self {
        case .critical: return "EF4444"
        case .high: return "F97316"
        case .medium: return "F59E0B"
        case .low: return "22C55E"
        }
    }
    
    var label: String {
        switch self {
        case .critical: return "Crítico"
        case .high: return "Alta"
        case .medium: return "Média"
        case .low: return "Baixa"
        }
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "arrow.up.circle.fill"
        case .medium: return "minus.circle.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
}

// MARK: - Action Plan (Premium)
struct ActionPlan: Codable {
    let summary: String
    let steps: [ActionStep]
    let insights: [String]
}

struct ActionStep: Codable, Identifiable {
    let id: UUID
    let order: Int
    let title: String
    let description: String
    let estimatedImpact: String
    
    init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        description: String,
        estimatedImpact: String
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.description = description
        self.estimatedImpact = estimatedImpact
    }
}

// MARK: - Analysis Metadata
struct AnalysisMetadata: Codable {
    let analyzedAt: Date
    let inputType: InputType
    let wordCount: Int
    let sectionsFound: [String]
}

enum InputType: String, Codable {
    case pdf = "pdf"
    case text = "text"
}

// MARK: - User Profile
struct UserProfile: Codable {
    var id: String?
    var email: String?
    var name: String?
    var analysisCount: Int
    var isPremium: Bool
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case analysisCount = "analysis_count"
        case isPremium = "is_premium"
        case createdAt = "created_at"
    }
    
    init(
        id: String? = nil,
        email: String? = nil,
        name: String? = nil,
        analysisCount: Int = 0,
        isPremium: Bool = false,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.analysisCount = analysisCount
        self.isPremium = isPremium
        self.createdAt = createdAt
    }
}

// MARK: - Payment Models
struct PaymentCreateResponse: Codable {
    let qrCode: String?
    let qrCodeBase64: String?
    let ticketUrl: String?
    let paymentId: Int64?
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case qrCode = "qr_code"
        case qrCodeBase64 = "qr_code_base_64"
        case ticketUrl = "ticket_url"
        case paymentId = "payment_id"
        case error
    }
}

struct PaymentStatusResponse: Codable {
    let status: String
    let error: String?
}

// MARK: - App State
enum AppScreen {
    case landing
    case loading
    case result
}

enum AnalysisInputMethod {
    case pdf
    case text
}
