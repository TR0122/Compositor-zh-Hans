import AppKit
import SwiftUI

struct ShortcutChord: Codable, Equatable, Hashable {
    var key: String
    var modifiers: Int
    init(_ key: String, _ modifiers: Int = 0) { self.key = key; self.modifiers = modifiers }
    // Stable stored bits: Command, Option, Control, Shift.
    init(_ event: NSEvent) {
        let flags = event.modifierFlags
        modifiers = (flags.contains(.command) ? 1 : 0) | (flags.contains(.option) ? 2 : 0)
            | (flags.contains(.control) ? 4 : 0) | (flags.contains(.shift) ? 8 : 0)
        switch event.keyCode {
        case 51, 117: key = "\u{7f}"
        case 36, 76: key = "\r"
        case 53: key = "\u{1b}"
        case 48: key = "\t"
        case 49: key = " "
        case 123: key = "\u{f702}"
        case 124: key = "\u{f703}"
        case 125: key = "\u{f701}"
        case 126: key = "\u{f700}"
        default:
            let typed = event.charactersIgnoringModifiers?.lowercased() ?? ""
            key = ["{": "[", "}": "]", "+": "=", "_": "-" ][typed] ?? typed
        }
    }
    var eventModifiers: EventModifiers {
        var flags: EventModifiers = []
        if modifiers & 1 != 0 { flags.insert(.command) }
        if modifiers & 2 != 0 { flags.insert(.option) }
        if modifiers & 4 != 0 { flags.insert(.control) }
        if modifiers & 8 != 0 { flags.insert(.shift) }
        return flags
    }
    var cocoaModifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if modifiers & 1 != 0 { flags.insert(.command) }
        if modifiers & 2 != 0 { flags.insert(.option) }
        if modifiers & 4 != 0 { flags.insert(.control) }
        if modifiers & 8 != 0 { flags.insert(.shift) }
        return flags
    }
    var label: String {
        let special = ["\u{7f}": L("Delete"), "\r": L("Return"), "\u{1b}": L("Esc"), "\t": L("Tab"), " ": L("Space"),
                       "\u{f702}": "←", "\u{f703}": "→", "\u{f701}": "↓", "\u{f700}": "↑"]
        return (modifiers & 4 != 0 ? "⌃" : "") + (modifiers & 2 != 0 ? "⌥" : "")
            + (modifiers & 8 != 0 ? "⇧" : "") + (modifiers & 1 != 0 ? "⌘" : "")
            + (special[key] ?? key.uppercased())
    }
    func event(like event: NSEvent) -> NSEvent? {
        let codes: [String: UInt16] = ["\u{7f}": 51, "\r": 36, "\u{1b}": 53, "\t": 48, " ": 49,
                                       "\u{f702}": 123, "\u{f703}": 124, "\u{f701}": 125, "\u{f700}": 126,
                                       "=": 24, "-": 27]
        let shifted = modifiers & 8 != 0 ? (["[": "{", "]": "}", "=": "+", "-": "_"][key] ?? key) : key
        return NSEvent.keyEvent(with: event.type, location: event.locationInWindow, modifierFlags: cocoaModifiers,
            timestamp: event.timestamp, windowNumber: event.windowNumber, context: nil,
            characters: shifted, charactersIgnoringModifiers: shifted, isARepeat: event.isARepeat,
            keyCode: codes[key] ?? 0xffff)
    }
}

struct ShortcutDefinition: Identifiable {
    let title: String
    let group: String
    let original: ShortcutChord
    var id: String { "\(group):\(title)" }
    var isMenu: Bool { group == L("Menus") }

