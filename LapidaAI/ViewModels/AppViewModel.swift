import SwiftUI
import Supabase
import PDFKit
import UniformTypeIdentifiers

// MARK: - App ViewModel (Observable)
@Observable
final class AppViewModel {
    // MARK: - State
    var currentScreen: AppScreen = .landing
    var userProfile = UserProfile()
    var analysisResult: AnalysisResult?
    var inputText: String = ""
    var selectedInputMethod: AnalysisInputMethod = .pdf
    var isFileImporterPresented = false
    var showPremiumModal = false
    var errorMessage: String?
    var showError = false
    var isAuthenticated = false
    var isAuthenticating = false
    var alertTitle = "Erro"
    
    // Loading state
    var isAnalyzing = false
    var loadingMessage = "Preparando análise..."
    var loadingProgress: CGFloat = 0
    
    // Payment state
    var paymentStep: PaymentStep = .benefits
    var isGeneratingPix = false
    var pixPayload: String = ""
    var ticketUrl: String = ""
    var paymentId: String?
    var isCheckingPayment = false
    var paymentConfirmed = false
    var pixCopied = false
    
    // Payment polling timer
    private var pollingTimer: Timer?
    
    // MARK: - Loading Messages
    private let loadingMessages = [
        "Lendo seções do currículo...",
        "Analisando compatibilidade ATS...",
        "Verificando formatação visual...",
        "Consultando Inteligência Artificial...",
        "Avaliando experiências profissionais...",
        "Gerando sugestões de melhoria...",
        "Calculando pontuação final...",
        "Preparando seu dashboard..."
    ]
    
    // MARK: - Analysis Flow
    func startAnalysis() {
        // Bloqueio para usuários gratuitos (Limite de 3 análises)
        if !userProfile.isPremium && userProfile.analysisCount >= 3 {
            showPremiumModal = true
            return
        }
        
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showErrorMessage("Por favor, insira o texto do seu currículo ou importe um PDF.")
            return
        }
        
        isAnalyzing = true
        currentScreen = .loading
        loadingProgress = 0
        
        // Animate through loading messages
        animateLoading()
        
