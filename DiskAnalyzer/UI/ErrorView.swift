import SwiftUI

/// View shown when scan fails
struct ErrorView: View {
    let error: ScanError
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Scan Failed", systemImage: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
        } description: {
            VStack(spacing: 12) {
                Text(error.localizedDescription)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)

                if let reason = error.failureReason {
                    Text(reason)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
            .padding()
        } actions: {
            Button {
                onRetry()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }
}

#Preview("Permission Denied") {
    ErrorView(
        error: .permissionDenied(path: "/System/Library"),
        onRetry: {}
    )
}

#Preview("Path Not Found") {
    ErrorView(
        error: .pathNotFound(path: "/Users/example/deleted"),
        onRetry: {}
    )
}

#Preview("Not a Directory") {
    ErrorView(
        error: .notADirectory(path: "/Users/example/file.txt"),
        onRetry: {}
    )
}