    static let all: [ShortcutDefinition] = {
        func entry(_ title: String, _ key: String, _ modifiers: Int = 0, menu: Bool = false) -> ShortcutDefinition {
            .init(title: title, group: menu ? L("Menus") : L("Canvas & Layers"), original: ShortcutChord(key, modifiers))
        }
        var result: [ShortcutDefinition] = [
            entry(L("Undo"), "z", 1, menu: true), entry(L("Redo"), "z", 9, menu: true),
            entry(L("New Canvas"), "n", 1, menu: true), entry(L("Open Project"), "o", 1, menu: true),
            entry(L("Save"), "s", 1, menu: true), entry(L("Save As"), "s", 9, menu: true),
            entry(L("Export PNG"), "e", 9, menu: true), entry(L("Export JPEG"), "s", 11, menu: true),
            entry(L("Close Project"), "w", 1, menu: true), entry(L("Fit Canvas"), "0", 1, menu: true), entry(L("Search Commands"), "f", 1, menu: true),
            entry(L("Actual Pixels"), "1", 1, menu: true), entry(L("Zoom In"), "=", 1, menu: true),
            entry(L("Zoom Out"), "-", 1, menu: true), entry(L("Show Transform Controls"), "h", 1, menu: true),
            entry(L("Hide Compositor"), "h", 3, menu: true), entry(L("Cut"), "x", 1, menu: true),
            entry(L("Copy"), "c", 1, menu: true), entry(L("Copy Merged"), "c", 9, menu: true),
            entry(L("Paste"), "v", 1, menu: true), entry(L("Fill with Foreground"), "\u{7f}", 2, menu: true),
            entry(L("Fill with Background"), "\u{7f}", 1, menu: true), entry(L("Content-Aware Fill"), "\u{7f}", 8, menu: true),
            entry(L("Select All"), "a", 1, menu: true), entry(L("Deselect"), "d", 1, menu: true),
            entry(L("Inverse Selection"), "i", 9, menu: true), entry(L("Select Subject"), "a", 3, menu: true),
            entry(L("Last Filter"), "f", 5, menu: true), entry(L("Curves"), "m", 1, menu: true), entry(L("Levels"), "l", 1, menu: true),
            entry(L("Hue/Saturation"), "u", 1, menu: true), entry(L("Invert Pixels / Mask"), "i", 1, menu: true),
            entry(L("Canvas Size"), "c", 3, menu: true), entry(L("Image Size"), "i", 3, menu: true),
            entry(L("Transform Layer / Selection"), "t", 1, menu: true), entry(L("Duplicate / Layer via Copy"), "j", 1, menu: true),
            entry(L("Toggle Clipping Mask"), "g", 3, menu: true), entry(L("Group Layers"), "g", 1, menu: true),
            entry(L("Ungroup Layers"), "g", 9, menu: true),
            entry(L("New Blank Layer"), "n", 9, menu: true), entry(L("Move Layer Up"), "]", 1, menu: true),
            entry(L("Move Layer Down"), "[", 1, menu: true), entry(L("Merge Layers"), "e", 1, menu: true),
            entry(L("Show Grid"), "'", 1, menu: true), entry(L("Show Guides"), ";", 1, menu: true),
            entry(L("Show Rulers"), "r", 1, menu: true), entry(L("Snap"), ";", 9, menu: true),
            entry(L("Lock Guides"), ";", 3, menu: true)
        ]
        for (title, key) in [(L("Toggle Fullscreen: the canvas alone on black (Esc also leaves)"), "f"), (L("Select tool"), "a"), (L("Move / Transform tool"), "v"), (L("Hand tool"), "h"),
            (L("Zoom tool"), "z"), (L("Brush tool"), "b"), (L("Eraser"), "e"), (L("Spot Healing"), "j"),
            (L("Clone Stamp"), "s"), (L("Type tool"), "t"), (L("Gradient tool"), "g"), (L("Shape tool"), "u"),
            (L("Eyedropper tool"), "i"), (L("Marquee / cycle shape"), "m"), (L("Magic"), "w"),
            (L("Lasso / cycle mode"), "l"), (L("Blur / Smudge / Liquify"), "r"), (L("Crop tool"), "c"),
            (L("Swap foreground/background"), "x"), (L("Reset colors"), "d"), (L("Cycle tool mode"), "\t"),
            (L("Temporary Hand tool (hold)"), " "), (L("Delete selection / layer / effect / lasso point"), "\u{7f}"),
            (L("Apply current canvas operation"), "\r"), (L("Cancel current canvas operation"), "\u{1b}"),
            (L("Decrease brush size"), "["), (L("Increase brush size"), "]")] {
            result.append(entry(title, key))
        }
        result += [entry(L("Decrease brush hardness"), "[", 8), entry(L("Increase brush hardness"), "]", 8),
                   entry(L("Previous blend mode"), "-", 8), entry(L("Next blend mode"), "=", 8),
                   entry(L("Cycle shape kind"), "u", 8)]
        for digit in 0...9 { result.append(entry("不透明度数字 \(digit)（输入两位数字以精确设置百分比）", String(digit))) }
        for (direction, key) in [(L("Left"), "\u{f702}"), (L("Right"), "\u{f703}"), (L("Up"), "\u{f700}"), (L("Down"), "\u{f701}")] {
            result += [entry("向\(direction.localized)微移 1 像素", key), entry("向\(direction.localized)微移 10 像素", key, 8),
                       entry("向\(direction.localized)移动所选像素 1 像素", key, 1), entry("向\(direction.localized)移动所选像素 10 像素", key, 9)]
        }
        result.append(.init(title: L("Finish editing text"), group: L("Text Editing"), original: ShortcutChord("\r", 1)))
        for (title, key) in [(L("Decrease tracking"), "\u{f702}"), (L("Increase tracking"), "\u{f703}"),
                             (L("Decrease leading"), "\u{f700}"), (L("Increase leading"), "\u{f701}")] {
            result.append(.init(title: title, group: L("Text Editing"), original: ShortcutChord(key, 2)))
            result.append(.init(title: title + L(" by 10"), group: L("Text Editing"), original: ShortcutChord(key, 10)))
        }
        result.append(entry(L("Toggle Levels preview"), "p", 2))
        return result
    }()
}

