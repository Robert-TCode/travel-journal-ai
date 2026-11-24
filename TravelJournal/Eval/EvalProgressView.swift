#if DEBUG
import SwiftUI

/// Shows a running eval's progress; the runner writes its own report.
struct EvalProgressView<Runner: EvalRunner>: View {
    @State var runner: Runner

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
