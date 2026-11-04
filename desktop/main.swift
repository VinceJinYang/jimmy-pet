import Cocoa

let POSE_NAMES = ["pose_idle", "pose_pen", "pose_shush"]

// (系统字体名, 菜单里显示的名字)。空字符串表示用系统默认字体。
let FONT_CHOICES: [(String, String)] = [
    ("Snell Roundhand", "花体"),
    ("Zapfino", "更花"),
    ("Futura", "现代"),
    ("Courier New", "等宽"),
    ("", "系统"),
]

struct QuoteBook: Decodable {
    let click: [String]
    let idle: [String]
    let sit: [String]
    let sales: [String]?
}

var CLICK: [String] = ["有事打给我。"]
var IDLE: [String] = ["我在。"]
var SIT: [String] = ["起来走两步。"]
var SALES: [String] = []

func loadQuotes() {
    guard let path = Bundle.main.path(forResource: "quotes", ofType: "json"),
          let data = FileManager.default.contents(atPath: path),
          let book = try? JSONDecoder().decode(QuoteBook.self, from: data) else { return }
    if !book.click.isEmpty { CLICK = book.click }
    if !book.idle.isEmpty { IDLE = book.idle }
    if !book.sit.isEmpty { SIT = book.sit }
    if let sales = book.sales, !sales.isEmpty { SALES = sales }
}

final class BubbleWindow: NSWindow {
    let textLabel = NSTextField(labelWithString: "")
    private let box = NSView()

    init() {
        super.init(contentRect: NSRect(x: 0, y: 0, width: 40, height: 24),
                   styleMask: [.borderless], backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

        box.wantsLayer = true
        box.layer?.backgroundColor = NSColor.white.cgColor
        box.layer?.cornerRadius = 10
        box.layer?.masksToBounds = true

        textLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        textLabel.textColor = NSColor(calibratedWhite: 0.12, alpha: 1)
        textLabel.alignment = .center
        textLabel.drawsBackground = false

        box.addSubview(textLabel)
        contentView = box
        alphaValue = 0
    }

    func present(_ text: String, above anchor: NSRect, on screen: NSScreen?) {
        textLabel.stringValue = text
        textLabel.sizeToFit()
        let padX: CGFloat = 12, padY: CGFloat = 7
        let w = textLabel.frame.width + padX * 2
        let h = textLabel.frame.height + padY * 2
        textLabel.frame = NSRect(x: padX, y: padY,
                                 width: textLabel.frame.width,
                                 height: textLabel.frame.height)

        var x = anchor.midX - w / 2
        var y = anchor.maxY + 8

        if let vf = (screen ?? NSScreen.main)?.visibleFrame {
            if y + h > vf.maxY { y = anchor.minY - h - 8 }
            x = min(max(x, vf.minX + 6), vf.maxX - w - 6)
            y = min(max(y, vf.minY + 6), vf.maxY - h - 6)
        }

        setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
        box.frame = NSRect(x: 0, y: 0, width: w, height: h)

        alphaValue = 1
        orderFrontRegardless()
    }

    func dismiss() {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            animator().alphaValue = 0
        } completionHandler: { [weak self] in
            self?.orderOut(nil)
        }
    }
}