@MainActor @Observable
final class ShortcutSettings {
    static let shared = ShortcutSettings()
    private(set) var overrides: [String: ShortcutChord] = [:]
    @ObservationIgnored private let panel = FloatingPanelController(name: "keyboardShortcuts")
    private static let storageKey = "keyboardShortcuts.v1"
    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode([String: ShortcutChord].self, from: data),
           Self.problem(in: saved) == nil { overrides = saved }
    }
    func chord(_ definition: ShortcutDefinition) -> ShortcutChord { overrides[definition.id] ?? definition.original }
    func menu(_ key: KeyEquivalent, modifiers: EventModifiers) -> ShortcutChord {
        let bits = (modifiers.contains(.command) ? 1 : 0) | (modifiers.contains(.option) ? 2 : 0)
            | (modifiers.contains(.control) ? 4 : 0) | (modifiers.contains(.shift) ? 8 : 0)
        let original = ShortcutChord(String(key.character), bits)
        guard let definition = ShortcutDefinition.all.first(where: { $0.isMenu && $0.original == original }) else { return original }
        return chord(definition)
    }
    func native(_ key: KeyEquivalent, modifiers: EventModifiers = []) -> ShortcutChord {
        let bits = (modifiers.contains(.command) ? 1 : 0) | (modifiers.contains(.option) ? 2 : 0)
            | (modifiers.contains(.control) ? 4 : 0) | (modifiers.contains(.shift) ? 8 : 0)
        let original = ShortcutChord(String(key.character), bits)
        guard let definition = ShortcutDefinition.all.first(where: { !$0.isMenu && $0.original == original }) else { return original }
        return chord(definition)
    }
    func show() {
        panel.show(title: L("Keyboard Shortcuts"), content: KeyboardShortcutsSheet(settings: self))
    }
    func close() { panel.close() }
    func save(_ values: [String: ShortcutChord]) {
        guard Self.problem(in: values) == nil, let data = try? JSONEncoder().encode(values) else { return }
        overrides = values
        UserDefaults.standard.set(data, forKey: Self.storageKey)
        close()
    }
    static func problem(in values: [String: ShortcutChord]) -> String? {
        var assigned: [ShortcutChord: String] = [:]
        for definition in ShortcutDefinition.all {
            let chord = values[definition.id] ?? definition.original
            guard chord.key.count == 1, (0...15).contains(chord.modifiers) else { return L("Choose a single key with optional modifiers.") }
            if definition.group == L("Text Editing"), chord.modifiers & 7 == 0 {
                return L("Text-editing shortcuts need Command, Option, or Control so they do not replace normal typing.")
            }
            if [ShortcutChord("q", 1), ShortcutChord(",", 1), ShortcutChord("m", 3)].contains(chord) {
                return "\(chord.label) 已被 macOS 保留。"
            }
            if let other = assigned[chord] { return "\(chord.label) 同时分配给了“\(other)”和“\(definition.title)”。" }
            assigned[chord] = definition.title
        }
        return nil
    }

    /// Translate only at the existing canvas/layer responder boundary. Native text
    /// fields and dialog controls retain their normal typing and navigation behavior.
    func canvasEvent(_ event: NSEvent) -> NSEvent? {
        guard !overrides.isEmpty else { return event }
        let input = ShortcutChord(event)
        if let definition = ShortcutDefinition.all.first(where: { $0.group == L("Canvas & Layers") && chord($0) == input }) {
            return definition.original == input ? event : definition.original.event(like: event)
        }
        if ShortcutDefinition.all.contains(where: { $0.group != L("Text Editing") && $0.original == input && chord($0) != input }) { return nil }
        // Letter tool shortcuts traditionally also accept Shift. Follow the base
        // assignment unless Shift has its own explicit command (e.g. cycle shape).
        if input.modifiers == 8 {
            let plain = ShortcutChord(input.key)
            if let definition = ShortcutDefinition.all.first(where: { !$0.isMenu && $0.original.modifiers == 0 && chord($0) == plain }) {
                return ShortcutChord(definition.original.key, 8).event(like: event)
            }
            if ShortcutDefinition.all.contains(where: { !$0.isMenu && $0.original == plain && chord($0) != plain }) { return nil }
        }
        return event
    }

    func textEvent(_ event: NSEvent) -> NSEvent? {
        guard !overrides.isEmpty else { return event }
        let definitions = ShortcutDefinition.all.filter { $0.group == L("Text Editing") || $0.original == ShortcutChord("\u{1b}") }
        let input = ShortcutChord(event)
        if let definition = definitions.first(where: { chord($0) == input }) {
            return definition.original == input ? event : definition.original.event(like: event)
        }
        if definitions.contains(where: { $0.original == input && chord($0) != input }) { return nil }
        return event
    }
}