        // Call API
        Task { @MainActor in
            do {
                // Simulate minimum loading time for polish
                async let apiResult = APIService.shared.analyzeResume(text: inputText)
                async let minimumDelay: () = Task.sleep(nanoseconds: 3_500_000_000)
                
                let result = try await apiResult
                _ = try? await minimumDelay
                
                analysisResult = result
            } catch {
                // Use demo data for development/offline
                loadDemoData()
            }
            
            // Incrementa sempre que terminar uma análise
            userProfile.analysisCount += 1
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                currentScreen = .result
                isAnalyzing = false
            }
        }
    }
    
    private func animateLoading() {
        var messageIndex = 0
        let interval = 0.8
        
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            guard let self = self else { timer.invalidate(); return }
            
            Task { @MainActor in
                if !self.isAnalyzing {
                    timer.invalidate()
                    return
                }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.loadingMessage = self.loadingMessages[messageIndex % self.loadingMessages.count]
                    self.loadingProgress = min(CGFloat(messageIndex + 1) / CGFloat(self.loadingMessages.count), 0.95)
                }
                messageIndex += 1
            }
        }
    }
    
    // MARK: - Authentication
    func checkSession() {
        Task { @MainActor in
            if let user = await SupabaseService.shared.getCurrentUser() {
                updateProfile(user: user)
                isAuthenticated = true
            } else {
                isAuthenticated = false
            }
        }
    }
    
    /// Login com Google via Supabase OAuth
    func signInWithGoogle() {
        performOAuthSignIn(provider: .google)
    }
    
    /// Login com GitHub via Supabase OAuth
    func signInWithGitHub() {
        performOAuthSignIn(provider: .github)
    }
    
    func signInWithEmail(email: String, password: String) {
        isAuthenticating = true
        Task { @MainActor in
            do {
                let user = try await SupabaseService.shared.signIn(email: email, password: password)
                updateProfile(user: user)
                withAnimation(.spring()) {
                    isAuthenticated = true
                }
            } catch {
                showErrorMessage(error.localizedDescription)
            }
            isAuthenticating = false
        }
    }
    
    func signUpWithEmail(email: String, password: String) {
        isAuthenticating = true
        Task { @MainActor in
            do {
                _ = try await SupabaseService.shared.signUp(email: email, password: password)
                showAlert(title: "Sucesso!", message: "Cadastro realizado! Verifique seu e-mail para confirmar a conta.")
            } catch {
                showErrorMessage("Erro ao cadastrar: \(error.localizedDescription)")
            }
            isAuthenticating = false
        }
    }
    
    private func performOAuthSignIn(provider: Provider) {
        isAuthenticating = true
        Task { @MainActor in
            do {
                let url = try await SupabaseService.shared.signInWithOAuth(provider: provider)
                // Abre a URL no navegador do sistema para OAuth
                if UIApplication.shared.canOpenURL(url) {
                    await UIApplication.shared.open(url)
                }
            } catch {
                showErrorMessage("Erro ao iniciar login: \(error.localizedDescription)")
                isAuthenticating = false
            }
        }
    }
    
    /// Processa o retorno da autenticação externa (Deep Link)
    func handleAuthCallback(url: URL) {
        Task { @MainActor in
            do {
                try await SupabaseService.shared.handleAuthCallback(url: url)
                if let user = await SupabaseService.shared.getCurrentUser() {
                    updateProfile(user: user)
                    withAnimation(.spring()) {
                        isAuthenticated = true
                    }
                }
            } catch {
                showErrorMessage("Falha na autenticação: \(error.localizedDescription)")
            }
            isAuthenticating = false
        }
    }
    
    private func updateProfile(user: User) {
        userProfile.id = user.id.uuidString
        userProfile.email = user.email
        // Aqui você poderia buscar dados adicionais do perfil na tabela 'profiles' do Supabase
        // fetchProfileData(userId: user.id)
    }
    
    func signOut() {
        Task { @MainActor in
            try? await SupabaseService.shared.signOut()
            isAuthenticated = false
            currentScreen = .landing
            resetToLanding()
        }
    }
    
    // MARK: - File Import
    func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showErrorMessage("Sem permissão para acessar o arquivo.")
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            if let data = try? Data(contentsOf: url),
               let text = extractTextFromPDF(data: data) {
                inputText = text
                startAnalysis()
            } else {
                showErrorMessage("Não foi possível ler o arquivo PDF.")
            }
            
        case .failure(let error):
            showErrorMessage("Erro ao importar: \(error.localizedDescription)")
        }
    }
    
    private func extractTextFromPDF(data: Data) -> String? {
        guard let document = PDFDocument(data: data) else { return nil }
        var fullText = ""
        
        for i in 0..<document.pageCount {
            if let page = document.page(at: i), let content = page.string {
                fullText += content + "\n"
            }
        }
        
        return fullText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : fullText
    }
    
    // MARK: - Payment Flow
    func generatePix() {
        paymentStep = .pix
        isGeneratingPix = true
        
        Task { @MainActor in
            do {
                let response = try await PaymentService.shared.createPixPayment()
                
                if let qrCode = response.qrCode, let id = response.paymentId {
                    pixPayload = qrCode
                    ticketUrl = response.ticketUrl ?? qrCode
                    paymentId = String(id)
                    startPaymentPolling()
                } else {
                    showErrorMessage(response.error ?? "Não foi possível gerar o PIX.")
                    paymentStep = .benefits
                }
            } catch {
                showErrorMessage("Erro ao processar pagamento.")
                paymentStep = .benefits
            }
            
            isGeneratingPix = false
        }
    }
    
    func copyPixCode() {
        guard !pixPayload.isEmpty else { return }
        UIPasteboard.general.string = pixPayload
        
        withAnimation(.spring(response: 0.3)) {
            pixCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            withAnimation { self?.pixCopied = false }
        }
    }
    
    func checkPaymentManually() {
        guard let paymentId else { return }
        isCheckingPayment = true
        
        Task { @MainActor in
            do {
                let response = try await PaymentService.shared.checkPaymentStatus(paymentId: paymentId)
                if response.status == "approved" {
                    confirmPayment()
                } else {
                    showErrorMessage("Ainda não recebemos a confirmação. Aguarde uns segundinhos.")
                }
            } catch {
                showErrorMessage("Erro ao verificar status.")
            }
            isCheckingPayment = false
        }
    }
    
    private func startPaymentPolling() {
        pollingTimer?.invalidate()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
            guard let self = self, let paymentId = self.paymentId, !self.paymentConfirmed else {
                timer.invalidate()
                return
            }
            
            Task { @MainActor in
                do {
                    let response = try await PaymentService.shared.checkPaymentStatus(paymentId: paymentId)
                    if response.status == "approved" {
                        timer.invalidate()
                        self.confirmPayment()
                    }
                } catch {
                    // Silently ignore polling errors
                }
            }
        }
    }
    
    private func confirmPayment() {
        withAnimation(.spring(response: 0.5)) {
            paymentConfirmed = true
            userProfile.isPremium = true
            userProfile.analysisCount = 0
        }
        
        stopPaymentPolling()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.showPremiumModal = false
            self?.resetPaymentState()
        }
    }
    
    func stopPaymentPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    func resetPaymentState() {
        paymentStep = .benefits
        isGeneratingPix = false
        pixPayload = ""
        paymentId = nil
        isCheckingPayment = false
        paymentConfirmed = false
        pixCopied = false
        stopPaymentPolling()
    }
    
    // MARK: - Navigation
    func resetToLanding() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            currentScreen = .landing
            inputText = ""
            analysisResult = nil
            isAnalyzing = false
            loadingProgress = 0
        }
    }
    
    // MARK: - Error Handling
    func showAlert(title: String, message: String) {
        alertTitle = title
        errorMessage = message
        showError = true
    }
    
    func showErrorMessage(_ message: String) {
        showAlert(title: "Erro", message: message)
    }
    
    // MARK: - Demo Data
    func loadDemoData() {
        analysisResult = AnalysisResult(
            overallScore: 72,
            dimensions: [
                AnalysisDimension(name: "ATS", score: 0.78, maxScore: 1.0, label: "Compatibilidade ATS", icon: "cpu"),
                AnalysisDimension(name: "Design", score: 0.65, maxScore: 1.0, label: "Formatação Visual", icon: "paintbrush"),
                AnalysisDimension(name: "Experiência", score: 0.82, maxScore: 1.0, label: "Descrição de Experiências", icon: "briefcase"),
                AnalysisDimension(name: "Habilidades", score: 0.70, maxScore: 1.0, label: "Competências Técnicas", icon: "star"),
                AnalysisDimension(name: "Formação", score: 0.60, maxScore: 1.0, label: "Formação Acadêmica", icon: "graduationcap"),
                AnalysisDimension(name: "Impacto", score: 0.45, maxScore: 1.0, label: "Resultados Mensuráveis", icon: "chart.bar"),
            ],
            suggestions: [
                Suggestion(
                    title: "Adicione métricas de impacto",
                    description: "Inclua números concretos em suas experiências. Ex: 'Aumentei as vendas em 35% em 6 meses'. Recrutadores valorizam resultados quantificáveis.",
                    priority: .critical,
                    category: "Conteúdo",
                    icon: "chart.line.uptrend.xyaxis"
                ),
                Suggestion(
                    title: "Otimize palavras-chave para ATS",
                    description: "Sistemas de triagem automática procuram termos específicos. Inclua as palavras-chave da vaga desejada no corpo do currículo.",
                    priority: .high,
                    category: "ATS",
                    icon: "cpu"
                ),
                Suggestion(
                    title: "Reorganize a seção de habilidades",
                    description: "Divida suas competências em categorias: Técnicas, Ferramentas, Idiomas e Soft Skills para facilitar a leitura.",
                    priority: .medium,
                    category: "Estrutura",
                    icon: "list.bullet.rectangle"
                ),
                Suggestion(
                    title: "Melhore o resumo profissional",
                    description: "Um resumo forte de 2-3 linhas no topo pode aumentar significativamente o impacto inicial do currículo.",
                    priority: .medium,
                    category: "Conteúdo",
                    icon: "text.alignleft"
                ),
                Suggestion(
                    title: "Plano de ação personalizado",
                    description: "Desbloqueie um plano passo-a-passo exclusivo gerado pela IA com sugestões de reescrita para cada seção.",
                    priority: .high,
                    category: "Premium",
                    icon: "star.fill",
                    isPremium: true
                ),
                Suggestion(
                    title: "Sugestões textuais com IA",
                    description: "Receba sugestões de reescrita para cada parágrafo e descubra seções invisíveis para o ATS.",
                    priority: .high,
                    category: "Premium",
                    icon: "wand.and.stars",
                    isPremium: true
                ),
            ],
            actionPlan: ActionPlan(
                summary: "Seu currículo tem uma base sólida, mas precisa de ajustes estratégicos para se destacar.",
                steps: [
                    ActionStep(order: 1, title: "Reescreva as experiências com métricas", description: "Adicione pelo menos um número ou porcentagem em cada experiência profissional.", estimatedImpact: "+15 pontos ATS"),
                    ActionStep(order: 2, title: "Crie um resumo profissional impactante", description: "Escreva 2-3 frases que sintetizem sua proposta de valor única.", estimatedImpact: "+10 pontos geral"),
                    ActionStep(order: 3, title: "Adicione seção de certificações", description: "Liste suas certificações relevantes com datas e instituições.", estimatedImpact: "+8 pontos formação"),
                ],
                insights: [
                    "78% dos recrutadores gastam menos de 7 segundos na primeira análise.",
                    "Currículos com métricas têm 40% mais chances de passar pela triagem.",
                    "Palavras de ação como 'liderou', 'implementou' e 'otimizou' aumentam o impacto."
                ]
            ),
            metadata: AnalysisMetadata(
                analyzedAt: Date(),
                inputType: .text,
                wordCount: 342,
                sectionsFound: ["Dados Pessoais", "Experiência Profissional", "Formação Acadêmica", "Habilidades"]
            )
        )
    }
}

// MARK: - Payment Step
enum PaymentStep {
    case benefits
    case pix
}
