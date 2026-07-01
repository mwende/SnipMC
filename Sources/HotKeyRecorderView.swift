import SwiftUI

struct HotKeyRecorderView: View {
    let title: String
    @Binding var combo: HotKeyCombo

    @State private var isRecording = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(isRecording ? 0.3 : 0.15))
                Text(isRecording ? "Taste drücken… (Esc = Abbrechen)" : combo.displayString)
                    .font(isRecording ? .callout : .body)
                    .lineLimit(1)
                KeyCaptureRepresentable(isRecording: $isRecording) { keyCode, modifiers in
                    combo = HotKeyCombo(keyCode: keyCode, carbonModifiers: modifiers)
                }
            }
            .frame(width: 190, height: 24)
            .onTapGesture { isRecording = true }
        }
    }
}
