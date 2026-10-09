import SwiftUI

struct CanvasSizeSheet: View {
    let foreground: PaletteColor
    let background: PaletteColor
    let session: EditorSession
    let finish: (CanvasSizeOptions?) -> Void
    @State private var draft: CanvasSizeDraft
    @State private var anchor = 4
    @State private var extensionChoice = L("Transparent")
    @State private var customColor = PaletteColor.white
    private let anchorNames = [L("Top left"), L("Top center"), L("Top right"), L("Middle left"), L("Center"), L("Middle right"), L("Bottom left"), L("Bottom center"), L("Bottom right")]

    init(document: CanvasDocument, session: EditorSession, finish: @escaping (CanvasSizeOptions?) -> Void) {
        self.foreground = session.foregroundColor
        self.background = session.backgroundColor
        self.session = session
        self.finish = finish
        _draft = State(initialValue: CanvasSizeDraft(width: document.width, height: document.height, resolution: document.resolution))
    }

    private func dimension(_ widthAxis: Bool) -> Binding<Double> {
        Binding(get: { draft.displayed(widthAxis: widthAxis) }, set: { draft.set($0, widthAxis: widthAxis) })
    }
    private func scrubRange(_ widthAxis: Bool) -> ClosedRange<Double> {
        let original = Double(widthAxis ? draft.originalWidth : draft.originalHeight)
        let other = Double(widthAxis ? draft.originalHeight : draft.originalWidth)
        let lower = draft.locked ? max(1, original / other) : 1.0
        let upper = draft.locked ? min(30_000, 30_000 * original / other) : 30_000.0
        func displayed(_ pixels: Double) -> Double {
            let difference = pixels - (draft.relative ? original : 0)
            switch draft.unit {
            case .pixels: return difference
            case .percent: return difference / original * 100
            case .inches: return difference / draft.resolution
            case .centimeters: return difference / draft.resolution * 2.54
            }
        }
        return displayed(lower)...displayed(upper)
    }
    private func scrubSensitivity(_ widthAxis: Bool) -> Double {
        switch draft.unit {
        case .pixels: return 1
        case .percent: return 100 / Double(widthAxis ? draft.originalWidth : draft.originalHeight)
        case .inches: return 1 / draft.resolution
        case .centimeters: return 2.54 / draft.resolution
        }
    }
    private func bytes(_ width: Int, _ height: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(width) * Int64(height) * 4, countStyle: .memory)
    }
    private var fill: CanvasExtensionColor? {
        let color: NSColor
        switch extensionChoice {
        case L("Transparent"): return nil
        case L("Black"): color = .black
        case L("Foreground"): color = foreground.nsColor
        case L("White"): color = .white
        case L("Background"): color = background.nsColor
        default: color = customColor.nsColor
        }
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        return CanvasExtensionColor(red: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent)
    }

    var body: some View { sheet.roundedControls() }
    @ViewBuilder private var sheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("Canvas Size")).font(.title2.bold())
            Text("当前：\(draft.originalWidth) × \(draft.originalHeight) 像素")
            Text("\(bytes(draft.originalWidth, draft.originalHeight)) 未压缩 RGBA 画布")
                .font(.callout).foregroundStyle(.secondary)
            Divider()
            Picker(L("Units"), selection: $draft.unit) {
                ForEach(CanvasUnit.allCases, id: \.self) { Text($0.rawValue.localized).tag($0) }
            }
            HStack {
                Text(L("Width")).frame(width: 60, alignment: .leading)
                    .scrubbable(sensitivity: scrubSensitivity(true), value: dimension(true), range: scrubRange(true), step: 1)
                TextField(L("Width"), value: dimension(true), format: .number.precision(.fractionLength(0...3)))
            }
            HStack {
                Text(L("Height")).frame(width: 60, alignment: .leading)
                    .scrubbable(sensitivity: scrubSensitivity(false), value: dimension(false), range: scrubRange(false), step: 1)
                TextField(L("Height"), value: dimension(false), format: .number.precision(.fractionLength(0...3)))
            }
            Toggle(L("Relative to current dimensions"), isOn: $draft.relative)
            Toggle(L("Lock original aspect ratio"), isOn: $draft.locked)
                .onChange(of: draft.locked) { _, locked in
                    if locked { draft.set(draft.displayed(widthAxis: true), widthAxis: true) }
                }
            if draft.valid {
                Text("新尺寸：\(Int(draft.width.rounded())) × \(Int(draft.height.rounded())) 像素 · \(bytes(Int(draft.width.rounded()), Int(draft.height.rounded())))（未压缩）")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                Text("最终尺寸的每边必须为 1–\(DocumentLimits.maxSide.formatted()) 像素。")
                    .font(.callout).foregroundStyle(.orange)
            }
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("Anchor"))
                    Grid(horizontalSpacing: 3, verticalSpacing: 3) {
                        ForEach(0..<3) { row in
                            GridRow {
                                ForEach(0..<3) { column in
                                    let index = row * 3 + column
                                    Button { anchor = index } label: {
                                        Image(systemName: index == anchor ? "circle.fill" : "circle")
                                            .frame(width: 25, height: 25)
                                    }
                                    .tint(index == anchor ? .accentColor : .secondary)
                                    .help(anchorNames[index]).accessibilityLabel(anchorNames[index])
                                    .accessibilityValue(index == anchor ? L("Selected") : "")
                                }
                            }
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(anchorNames[anchor]).font(.callout.bold())
                    Text(L("Keeps this point fixed. Artwork is not scaled; cropped content remains outside the canvas."))
                        .font(.callout).foregroundStyle(.secondary)
                }.padding(.top, 28)
            }
            Picker(L("Canvas extension"), selection: $extensionChoice) {
                ForEach([L("Transparent"), L("Foreground"), L("Background"), L("Black"), L("White"), L("Custom")], id: \.self) { Text($0) }
            }
            if extensionChoice == L("Custom") {
                HStack(spacing: 8) {
                    Text(L("Extension color"))
                    DialogColorSwatch(title: L("Extension Color"), color: $customColor, session: session)
                        .help(L("Color for the added canvas"))
                }
            }
            HStack {
                Button(L("Cancel")) { DialogColorSwatch.closePicker(session); finish(nil) }.configuredNativeShortcut(.escape)
                Spacer()
                Button(L("OK")) {
                    guard draft.valid else { return }
                    DialogColorSwatch.closePicker(session)
                    finish(CanvasSizeOptions(width: Int(draft.width.rounded()), height: Int(draft.height.rounded()), anchor: anchor, fill: fill))
                }.configuredNativeShortcut(.return).disabled(!draft.valid)
            }
        }.textFieldStyle(.roundedBorder).padding(24).frame(width: 450)
    }
}
