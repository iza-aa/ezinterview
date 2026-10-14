import Cocoa
import SwiftUI
import AVFoundation
import Combine

// MARK: - App State & Data Model
class AppViewModel: ObservableObject {
    @Published var isExpanded: Bool = false
    @Published var answerText: String = ""
    @Published var displayedText: String = ""
    @Published var isAnalyzing: Bool = false
    @Published var statusBadge: String = "Standby"
    @Published var statusColor: Color = .green
    @Published var questionHint: String = "Siap mendengarkan pertanyaan peserta..."
    
    let audioRecorder = AudioRecorder()
    private var fileWatcherTimer: Timer?
    private var typingTimer: Timer?
    private var fullTargetText: String = ""
    private var lastAnswerModified: Date?
    private var cancellables = Set<AnyCancellable>()
    
    let answerFileURL = URL(fileURLWithPath: "/Users/heizaaa/Desktop/cdev/iza-quote/answer.txt")
    let statusFileURL = URL(fileURLWithPath: "/Users/heizaaa/Desktop/cdev/iza-quote/status.json")
    
    init() {
        loadCurrentAnswer()
        startFileWatcher()
        
        // Meneruskan update dari AudioRecorder agar timer detik otomatis merender UI
        audioRecorder.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    func startFileWatcher() {
        // Cek update file jawaban setiap 0.05 detik untuk respons ultra-kilat
        fileWatcherTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.checkAnswerFileUpdate()
        }
    }
    
    func loadCurrentAnswer() {
        if let data = try? String(contentsOf: answerFileURL, encoding: .utf8), !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.answerText = data
            self.displayedText = data
        }
    }
    
    func animateTextStream(to target: String) {
        self.fullTargetText = target
        self.isAnalyzing = false
        self.statusBadge = "Jawaban Mengalir"
        self.statusColor = .blue
        self.isExpanded = true
        
        self.typingTimer?.invalidate()
        
        // Jika teks baru adalah kelanjutan atau perbaikan dari yang sudah ada
        if !target.hasPrefix(self.displayedText) {
            // Jika benar-benar topik baru, reset tampilan
            self.displayedText = ""
        }
        
        let timer = Timer(timeInterval: 0.02, repeats: true) { [weak self] t in
            guard let self = self else { t.invalidate(); return }
            if self.displayedText.count < self.fullTargetText.count {
                let nextLen = min(self.displayedText.count + 4, self.fullTargetText.count)
                let index = self.fullTargetText.index(self.fullTargetText.startIndex, offsetBy: nextLen)
                self.displayedText = String(self.fullTargetText[..<index])
            } else {
                self.displayedText = self.fullTargetText
                self.statusBadge = "Jawaban Siap"
                self.statusColor = .green
                t.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.typingTimer = timer
    }
    
    func checkAnswerFileUpdate() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: answerFileURL.path),
              let modDate = attrs[.modificationDate] as? Date else { return }
        
        if lastAnswerModified == nil {
            lastAnswerModified = modDate
            return
        }
        
        if let last = lastAnswerModified, modDate > last {
            lastAnswerModified = modDate
            if let content = try? String(contentsOf: answerFileURL, encoding: .utf8), !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                DispatchQueue.main.async {
                    self.answerText = content
                    self.animateTextStream(to: content)
                    NSSound(named: "Tink")?.play()
                }
            }
        }
    }
    
    func toggleRecording() {
        if audioRecorder.isRecording {
            // Stop recording
            audioRecorder.stopRecording { [weak self] url in
                guard let self = self else { return }
                self.isAnalyzing = true
                self.displayedText = ""
                self.answerText = ""
                self.statusBadge = "Meracik..."
                self.statusColor = .orange
                self.questionHint = "Antigravity sedang meracik naskah jawaban..."
                self.isExpanded = true
                
                // Write status.json
                self.writeStatus(state: "analyzing")
                
                // Copy notification to clipboard for quick paste if needed
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString("Pertanyaan baru direkam di audio/latest_question.wav. Tolong jawab sesuai materi_presentasi.md", forType: .string)
            }
        } else {
            // Start recording
            audioRecorder.startRecording()
            isAnalyzing = false
            statusBadge = "Merekam..."
            statusColor = .red
            questionHint = "Merekam suara penanya Zoom..."
            writeStatus(state: "recording")
        }
    }
    
    func copyAnswer() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let textToCopy = displayedText.isEmpty ? answerText : displayedText
        pasteboard.setString(textToCopy, forType: .string)
        
        statusBadge = "Tersalin!"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.statusBadge = "Standby"
            self.statusColor = .green
        }
    }
    
    func resetAnswer() {
        typingTimer?.invalidate()
        isAnalyzing = false
        answerText = ""
        displayedText = ""
        statusBadge = "Standby"
        statusColor = .green
        questionHint = "Siap mendengarkan pertanyaan peserta..."
        try? "".write(to: answerFileURL, atomically: true, encoding: .utf8)
        writeStatus(state: "idle")
    }
    
    private func writeStatus(state: String) {
        let json: [String: Any] = [
            "state": state,
            "timestamp": Date().timeIntervalSince1970,
            "audio": audioRecorder.audioOutputURL.path
        ]
        if let data = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
            try? data.write(to: statusFileURL)
        }
    }
}

