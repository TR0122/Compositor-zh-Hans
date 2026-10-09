import SwiftUI

struct TrimSheet: View {
    let finish: (TrimOptions?) -> Void
    @State private var basedOn: TrimBasedOn = .transparentPixels
    @State private var trimTop: Bool = true
    @State private var trimBottom: Bool = true
    @State private var trimLeft: Bool = true
    @State private var trimRight: Bool = true

    var body: some View { sheet.roundedControls() }

    @ViewBuilder private var sheet: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L("Trim")).font(.title2.bold())

            VStack(alignment: .leading, spacing: 8) {
                Text(L("Based On")).font(.headline)
                Picker("", selection: $basedOn) {
                    ForEach(TrimBasedOn.allCases) { option in
                        Text(option.rawValue.localized).tag(option)
                    }
                }
                .labelsHidden()
                .pickerStyle(.radioGroup)
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(L("Trim Away")).font(.headline)
                Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 8) {
                    GridRow {
                        Toggle(L("Top"), isOn: $trimTop)
                        Toggle(L("Bottom"), isOn: $trimBottom)
                    }
                    GridRow {
                        Toggle(L("Left"), isOn: $trimLeft)
                        Toggle(L("Right"), isOn: $trimRight)
                    }
                }
            }

            Divider()

            HStack {
                Button(L("Cancel")) { finish(nil) }
                    .configuredNativeShortcut(.escape)
                Spacer()
                Button(L("OK")) {
                    let options = TrimOptions(
                        basedOn: basedOn,
                        top: trimTop,
                        bottom: trimBottom,
                        left: trimLeft,
                        right: trimRight
                    )
                    finish(options)
                }
                .configuredNativeShortcut(.return)
                .buttonStyle(.borderedProminent)
                .disabled(!trimTop && !trimBottom && !trimLeft && !trimRight)
            }
        }
        .padding(24)
        .frame(width: 320)
    }
}
