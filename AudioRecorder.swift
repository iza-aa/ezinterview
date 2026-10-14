import Foundation
import AVFoundation
import CoreAudio

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var statusMessage: String = "Standby"
    
    private var engine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var timer: Timer?
    private var startTime: Date?
    
    let audioOutputURL: URL = {
        let folder = URL(fileURLWithPath: "/Users/heizaaa/Desktop/cdev/iza-quote/audio")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("latest_question.wav")
    }()
    
    private func getZoomAudioDeviceID() -> AudioDeviceID? {
        var allDevicesSize = UInt32(0)
        var allDevicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &allDevicesAddress, 0, nil, &allDevicesSize) == noErr else { return nil }
        let count = Int(allDevicesSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: count)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &allDevicesAddress, 0, nil, &allDevicesSize, &deviceIDs) == noErr else { return nil }
        
        for devID in deviceIDs {
            var nameSize = UInt32(256)
            var name = [CChar](repeating: 0, count: 256)
            var nameAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceName,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            if AudioObjectGetPropertyData(devID, &nameAddress, 0, nil, &nameSize, &name) == noErr {
                let devName = String(cString: name)
                if devName.contains("ZoomAudioDevice") {
                    return devID
                }
            }
        }
        return nil
    }
    
    func startRecording() {
        do {
            try? FileManager.default.removeItem(at: audioOutputURL)
            
            let engine = AVAudioEngine()
            let inputNode = engine.inputNode
            
            var usingZoom = false
            if var zoomID = getZoomAudioDeviceID(), let audioUnit = inputNode.audioUnit {
                let status = AudioUnitSetProperty(
                    audioUnit,
                    kAudioOutputUnitProperty_CurrentDevice,
                    kAudioUnitScope_Global,
                    0,
                    &zoomID,
                    UInt32(MemoryLayout<AudioDeviceID>.size)
                )
                if status == noErr {
                    usingZoom = true
                }
            }
            
            let format = inputNode.inputFormat(forBus: 0)
            let audioFile = try AVAudioFile(forWriting: audioOutputURL, settings: format.settings)
            self.audioFile = audioFile
            
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
                try? audioFile.write(from: buffer)
            }
            
            try engine.start()
            self.engine = engine
            self.isRecording = true
            self.startTime = Date()
            self.recordingDuration = 0
            self.statusMessage = usingZoom ? "Merekam suara Zoom..." : "Merekam mikrofon..."
            
            DispatchQueue.main.async {
                self.timer?.invalidate()
                let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
                    guard let self = self, let start = self.startTime else { return }
                    self.recordingDuration = Date().timeIntervalSince(start)
                }
                RunLoop.main.add(t, forMode: .common)
                self.timer = t
            }
        } catch {
            self.statusMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        timer?.invalidate()
        timer = nil
        
        guard let engine = engine, engine.isRunning else {
            isRecording = false
            completion(nil)
            return
        }
        
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        self.engine = nil
        self.audioFile = nil // Flush and close WAV header
        self.isRecording = false
        self.statusMessage = "Audio tersimpan"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            completion(self.audioOutputURL)
        }
    }
    
    func formattedDuration() -> String {
        let totalSeconds = Int(recordingDuration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
