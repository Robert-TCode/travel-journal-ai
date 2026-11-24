#if DEBUG
import SwiftUI

struct PhotoEvalView: View {
    @State private var runner = PhotoEvalRunner()

    var body: some View {
        VStack(spacing: 16) {
            if !runner.isFinished {
                ProgressView()
            }
            Text(runner.progress)
                .font(.footnote.monospaced())
                .multilineTextAlignment(.center)
        }
        .padding()
        .task { await runner.run() }
    }
}
#endif
