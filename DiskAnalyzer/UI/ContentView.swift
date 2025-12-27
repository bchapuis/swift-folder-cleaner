import SwiftUI

struct ContentView: View {
    @State private var scanResult: ScanResult?
    @State private var isScanning = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Disk Analyzer")
                .font(.largeTitle)

            if isScanning {
                ProgressView("Scanning...")
            } else if let result = scanResult {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Scan Complete!")
                        .font(.headline)
                    Text("Files scanned: \(result.totalFilesScanned)")
                    Text("Total size: \(result.rootNode.formattedSize)")
                    Text("Duration: \(result.formattedDuration)")
                }
                .padding()
                .background(.quaternary)
                .cornerRadius(8)
            } else if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundStyle(.red)
            } else {
                Text("Ready to scan")
                    .foregroundStyle(.secondary)
            }

            Button("Test Scan (Home Directory)") {
                testScan()
            }
            .disabled(isScanning)
        }
        .padding()
        .frame(minWidth: 800, minHeight: 600)
    }

    private func testScan() {
        isScanning = true
        errorMessage = nil
        scanResult = nil

        Task {
            do {
                let scanner = AsyncFileScanner()
                let homeDir = FileManager.default.homeDirectoryForCurrentUser

                // Scan just the Documents folder to keep it quick
                let docsDir = homeDir.appendingPathComponent("Documents")

                let result = try await scanner.scan(url: docsDir) { progress in
                    print("Scanned \(progress.filesScanned) files - \(progress.formattedBytesScanned)")
                }

                await MainActor.run {
                    self.scanResult = result
                    self.isScanning = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isScanning = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
