#if DEBUG
import SwiftUI

struct SearchEvalView: View {
    @State var runner: SearchEvalRunner

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