extension View {
    func configuredNativeShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = []) -> some View {
        let chord = ShortcutSettings.shared.native(key, modifiers: modifiers)
        guard let first = chord.key.first else { return keyboardShortcut(key, modifiers: modifiers) }
        return keyboardShortcut(KeyEquivalent(first), modifiers: chord.eventModifiers)
    }
    func configuredKeyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = .command) -> some View {
        let chord = ShortcutSettings.shared.menu(key, modifiers: modifiers)
        guard let first = chord.key.first else { return keyboardShortcut(key, modifiers: modifiers) }
        return keyboardShortcut(KeyEquivalent(first), modifiers: chord.eventModifiers)
    }
}

private struct KeyboardShortcutsSheet: View {
    let settings: ShortcutSettings
    @State private var draft: [String: ShortcutChord]
    @State private var search = ""
    @State private var recording: String?
    init(settings: ShortcutSettings) { self.settings = settings; _draft = State(initialValue: settings.overrides) }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L("Click a shortcut, then press its new key combination. Changes apply when you save."))
                .foregroundStyle(.secondary)
            TextField(L("Search shortcuts"), text: $search).textFieldStyle(.roundedBorder)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach([L("Menus"), L("Canvas & Layers"), L("Text Editing")], id: \.self) { group in
                        Text(group).font(.headline).padding(.top, 8)
                        ForEach(ShortcutDefinition.all.filter { $0.group == group && (search.isEmpty || $0.title.localizedCaseInsensitiveContains(search)) }) { definition in
                            HStack {
                                Text(definition.title)
                                Spacer()
                                ShortcutRecorder(chord: draft[definition.id] ?? definition.original,
                                    recording: recording == definition.id,
                                    start: { recording = definition.id },
                                    finish: { chord in
                                        if let chord { draft[definition.id] = chord }
                                        recording = nil
                                    })
                                    .frame(width: 150, height: 26)
                            }
                        }
                    }
                    Divider().padding(.vertical, 8)
                    Text(L("Contextual keys & mouse gestures")).font(.headline)
                    Text(L("Text fields keep standard macOS editing keys. Dialogs share the Apply/Cancel assignments above. Numeric fields use Up/Down, with Shift for larger steps. Standard macOS commands include ⌘Q to quit and ⌃⌘F for full screen. The shortcut editor itself always uses Return to save and Esc to cancel when not recording."))
                    Text(L("Option temporarily selects the eyedropper in painting tools. Shift constrains shapes/movement or adds to a selection; Option subtracts from selections or draws from center. Command-drag moves selected pixels; Command-Option-drag copies them. Option-drag duplicates layers/folders/effects; Option-click at a layer boundary toggles clipping. Command-click a thumbnail loads its selection. Control bypasses snapping. Right-drag adjusts brush size. Modifier-and-mouse gestures are fixed."))
                }.padding(.trailing, 8)
            }.frame(height: 465)
            // Only a conflict takes room here; an empty line left a wide gap above the buttons.
            if let problem = ShortcutSettings.problem(in: draft) {
                Text(problem)
                    .foregroundStyle(.orange).font(.callout).lineLimit(2)
                    .frame(height: 22, alignment: .topLeading)
            }
            Divider()
            HStack {
                Button(L("Restore Defaults")) { recording = nil; draft = [:] }
                Spacer()
                Button(L("Cancel")) { settings.close() }.keyboardShortcut(.cancelAction)
                Button(L("Save")) { settings.save(draft) }.keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(recording != nil || ShortcutSettings.problem(in: draft) != nil)
            }
        }.padding(24).frame(width: 660).fixedSize()
    }
}

