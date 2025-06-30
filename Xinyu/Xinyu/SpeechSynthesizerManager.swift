import Foundation
import AVFoundation
import Combine

class SpeechSynthesizerManager: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    private var lastUtteranceId: UUID?
    private var previousAudioCategory: AVAudioSession.Category?
    private var previousAudioMode: AVAudioSession.Mode?
    private var previousAudioOptions: AVAudioSession.CategoryOptions = []
    @Published var isPaused: Bool = false
    
    override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    /// 朗读文本，支持多语言和自定义参数
    func speak(
        text: String,
        language: String = "zh-CN",
        utteranceId: UUID? = nil,
        rate: Float = AVSpeechUtteranceDefaultSpeechRate,
        volume: Float = 1.0,
        pitch: Float = 1.0
    ) {
        print("[TTS] speak: \(text) | language: \(language)")
        // 1. 设置音频会话为播放模式，确保TTS有声音
        setAudioSessionForPlayback()
        stopSpeaking()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.volume = volume
        utterance.pitchMultiplier = pitch
        self.lastUtteranceId = utteranceId
        synthesizer.speak(utterance)
    }
    
    /// 停止朗读
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    /// 设置音频会话为播放模式
    private func setAudioSessionForPlayback() {
        let session = AVAudioSession.sharedInstance()
        do {
            // 记录原有音频会话，便于后续恢复
            previousAudioCategory = session.category
            previousAudioMode = session.mode
            previousAudioOptions = session.categoryOptions
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            print("[TTS] AVAudioSession已设置为playback")
        } catch {
            print("[TTS] AVAudioSession设置失败: \(error)")
        }
    }
    
    /// 恢复音频会话（如有需要）
    func restoreAudioSessionIfNeeded() {
        guard let category = previousAudioCategory, let mode = previousAudioMode else { return }
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(category, mode: mode, options: previousAudioOptions)
            try session.setActive(true)
            print("[TTS] AVAudioSession已恢复为原设置")
        } catch {
            print("[TTS] 恢复AVAudioSession失败: \(error)")
        }
    }
    
    func pauseSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.pauseSpeaking(at: .immediate)
            isPaused = true
        }
    }
    
    func continueSpeaking() {
        if synthesizer.isPaused {
            synthesizer.continueSpeaking()
            isPaused = false
        }
    }
}

extension SpeechSynthesizerManager: AVSpeechSynthesizerDelegate {
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("[TTS] 开始朗读")
        DispatchQueue.main.async {
            self.isSpeaking = true
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("[TTS] 朗读结束")
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        // 朗读结束后可恢复音频会话（如有需要）
        self.restoreAudioSessionIfNeeded()
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("[TTS] 朗读被取消")
        DispatchQueue.main.async {
            self.isSpeaking = false
        }
        self.restoreAudioSessionIfNeeded()
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = true
        }
    }
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        DispatchQueue.main.async {
            self.isPaused = false
        }
    }
} 