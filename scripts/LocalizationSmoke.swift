import AppKit
import ImageIO
import Foundation

@main
struct LocalizationSmoke {
    @MainActor static func main() async throws {
        _ = NSApplication.shared
        var passed = 0
        func check(_ value: Bool, _ message: String) throws {
            guard value else { throw NSError(domain: "LocalizationSmoke", code: 1, userInfo: [NSLocalizedDescriptionKey: message]) }
            passed += 1
        }
        try check(L("Layers") == "图层", "Chinese resource lookup")
        try check(L("Save") == "存储", "Chinese file commands")
        try check(FilterKind.gaussianBlur.rawValue.localized == "高斯模糊", "Dynamic filter title")
        try check(LayerBlendMode.multiply.rawValue == "Multiply", "Stable blend raw value")
        for mode in LayerBlendMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(LayerBlendMode.self, from: data)
            try check(decoded == mode, "Blend mode Codable round trip")
            try check(mode.rawValue.localized != mode.rawValue, "Chinese blend mode: \(mode.rawValue)")
        }
        for kind in FilterKind.allCases {
            try check(kind.rawValue.localized != kind.rawValue, "Chinese filter: \(kind.rawValue)")
        }
        let session = EditorSession()
        session.createDocument(width: 8, height: 6, emptyLayer: true,
                               background: CGColor(srgbRed: 0.8, green: 0.2, blue: 0.1, alpha: 1))
        try check(session.activeLayer?.name == "背景", "Chinese background layer")
        session.addBlankLayer()
        try check(session.activeLayer?.name.hasPrefix("图层 ") == true, "Chinese layer naming")
        session.undo()
        try check(session.document?.layers.count == 1, "Undo layer creation")
        session.redo()
        try check(session.document?.layers.count == 2, "Redo layer creation")
        let button = NSPopUpButton(frame: .zero, pullsDown: false)
        button.addItem(withTitle: LayerBlendMode.multiply.rawValue.localized)
        button.lastItem?.representedObject = LayerBlendMode.multiply.rawValue
        let coordinator = BlendModePicker.Coordinator(session: session)
        coordinator.menuWillOpen(button.menu!)
        coordinator.menu(button.menu!, willHighlight: button.lastItem)
        try check(session.activeLayer?.blendMode == .normal, "Hover leaves saved mode intact")
        coordinator.choose(button)
        try check(session.activeLayer?.blendMode == .multiply, "Chinese popup commits correct mode")
        session.undo()
        try check(session.activeLayer?.blendMode == .normal, "Undo blend mode")
        session.redo()
        try check(session.activeLayer?.blendMode == .multiply, "Redo blend mode")
        let snapshot = session.projectSnapshot()!
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Compositor-中文测试-\(UUID()).comp")
        defer { try? FileManager.default.removeItem(at: url) }
        try await ProjectStore.shared.save(snapshot, to: url)
        let loaded = try await ProjectStore.shared.load(from: url)
        try check(loaded.manifest.layers.map(\.name) == snapshot.manifest.layers.map(\.name), "Chinese layer names survive save/open")
        try check(loaded.manifest.layers.last?.blendMode == .multiply, "Blend survives save/open")
        let json = try String(contentsOf: url.appendingPathComponent("manifest.json"), encoding: .utf8)
        try check(json.contains("Multiply") && !json.contains("正片叠底"), "Saved format keeps English enum identifiers")
        let data = try await ImageExporter.shared.pngData(loaded)
        let image = CGImageSourceCreateImageAtIndex(CGImageSourceCreateWithData(data as CFData, nil)!, 0, nil)!
        try check(image.width == 8 && image.height == 6, "PNG export dimensions")
        let bitmap = NSBitmapImageRep(cgImage: image)
        try check(bitmap.colorAt(x: 3, y: 3)!.redComponent > 0.7, "PNG rendered pixels")
        let definitions = ShortcutDefinition.all
        try check(definitions.contains { $0.title == "新建画布" && $0.original == ShortcutChord("n", 1) }, "Localized shortcut keeps Cmd-N")
        try check(CommandPaletteSearch.score("高斯", in: "滤镜 › 高斯模糊…") != nil, "Chinese command search")
        print("PASS: \(passed) localization, editing, blend mode, serialization, PNG, shortcut and search checks")
    }
}