// MARK: - SwiftUI Main View
struct MainContentView: View {
    @ObservedObject var vm: AppViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar
            
            if vm.isExpanded {
                Divider()
                    .background(Color.white.opacity(0.15))
                
                // Expanded HUD Content
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 6)
        )
        .frame(width: vm.isExpanded ? 440 : 340)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.isExpanded)
        .animation(.easeInOut(duration: 0.2), value: vm.audioRecorder.isRecording)
    }
    
    // Header Bar View
    private var headerBar: some View {
        HStack(spacing: 8) {
            // Drag handle & Status dot
            Circle()
                .fill(vm.audioRecorder.isRecording ? Color.red : vm.statusColor)
                .frame(width: 9, height: 9)
                .shadow(color: (vm.audioRecorder.isRecording ? Color.red : vm.statusColor).opacity(0.6), radius: 3)
            
            Text("iza-quote")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))
            
            Text(vm.statusBadge)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.12)))
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            // Record / Stop Button in Header
            Button(action: {
                vm.toggleRecording()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: vm.audioRecorder.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(vm.audioRecorder.isRecording ? "Selesai (\(vm.audioRecorder.formattedDuration()))" : "Rekam")
                        .font(.system(size: 11, weight: .semibold))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(vm.audioRecorder.isRecording ? Color.red : Color.blue)
                )
                .foregroundColor(.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Toggle Expand Button
            Button(action: {
                withAnimation {
                    vm.isExpanded.toggle()
                }
            }) {
                Image(systemName: vm.isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
            .help(vm.isExpanded ? "Ciutkan" : "Buka Jendela Contekan")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
    
    // Expanded Content View
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Hint text
            HStack {
                Text(vm.questionHint)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                
                Button(action: {
                    vm.copyAnswer()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                        Text("Salin")
                    }
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.15)))
                    .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    vm.resetAnswer()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium))
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.15)))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Bersihkan Contekan")
            }
            .padding(.top, 6)
            
            // Answer Scroll Box
            ScrollView(.vertical, showsIndicators: true) {
                if vm.isAnalyzing {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.1)
                        
                        Text("Mendengarkan rekaman...")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("Whisper & Antigravity sedang meracik naskah...")
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 65)
                    .transition(.opacity)
                } else if vm.displayedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.2))
                        Text("Menunggu pertanyaan...")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    Text(vm.displayedText)
                        .font(.system(size: 13, weight: .regular, design: .default))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        .padding(8)
                        .transition(.opacity)
                }
            }
            .frame(height: 220)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.3))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .padding(.top, 4)
    }
}

// MARK: - Custom Floating Panel with Screen Share Protection
class FloatingPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .titled, .fullSizeContentView, .resizable],
            backing: .buffered,
            defer: false
        )
        
        // 1. ALWAYS ON TOP
        self.level = .floating
        
        // 2. 100% INVISIBLE TO ZOOM SHARE SCREEN / SCREENSHOTS
        self.sharingType = .none
        
        // 3. Stays across macOS Spaces / Full Screen Presentations
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // 4. Borderless glass look
        self.titleVisibility = .hidden
        self.titlebarAppearsTransparent = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.isMovableByWindowBackground = true
        self.hasShadow = false
    }
}

// MARK: - Application Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var panel: FloatingPanel!
    var viewModel = AppViewModel()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let screenRect = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        
        // Position on top-right area (comfortable next to webcam / presentation)
        let initialWidth: CGFloat = 340
        let initialHeight: CGFloat = 360
        let initialX = screenRect.maxX - initialWidth - 30
        let initialY = screenRect.maxY - initialHeight - 30
        
        let rect = NSRect(x: initialX, y: initialY, width: initialWidth, height: initialHeight)
        panel = FloatingPanel(contentRect: rect)
        
        let contentView = MainContentView(vm: viewModel)
        panel.contentView = NSHostingView(rootView: contentView)
        
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()
    }
}

