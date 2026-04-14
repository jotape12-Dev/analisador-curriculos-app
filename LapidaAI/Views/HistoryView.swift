import SwiftUI

struct HistoryView: View {
    @Environment(AppViewModel.self) private var viewModel
    @Binding var isPresented: Bool

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale(identifier: "pt_BR")
        return f
    }

    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // MARK: - Navigation Bar
                HStack {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(AppColors.primary)
                            .frame(width: 44, height: 44)
                    }

                    Spacer()

                    Text("Histórico")
                        .font(AppTypography.headline)
                        .foregroundStyle(AppColors.textPrimary)

                    Spacer()

                    // Balancing spacer
                    Color.clear.frame(width: 44, height: 44)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)

                Divider()
                    .background(AppColors.glassBorder)

                if viewModel.analysisHistory.isEmpty {
                    emptyState
                } else {
                    historyList
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 56, weight: .thin))
                .foregroundStyle(AppColors.textTertiary)

            VStack(spacing: AppSpacing.sm) {
                Text("Nenhuma análise registrada")
                    .font(AppTypography.bodyMedium)
                    .foregroundStyle(AppColors.textSecondary)

                Text("Suas análises aparecerão aqui")
                    .font(AppTypography.caption)
                    .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - History List
    private var historyList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: AppSpacing.md) {
                ForEach(viewModel.analysisHistory) { entry in
                    HistoryCard(entry: entry, dateFormatter: dateFormatter) {
                        isPresented = false
                        viewModel.openHistoryEntry(entry)
                    } onDelete: {
                        withAnimation {
                            viewModel.deleteHistoryEntry(entry)
                        }
                    }
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.lg)
        }
    }
}

// MARK: - History Card
private struct HistoryCard: View {
    let entry: HistoryEntry
    let dateFormatter: DateFormatter
    let onOpen: () -> Void
    let onDelete: () -> Void

    private var scoreColor: Color {
        switch entry.result.overallScore {
        case 80...: return AppColors.success
        case 60..<80: return AppColors.warning
        default: return AppColors.danger
        }
    }

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: AppSpacing.md) {
                // Score badge
                ZStack {
                    Circle()
                        .fill(scoreColor.opacity(0.15))
                        .frame(width: 52, height: 52)
                    VStack(spacing: 0) {
                        Text("\(entry.result.overallScore)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(scoreColor)
                        Text("pts")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(scoreColor.opacity(0.8))
                    }
                }

                // Info
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(entry.inputPreview.isEmpty ? "Currículo analisado" : entry.inputPreview)
                        .font(AppTypography.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: AppSpacing.sm) {
                        Label(
                            entry.result.metadata.inputType == .pdf ? "PDF" : "Texto",
                            systemImage: entry.result.metadata.inputType == .pdf ? "doc.fill" : "text.alignleft"
                        )
                        .font(AppTypography.captionSmall)
                        .foregroundStyle(AppColors.textTertiary)

                        Text("·")
                            .foregroundStyle(AppColors.textTertiary)

                        Text(dateFormatter.string(from: entry.analyzedAt))
                            .font(AppTypography.captionSmall)
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.textTertiary)
            }
            .glassCard(cornerRadius: AppRadius.lg, padding: AppSpacing.md)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive, action: onDelete) {
                Label("Excluir", systemImage: "trash")
            }
        }
    }
}
