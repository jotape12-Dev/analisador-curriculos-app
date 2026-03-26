import Foundation
import Supabase

// MARK: - API Configuration
enum APIConfig {
    static let baseURL = "https://analisador-curriculos-a74g.vercel.app"
    
    enum Endpoints {
        static let analyze = "/api/analyze"
        static let paymentCreate = "/api/payment/mp/create"
        static let paymentStatus = "/api/payment/mp/status"
    }
}

// MARK: - API Service
actor APIService {
    static let shared = APIService()
    
    private let session: URLSession
    private let decoder: JSONDecoder
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Analyze Resume
    func analyzeResume(text: String) async throws -> AnalysisResult {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.analyze) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Injetar Token do Supabase
        if let token = await SupabaseService.shared.getSessionToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let body: [String: Any] = ["text": text]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        // Parse the response and convert to our model
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return parseAnalysisResponse(json)
    }
    
    // MARK: - Parse Analysis Response
    private func parseAnalysisResponse(_ json: [String: Any]) -> AnalysisResult {
        let overallScore = json["overall_score"] as? Int ?? 65
        
        // Parse dimensions
        let dimensionsRaw = json["dimensions"] as? [[String: Any]] ?? []
        let dimensions: [AnalysisDimension] = dimensionsRaw.isEmpty
            ? Self.defaultDimensions(score: overallScore)
            : dimensionsRaw.map { dim in
                AnalysisDimension(
                    name: dim["name"] as? String ?? "",
                    score: dim["score"] as? Double ?? 0.5,
                    maxScore: 1.0,
                    label: dim["label"] as? String ?? "",
                    icon: dim["icon"] as? String ?? "circle"
                )
            }
        
        // Parse suggestions
        let suggestionsRaw = json["suggestions"] as? [[String: Any]] ?? []
        let suggestions: [Suggestion] = suggestionsRaw.isEmpty
            ? Self.defaultSuggestions()
            : suggestionsRaw.map { sug in
                Suggestion(
                    title: sug["title"] as? String ?? "",
                    description: sug["description"] as? String ?? "",
                    priority: SuggestionPriority(rawValue: sug["priority"] as? String ?? "medium") ?? .medium,
                    category: sug["category"] as? String ?? "",
                    icon: sug["icon"] as? String ?? "lightbulb",
                    isPremium: sug["is_premium"] as? Bool ?? false
                )
            }
        
        // Parse action plan
        var actionPlan: ActionPlan? = nil
        if let planDict = json["action_plan"] as? [String: Any] {
            let steps = (planDict["steps"] as? [[String: Any]] ?? []).enumerated().map { (i, step) in
                ActionStep(
                    order: i + 1,
                    title: step["title"] as? String ?? "",
                    description: step["description"] as? String ?? "",
                    estimatedImpact: step["impact"] as? String ?? ""
                )
            }
            actionPlan = ActionPlan(
                summary: planDict["summary"] as? String ?? "",
                steps: steps,
                insights: planDict["insights"] as? [String] ?? []
            )
        }
        
        let sectionsFound = json["sections_found"] as? [String] ?? ["Dados Pessoais", "Experiência", "Formação"]
        
        return AnalysisResult(
            overallScore: overallScore,
            dimensions: dimensions,
            suggestions: suggestions,
            actionPlan: actionPlan,
            metadata: AnalysisMetadata(
                analyzedAt: Date(),
                inputType: .text,
                wordCount: (json["word_count"] as? Int) ?? 0,
                sectionsFound: sectionsFound
            )
        )
    }
    
    // MARK: - Default Data (Demo/Fallback)
    private static func defaultDimensions(score: Int) -> [AnalysisDimension] {
        let base = Double(score) / 100.0
        return [
            AnalysisDimension(name: "ATS", score: min(base + 0.1, 1.0), maxScore: 1.0, label: "Compatibilidade ATS", icon: "cpu"),
            AnalysisDimension(name: "Design", score: max(base - 0.05, 0), maxScore: 1.0, label: "Formatação Visual", icon: "paintbrush"),
            AnalysisDimension(name: "Experiência", score: base, maxScore: 1.0, label: "Experiência Profissional", icon: "briefcase"),
            AnalysisDimension(name: "Habilidades", score: min(base + 0.05, 1.0), maxScore: 1.0, label: "Competências Técnicas", icon: "star"),
            AnalysisDimension(name: "Formação", score: max(base - 0.1, 0), maxScore: 1.0, label: "Formação Acadêmica", icon: "graduationcap"),
            AnalysisDimension(name: "Impacto", score: max(base - 0.15, 0), maxScore: 1.0, label: "Resultados Mensuráveis", icon: "chart.bar"),
        ]
    }
    
    private static func defaultSuggestions() -> [Suggestion] {
        [
            Suggestion(
                title: "Adicione métricas de impacto",
                description: "Quantifique seus resultados com números concretos. Ex: 'Aumentei as vendas em 35%'.",
                priority: .critical,
                category: "Conteúdo",
                icon: "chart.line.uptrend.xyaxis"
            ),
            Suggestion(
                title: "Otimize para sistemas ATS",
                description: "Use palavras-chave da vaga desejada nos títulos e descrições das experiências.",
                priority: .high,
                category: "ATS",
                icon: "cpu"
            ),
            Suggestion(
                title: "Melhore a seção de habilidades",
                description: "Categorize suas competências em técnicas, ferramentas e soft skills.",
                priority: .medium,
                category: "Estrutura",
                icon: "list.bullet.rectangle"
            ),
            Suggestion(
                title: "Revisão gramatical",
                description: "Considere usar ferramentas de revisão para garantir clareza textual.",
                priority: .low,
                category: "Linguagem",
                icon: "text.magnifyingglass"
            ),
            Suggestion(
                title: "Plano de ação personalizado",
                description: "Desbloqueie seu plano exclusivo com passos detalhados para melhorar cada seção do currículo.",
                priority: .high,
                category: "Premium",
                icon: "star.fill",
                isPremium: true
            ),
            Suggestion(
                title: "Sugestões textuais com IA",
                description: "Receba sugestões de reescrita geradas pela IA para cada trecho do seu currículo.",
                priority: .high,
                category: "Premium",
                icon: "wand.and.stars",
                isPremium: true
            ),
        ]
    }
}