final class PetView: NSView {
    var onTap: (() -> Void)?
    var onDragEnd: (() -> Void)?
    private var dragOrigin: NSPoint?
    private var didMove = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        dragOrigin = NSEvent.mouseLocation
        didMove = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let origin = dragOrigin, let win = window else { return }
        let now = NSEvent.mouseLocation
        let dx = now.x - origin.x
        let dy = now.y - origin.y
        if abs(dx) + abs(dy) > 2 { didMove = true }
        var f = win.frame
        f.origin.x += dx
        f.origin.y += dy
        win.setFrame(f, display: false)
        dragOrigin = now
    }

    override func mouseUp(with event: NSEvent) {
        if didMove { onDragEnd?() } else { onTap?() }
        dragOrigin = nil
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var imageView: NSImageView!
    var statusItem: NSStatusItem!
    var bubble = BubbleWindow()
    var poseIndex = 0
    var petHeight: CGFloat = 190
    var images: [NSImage] = []
    var talkOn = true
    var hideTimer: Timer?
    var sitTimer: Timer?
    var idleTimer: Timer?
    var fontIndex = 0
    var menuTitle = "Jimmy McGill"

    let defaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadImages()
        loadQuotes()
        if let saved = defaults.string(forKey: "menuTitle"), !saved.isEmpty {
            menuTitle = saved
        }
        let savedFont = defaults.string(forKey: "menuFontKey") ?? "Snell Roundhand"
        if let idx = FONT_CHOICES.firstIndex(where: { $0.0.lowercased() == savedFont.lowercased() || $0.1.lowercased() == savedFont.lowercased() }) {
            fontIndex = idx
        }
        buildWindow()
        buildMenuBar()
        startTimers()
    }

    func loadImages() {
        for name in POSE_NAMES {
            if let path = Bundle.main.path(forResource: name, ofType: "png"),
               let img = NSImage(contentsOfFile: path) {
                images.append(img)
            }
        }
        if images.isEmpty {
            let alert = NSAlert()
            alert.messageText = "找不到姿势图片"
            alert.informativeText = "请确认 JimmyPet.app/Contents/Resources 里有 pose_*.png"
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func buildWindow() {
        let savedH = defaults.double(forKey: "petHeight")
        if savedH > 0 { petHeight = max(90, min(320, savedH)) }
        let w = petHeight * 192.0 / 208.0
        let rect = NSRect(x: 0, y: 0, width: w, height: petHeight)

        window = NSWindow(contentRect: rect,
                          styleMask: [.borderless],
                          backing: .buffered,
                          defer: false)
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isMovableByWindowBackground = false

        let view = PetView(frame: rect)
        view.wantsLayer = true
        view.onTap = { [weak self] in self?.tap() }
        view.onDragEnd = { [weak self] in self?.snapToEdge() }

        imageView = NSImageView(frame: rect)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.image = images[0]
        view.addSubview(imageView)

        window.contentView = view
        restorePosition()
        window.orderFrontRegardless()
    }

    func restorePosition() {
        let x = defaults.double(forKey: "petX")
        let y = defaults.double(forKey: "petY")
        let size = window.frame.size
        if defaults.object(forKey: "petX") != nil {
            let candidate = NSRect(x: x, y: y, width: size.width, height: size.height)
            if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(candidate) }) {
                window.setFrame(candidate, display: false)
                return
            }
        }
        let screen = window.screen ?? NSScreen.main
        guard let vf = screen?.visibleFrame else { return }
        window.setFrameOrigin(NSPoint(x: vf.maxX - size.width - 28, y: vf.minY + 28))
    }

    func savePosition() {
        defaults.set(window.frame.origin.x, forKey: "petX")
        defaults.set(window.frame.origin.y, forKey: "petY")
    }

    func snapToEdge() {
        let screen = window.screen ?? NSScreen.main
        guard let vf = screen?.visibleFrame else { return }
        var f = window.frame
        let threshold: CGFloat = 28

        if abs(f.minX - vf.minX) < threshold { f.origin.x = vf.minX }
        if abs(f.maxX - vf.maxX) < threshold { f.origin.x = vf.maxX - f.width }
        if abs(f.minY - vf.minY) < threshold { f.origin.y = vf.minY }
        if abs(f.maxY - vf.maxY) < threshold { f.origin.y = vf.maxY - f.height }

        if f.origin != window.frame.origin {
            window.setFrame(f, display: true, animate: true)
        }
        savePosition()
    }

    func resize(_ h: CGFloat) {
        petHeight = max(90, min(320, h))
        defaults.set(petHeight, forKey: "petHeight")
        let w = petHeight * 192.0 / 208.0
        var f = window.frame
        let right = f.maxX
        let bottom = f.minY
        f.size = NSSize(width: w, height: petHeight)
        f.origin = NSPoint(x: right - w, y: bottom)
        window.setFrame(f, display: true)
        imageView.frame = NSRect(x: 0, y: 0, width: w, height: petHeight)
        savePosition()
    }

    func tap() {
        poseIndex = (poseIndex + 1) % images.count
        imageView.image = images[poseIndex]
        if !SALES.isEmpty && Bool.random() {
            say(SALES)
        } else {
            say(CLICK)
        }
    }

    func say(_ lines: [String]) {
        guard talkOn else { return }
        let line = lines.randomElement() ?? "有事打给我。"
        bubble.present(line, above: window.frame, on: window.screen)
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: false) { [weak self] _ in
            self?.bubble.dismiss()
        }
    }

    func startTimers() {
        sitTimer = Timer.scheduledTimer(withTimeInterval: 45 * 60, repeats: true) { [weak self] _ in
            guard let self, self.window.isVisible else { return }
            self.say(SIT)
        }
        idleTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: true) { [weak self] _ in
            guard let self, self.talkOn, self.window.isVisible else { return }
            if Double.random(in: 0...1) < 0.18 { self.say(IDLE) }
        }
    }

    func applyMenuFont() {
        let choice = FONT_CHOICES[fontIndex]
        let size: CGFloat = choice.0.isEmpty ? 13 : 15
        let font = NSFont(name: choice.0, size: size) ?? NSFont.systemFont(ofSize: 13)
        let attr = NSAttributedString(string: menuTitle, attributes: [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ])
        statusItem.button?.attributedTitle = attr
        defaults.set(choice.0, forKey: "menuFontKey")
        if let item = statusItem.menu?.item(at: 2) {
            item.title = "换字体：" + choice.1
        }
    }

    func buildMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let menu = NSMenu()

        let toggle = NSMenuItem(title: "隐藏吉米", action: #selector(togglePet), keyEquivalent: "h")
        toggle.target = self
        menu.addItem(toggle)

        let pose = NSMenuItem(title: "换姿势", action: #selector(changePose), keyEquivalent: "p")
        pose.target = self
        menu.addItem(pose)

        let fontItem = NSMenuItem(title: "换字体", action: #selector(cycleFont), keyEquivalent: "f")
        fontItem.target = self
        menu.addItem(fontItem)

        let titleItem = NSMenuItem(title: "改名字…", action: #selector(editTitle), keyEquivalent: "n")
        titleItem.target = self
        menu.addItem(titleItem)

        let talk = NSMenuItem(title: "说话：开", action: #selector(toggleTalk), keyEquivalent: "t")
        talk.target = self
        menu.addItem(talk)

        menu.addItem(NSMenuItem.separator())

        let bigger = NSMenuItem(title: "大一点", action: #selector(grow), keyEquivalent: "+")
        bigger.target = self
        menu.addItem(bigger)

        let smaller = NSMenuItem(title: "小一点", action: #selector(shrink), keyEquivalent: "-")
        smaller.target = self
        menu.addItem(smaller)

        menu.addItem(NSMenuItem.separator())

        let about = NSMenuItem(title: "关于 Jimmy McGill", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)

        let quit = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
        applyMenuFont()
    }

    @objc func togglePet() {
        if window.isVisible {
            window.orderOut(nil)
            bubble.orderOut(nil)
            statusItem.menu?.item(at: 0)?.title = "显示吉米"
        } else {
            window.orderFrontRegardless()
            statusItem.menu?.item(at: 0)?.title = "隐藏吉米"
        }
    }

    @objc func editTitle() {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.messageText = "菜单栏显示什么"
        alert.informativeText = "随便写。留空就恢复成 Jimmy McGill。"
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = menuTitle
        field.placeholderString = "Jimmy McGill"
        alert.accessoryView = field
        alert.addButton(withTitle: "好")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn {
            let v = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            menuTitle = v.isEmpty ? "Jimmy McGill" : v
            defaults.set(menuTitle, forKey: "menuTitle")
            applyMenuFont()
        }
    }

    @objc func cycleFont() {
        fontIndex = (fontIndex + 1) % FONT_CHOICES.count
        applyMenuFont()
    }

    @objc func toggleTalk() {
        talkOn = !talkOn
        statusItem.menu?.item(withTitle: talkOn ? "说话：关" : "说话：开")?.title = talkOn ? "说话：关" : "说话：开"
    }

    @objc func changePose() {
        poseIndex = (poseIndex + 1) % images.count
        imageView.image = images[poseIndex]
    }

    @objc func grow() { resize(petHeight + 40) }
    @objc func shrink() { resize(petHeight - 40) }

    @objc func showAbout() {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let alert = NSAlert()
        alert.messageText = "Jimmy McGill v\(v)"
        alert.informativeText = """
        从《风骚律师》来的像素桌宠。

        点一下：换姿势 + 说一句
        按住拖：移动，靠近屏幕边缘会吸住
        每 45 分钟提醒你起身

        台词共 \(CLICK.count + IDLE.count + SIT.count + SALES.count) 条。
        """
        alert.runModal()
    }

    @objc func quitApp() { savePosition(); NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
