import Cocoa

public class TomatoBarController: NSViewController {
    /** Is sound enabled flag */
    private var isSoundEnabled: Bool {
        return UserDefaults.standard.bool(forKey: "isSoundEnabled")
    }

    /** Interval length, in minutes */
    private var intervalLength: Int {
        return UserDefaults.standard.integer(forKey: "intervalLength")
    }
    /** Interval length as seconds */
    private var intervalLengthSeconds: Int { return intervalLength * 60 }

    /** Time left, in seconds */
    private var timeLeft: Int = 0
    /** Time left as MM:SS */
    private var timeLeftString: String {
        return String(format: "%.2i:%.2i", timeLeft / 60, timeLeft % 60)
    }
    /** Timer instance */
    private var timer: DispatchSourceTimer?

    /** Status bar item */
    public var statusItem: NSStatusItem?
    /** Status bar button */
    private var statusBarButton: NSButton? {
        return statusItem?.button
    }

    @IBOutlet private var statusMenu: NSMenu!
    @IBOutlet private var touchBarItem: NSTouchBarItem!
    @IBOutlet private var touchBarButton: NSButton!
    @IBOutlet private var startMenuItem: NSMenuItem!
    @IBOutlet private var stopMenuItem: NSMenuItem!
    @IBOutlet private var isSoundEnabledCheckBox: NSButton!

    /* Loaded because of fake view */
    override public func viewDidLoad() {
        super.viewDidLoad()
        /* Register defaults */
        UserDefaults.standard.register(defaults: ["intervalLength": 25,
                                                  "isSoundEnabled": true])

        /* Initialize status bar */
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.alignment = .right
        statusBarButton?.image = NSImage(named: NSImage.Name("BarIcon"))
        statusBarButton?.imagePosition = .imageOnly
        statusItem?.menu = statusMenu

        /* Initialize touch bar, WARNING: uses private framework methods */
        NSTouchBarItem.addSystemTrayItem(touchBarItem)
        DFRElementSetControlStripPresenceForIdentifier(touchBarItem.identifier.rawValue, true)
    }

    /** Called on Touch Bar button and Start and Stop menu items clicks */
    @IBAction private func startStopAction(_ sender: Any) {
        timer == nil ? start() : cancel()
    }

    /** Starts interval */
    private func start() {
        /* Prepare UI */
        touchBarButton.imagePosition = .noImage
        touchBarButton.bezelColor = NSColor.systemGreen
        statusBarButton?.imagePosition = .imageLeft
        swap(&startMenuItem.isHidden, &stopMenuItem.isHidden)
        statusItem?.length = 70

        /* Start timer */
        timeLeft = intervalLengthSeconds
        let queue: DispatchQueue = DispatchQueue(label: "Timer")
        timer = DispatchSource.makeTimerSource(flags: .strict, queue: queue)
        timer?.schedule(deadline: .now(), repeating: .seconds(1), leeway: .never)
        timer?.setEventHandler(handler: self.tick)
        timer?.resume()

        playSound()
    }

    /** Called on interval finish */
    private func finish() {
        sendNotication()
        reset()
        playSound()
    }

    /** Cancels interval */
    private func cancel() {
        reset()
        playSound()
    }

    /** Resets controller to initial state */
    private func reset() {
        /* Reset timer */
        timer?.cancel()
        timer = nil

        /* Reset UI */
        touchBarButton.imagePosition = .imageOnly
        touchBarButton.bezelColor = NSColor.clear
        statusBarButton?.imagePosition = .imageOnly
        swap(&startMenuItem.isHidden, &stopMenuItem.isHidden)
        statusItem?.length = NSStatusItem.variableLength
    }

    /** Called every second by timer */
    private func tick() {
        timeLeft -= 1
        DispatchQueue.main.async {
            if self.timeLeft >= 0 {
                self.touchBarButton.title = self.timeLeftString
                self.statusBarButton?.title = self.timeLeftString
            } else {
                self.finish()
            }
        }
    }

    /** Plays sound */
    private func playSound() {
        guard isSoundEnabled else {
            return
        }
        NSSound.beep()
    }

    /** Sends notification */
    private func sendNotication() {
        let notification: NSUserNotification = NSUserNotification()
        notification.title = "Time's up"
        notification.informativeText = "Keep up the good work!"
        NSUserNotificationCenter.default.deliver(notification)
    }
}