private struct ShortcutRecorder: NSViewRepresentable {
    let chord: ShortcutChord
    let recording: Bool
    let start: () -> Void
    let finish: (ShortcutChord?) -> Void
    func makeNSView(context: Context) -> RecorderButton { RecorderButton() }
    func updateNSView(_ button: RecorderButton, context: Context) {
        button.start = start; button.finish = finish; button.recording = recording
        button.title = recording ? L("Press keys…") : chord.label
        button.setAccessibilityLabel(recording ? L("Press a shortcut") : chord.label)
        if recording, button.window?.firstResponder !== button { button.window?.makeFirstResponder(button) }
    }
    final class RecorderButton: NSButton {
        var start: (() -> Void)?
        var finish: ((ShortcutChord?) -> Void)?
        var recording = false
        override var acceptsFirstResponder: Bool { true }
        init() {
            super.init(frame: .zero)
            bezelStyle = .rounded; target = self; action = #selector(beginRecording)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        @objc private func beginRecording() { window?.makeFirstResponder(self); recording = true; start?() }
        override func performKeyEquivalent(with event: NSEvent) -> Bool {
            guard recording, window?.firstResponder === self else { return super.performKeyEquivalent(with: event) }
            keyDown(with: event); return true
        }
        override func keyDown(with event: NSEvent) {
            guard recording else { super.keyDown(with: event); return }
            let chord = ShortcutChord(event)
            guard chord.key.count == 1 else { NSSound.beep(); return }
            recording = false
            finish?(chord)
            window?.makeFirstResponder(nil)
        }
    }
}
