import Cocoa

let POSE_NAMES = ["pose_idle", "pose_pen", "pose_shush"]

var QUOTES: [String] = [
    "有事打给我。", "这活儿我接。", "听着，这事儿咱们能聊。", "你脸色不对，是遇上事了。", "S'all good, man.",
    "别慌。慌了就输一半。", "先坐，喝点什么。", "我不问你有没有理，我先问你有没有钱。",
    "法律这东西，跟修水管一样，你得知道哪根是通的。", "你别把我想成鲨鱼。我就是池塘里那条小鱼。",
    "我不是好人，但我是站在你这边的坏人。", "你签字那天晚上三点还睁着眼，这就叫风险。", "我认识人。",
    "这事儿我不能保证赢，但我能保证没人比我要价低。", "你先别说话，让我把话说完。",
    "我知道我上回搞砸了。我知道。你先听我说。", "你以为我愿意干这个？", "换你你怎么办？",
    "钱的事好说。难的是你开不了口。", "我这人吧，底线是有的，就是弹性大了点。", "你信我一次。就一次。",
    "我不管你以前干过什么，我只管你以后想干什么。", "他们跟你讲规矩，我跟你讲办法。",
    "你想听真话还是想听好听的？我两种都会说。", "别跟我谈道德，跟我谈条款。",
    "我这辈子最擅长的，就是把不可能变成「再等等」。", "你要是没罪，我让你更没罪。你要是有罪，那咱们聊聊。",
    "你请我，不是因为我便宜。是因为我敢。", "我说话不算数的时候，我会提前告诉你。",
    "你看我像骗子吗？别回答，这问题不好答。", "我哥说我是拿机关枪的猩猩。他不懂，猩猩也分会不会用枪。",
    "我不装体面。体面太贵。", "你给我十分钟，我给你一个说法。",
    "这事儿要是成了，你别忘了是谁给你指的这条路。", "我从不撒谎——我只是把真话说得比较有想象力。",
    "别怕。最坏的结果也就是最坏的结果。", "你要的是赢，不是对。这两样很少一块儿来。",
    "我这种人，最值钱的就是脸皮。", "谈钱伤感情？不谈钱才伤感情。", "你先别签。让我看一眼。就一眼。",
    "我不保证结果。我保证过程里我一直在这儿。", "你信规矩，我信人。人比规矩好说话。",
    "我这人记性不好，但记仇记得清楚。", "你现在这个表情，我见过。上一个这么看我的，后来请我吃了饭。",
    "别把我当律师。把我当个知道门在哪的人。", "咱们不争对错，咱们争时间。",
    "你要真准备好了，就不会来找我。", "我这辈子就学会一件事：怎么在没路的地方踩出一条。",
    "行了，别哭。哭完咱们还得办事。", "有事打给我。没事也可以打，我接。"
]

func loadQuotes() {
    guard let path = Bundle.main.path(forResource: "quotes", ofType: "json"),
          let data = FileManager.default.contents(atPath: path),
          let arr = try? JSONDecoder().decode([String].self, from: data),
          !arr.isEmpty else { return }
    QUOTES = arr
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

    func present(_ text: String, above anchor: NSRect) {
        textLabel.stringValue = text
        textLabel.sizeToFit()
        let padX: CGFloat = 12, padY: CGFloat = 7
        let w = textLabel.frame.width + padX * 2
        let h = textLabel.frame.height + padY * 2
        textLabel.frame = NSRect(x: padX, y: padY, width: textLabel.frame.width, height: textLabel.frame.height)

        let x = anchor.midX - w / 2
        let y = anchor.maxY + 8
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

    let defaults = UserDefaults.standard

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadImages()
        loadQuotes()
        buildWindow()
        buildMenuBar()
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
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
        window.setFrameOrigin(NSPoint(x: vf.maxX - size.width - 28, y: vf.minY + 28))
    }

    func savePosition() {
        defaults.set(window.frame.origin.x, forKey: "petX")
        defaults.set(window.frame.origin.y, forKey: "petY")
    }

    func snapToEdge() {
        guard let screen = NSScreen.main else { return }
        let vf = screen.visibleFrame
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
        speak()
    }

    func speak() {
        guard talkOn else { return }
        let line = QUOTES.randomElement() ?? "有事打给我。"
        bubble.present(line, above: window.frame)
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2.8, repeats: false) { [weak self] _ in
            self?.bubble.dismiss()
        }
    }

    func buildMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        let font = NSFont(name: "Snell Roundhand", size: 15) ?? NSFont.systemFont(ofSize: 14)
        let attr = NSAttributedString(string: "Jimmy McGill", attributes: [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ])
        statusItem.button?.attributedTitle = attr

        let menu = NSMenu()

        let toggle = NSMenuItem(title: "隐藏吉米", action: #selector(togglePet), keyEquivalent: "h")
        toggle.target = self
        menu.addItem(toggle)

        let pose = NSMenuItem(title: "换姿势", action: #selector(changePose), keyEquivalent: "p")
        pose.target = self
        menu.addItem(pose)

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

        let quit = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
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

    @objc func toggleTalk() {
        talkOn = !talkOn
        statusItem.menu?.item(at: 2)?.title = talkOn ? "说话：开" : "说话：关"
    }

    @objc func changePose() {
        poseIndex = (poseIndex + 1) % images.count
        imageView.image = images[poseIndex]
    }

    @objc func grow() { resize(petHeight + 40) }
    @objc func shrink() { resize(petHeight - 40) }
    @objc func quitApp() { savePosition(); NSApp.terminate(nil) }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