// MARK: - Payment Service
actor PaymentService {
    static let shared = PaymentService()
    
    private let session: URLSession
    
    private init() {
        self.session = URLSession.shared
    }
    
    func createPixPayment() async throws -> PaymentCreateResponse {
        guard let url = URL(string: APIConfig.baseURL + APIConfig.Endpoints.paymentCreate) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Injetar Token do Supabase
        if let token = await SupabaseService.shared.getSessionToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        if httpResponse.statusCode == 200 {
            do {
                return try JSONDecoder().decode(PaymentCreateResponse.self, from: data)
            } catch {
                throw APIError.decodingError
            }
        } else {
            throw APIError.serverError(httpResponse.statusCode)
        }
    }
    
    func checkPaymentStatus(paymentId: String) async throws -> PaymentStatusResponse {
        guard let url = URL(string: "\(APIConfig.baseURL)\(APIConfig.Endpoints.paymentStatus)?id=\(paymentId)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        
        // Injetar Token do Supabase
        if let token = await SupabaseService.shared.getSessionToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(PaymentStatusResponse.self, from: data)
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case paymentFailed
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL inválida"
        case .invalidResponse: return "Resposta inválida do servidor"
        case .serverError(let code): return "Erro do servidor (\(code))"
        case .decodingError: return "Erro ao processar dados"
        case .paymentFailed: return "Falha no pagamento"
        case .noData: return "Nenhum dado recebido"
        }
    }
}

// MARK: - Supabase Configuration
enum SupabaseConfig {
    static let url = URL(string: "https://gpmsvbblqmetrsrdrqeb.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdwbXN2YmJscW1ldHJzcmRycWViIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MDk1NTIsImV4cCI6MjA4OTk4NTU1Mn0.HZO8cQVWBBVkotKT1gBS5YpjCvvxWfhZAJnL9NwgDcE"
}

// MARK: - Supabase Service
@MainActor
public final class SupabaseService {
    public static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }
    
    func signIn(email: String, password: String) async throws -> User {
        let response = try await client.auth.signIn(email: email, password: password)
        return response.user
    }
    
    func signUp(email: String, password: String) async throws -> User {
        let response = try await client.auth.signUp(email: email, password: password)
        return response.user
    }
    
    func signInWithOAuth(provider: Provider) async throws -> URL {
        let url = try client.auth.getOAuthSignInURL(
            provider: provider,
            redirectTo: URL(string: "lapidaai://auth-callback")
        )
        return url
    }
    
    func handleAuthCallback(url: URL) async throws {
        _ = try await client.auth.session(from: url)
    }
    
    func getCurrentUser() async -> User? {
        try? await client.auth.session.user
    }
    
    func fetchProfile() async throws -> UserProfile {
        let user = try await client.auth.session.user
        let profile: UserProfile = try await client.database
            .from("profiles")
            .select()
            .eq("id", value: user.id)
            .single()
            .execute()
            .value
        return profile
    }
    
    func updateProfile(_ profile: UserProfile) async {
        try? await client.database
            .from("profiles")
            .upsert(profile)
            .execute()
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getSessionToken() async -> String? {
        try? await client.auth.session.accessToken
    }
}
