import Foundation
import Supabase
import StoreKit
import Observation

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
        
        let body: [String: Any] = ["curriculo": text]
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
    // API returns: score_geral, scores{ats, aderencia_vaga, qualidade_experiencias, clareza},
    //              resumo, skills_encontradas, skills_faltantes, secoes_presentes, secoes_faltantes,
    //              recomendacoes[{titulo, descricao, sugestao}], _profile{analysis_count, is_premium}
    private func parseAnalysisResponse(_ json: [String: Any]) -> AnalysisResult {
        let overallScore = json["score_geral"] as? Int ?? 50

        // Parse dimensions from scores object
        // JSONSerialization returns numbers as NSNumber, so extract via NSNumber.doubleValue
        let scores = json["scores"] as? [String: Any] ?? [:]
        func extractScore(_ key: String) -> Double {
            if let d = scores[key] as? Double { return d }
            if let i = scores[key] as? Int { return Double(i) }
            return 50.0
        }
        let ats = extractScore("ats")
        let aderencia = extractScore("aderencia_vaga")
        let experiencia = extractScore("qualidade_experiencias")
        let clareza = extractScore("clareza")

        let dimensions: [AnalysisDimension] = [
            AnalysisDimension(name: "ATS", score: ats / 100.0, maxScore: 1.0, label: "Compatibilidade ATS", icon: "cpu"),
            AnalysisDimension(name: "Aderência", score: aderencia / 100.0, maxScore: 1.0, label: "Aderência à Vaga", icon: "target"),
            AnalysisDimension(name: "Experiência", score: experiencia / 100.0, maxScore: 1.0, label: "Qualidade das Experiências", icon: "briefcase"),
            AnalysisDimension(name: "Clareza", score: clareza / 100.0, maxScore: 1.0, label: "Clareza e Objetividade", icon: "text.alignleft"),
        ]

        // Parse suggestions from recomendacoes
        let prioridades: [SuggestionPriority] = [.critical, .high, .medium, .medium, .low]
        let iconePorIndice = ["chart.line.uptrend.xyaxis", "cpu", "list.bullet.rectangle", "text.magnifyingglass", "lightbulb"]
        let recomendacoes = json["recomendacoes"] as? [[String: Any]] ?? []

        var suggestions: [Suggestion] = recomendacoes.enumerated().map { (i, rec) in
            let titulo = rec["titulo"] as? String ?? ""
            let descricao = rec["descricao"] as? String ?? ""
            let sugestao = rec["sugestao"] as? String ?? ""
            let fullDescription = sugestao.isEmpty ? descricao : "\(descricao)\n\n💡 \(sugestao)"
            return Suggestion(
                title: titulo,
                description: fullDescription,
                priority: prioridades[min(i, prioridades.count - 1)],
                category: "Melhoria",
                icon: iconePorIndice[min(i, iconePorIndice.count - 1)]
            )
        }

        // Add locked premium suggestions
        suggestions += [
            Suggestion(
                title: "Plano de ação detalhado",
                description: "Receba um plano passo-a-passo exclusivo com sugestões de reescrita para cada seção.",
                priority: .high,
                category: "Premium",
                icon: "star.fill",
                isPremium: true
            ),
            Suggestion(
                title: "Reescrita com IA",
                description: "Textos alternativos gerados pela IA para cada trecho fraco do seu currículo.",
                priority: .high,
                category: "Premium",
                icon: "wand.and.stars",
                isPremium: true
            ),
        ]

        // Build action plan from resumo + recomendacoes + skills_faltantes
        let resumo = json["resumo"] as? String ?? ""
        let skillsFaltantes = json["skills_faltantes"] as? [String] ?? []
        let actionSteps = recomendacoes.enumerated().map { (i, rec) in
            ActionStep(
                order: i + 1,
                title: rec["titulo"] as? String ?? "",
                description: rec["sugestao"] as? String ?? rec["descricao"] as? String ?? "",
                estimatedImpact: ""
            )
        }
        let insights: [String] = skillsFaltantes.isEmpty
            ? ["Revise as seções faltantes e inclua métricas de impacto."]
            : skillsFaltantes.map { "Habilidade ausente: \($0)" }

        let actionPlan = ActionPlan(summary: resumo, steps: actionSteps, insights: insights)

        let sectionsFound = json["secoes_presentes"] as? [String] ?? []

        return AnalysisResult(
            overallScore: overallScore,
            dimensions: dimensions,
            suggestions: suggestions,
            actionPlan: actionPlan,
            metadata: AnalysisMetadata(
                analyzedAt: Date(),
                inputType: .text,
                wordCount: 0,
                sectionsFound: sectionsFound
            )
        )
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
    
    func deleteUserAccount() async throws {
        let user = try await client.auth.session.user
        try await client.database
            .from("profiles")
            .delete()
            .eq("id", value: user.id)
            .execute()
        
        // Em um app completo, você chamaria uma RPC para deletar o Auth User também.
        // Como o Supabase não permite auto-deleção nativa via Auth SDK por segurança, 
        // remover os dados do perfil já atende a maior parte dos requisitos de UI da Apple.
    }
    
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    func getSessionToken() async -> String? {
        try? await client.auth.session.accessToken
    }
}
