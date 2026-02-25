import Foundation

final class SettingsManager {
  static let shared = SettingsManager()

  private let defaults = UserDefaults.standard

  private enum Key: String {
    case geminiAPIKey
    case openClawHost
    case openClawPort
    case openClawHookToken
    case openClawGatewayToken
    case geminiSystemPrompt
    case webrtcSignalingURL
    case activeAIBackend
    case autoReconnect
    case showTranscripts
    case enableWakeWord
    case wakePhrase
    case autoEndTimeout
    case ttsVoice
    case activationSound
    case offlineModelURL
  }

  private init() {}

  // MARK: - Gemini

  var geminiAPIKey: String {
    get { defaults.string(forKey: Key.geminiAPIKey.rawValue) ?? Secrets.geminiAPIKey }
    set { defaults.set(newValue, forKey: Key.geminiAPIKey.rawValue) }
  }

  var geminiSystemPrompt: String {
    get { defaults.string(forKey: Key.geminiSystemPrompt.rawValue) ?? GeminiConfig.defaultSystemInstruction }
    set { defaults.set(newValue, forKey: Key.geminiSystemPrompt.rawValue) }
  }

  // MARK: - OpenClaw

  var openClawHost: String {
    get { defaults.string(forKey: Key.openClawHost.rawValue) ?? Secrets.openClawHost }
    set { defaults.set(newValue, forKey: Key.openClawHost.rawValue) }
  }

  var openClawPort: Int {
    get {
      let stored = defaults.integer(forKey: Key.openClawPort.rawValue)
      return stored != 0 ? stored : Secrets.openClawPort
    }
    set { defaults.set(newValue, forKey: Key.openClawPort.rawValue) }
  }

  var openClawHookToken: String {
    get { defaults.string(forKey: Key.openClawHookToken.rawValue) ?? Secrets.openClawHookToken }
    set { defaults.set(newValue, forKey: Key.openClawHookToken.rawValue) }
  }

  var openClawGatewayToken: String {
    get { defaults.string(forKey: Key.openClawGatewayToken.rawValue) ?? Secrets.openClawGatewayToken }
    set { defaults.set(newValue, forKey: Key.openClawGatewayToken.rawValue) }
  }

  // MARK: - WebRTC

  var webrtcSignalingURL: String {
    get { defaults.string(forKey: Key.webrtcSignalingURL.rawValue) ?? Secrets.webrtcSignalingURL }
    set { defaults.set(newValue, forKey: Key.webrtcSignalingURL.rawValue) }
  }

  var activeAIBackend: String {
    get { defaults.string(forKey: Key.activeAIBackend.rawValue) ?? "Gemini Live" }
    set { defaults.set(newValue, forKey: Key.activeAIBackend.rawValue) }
  }

  var autoReconnect: Bool {
    get { defaults.object(forKey: Key.autoReconnect.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.autoReconnect.rawValue) }
  }

  var showTranscripts: Bool {
    get { defaults.object(forKey: Key.showTranscripts.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.showTranscripts.rawValue) }
  }

  var enableWakeWord: Bool {
    get { defaults.object(forKey: Key.enableWakeWord.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.enableWakeWord.rawValue) }
  }

  var wakePhrase: String {
    get { defaults.string(forKey: Key.wakePhrase.rawValue) ?? "Ok Vision" }
    set { defaults.set(newValue, forKey: Key.wakePhrase.rawValue) }
  }

  var autoEndTimeout: Double {
    get {
        let stored = defaults.double(forKey: Key.autoEndTimeout.rawValue)
        return stored != 0 ? stored : 30.0
    }
    set { defaults.set(newValue, forKey: Key.autoEndTimeout.rawValue) }
  }

  var ttsVoice: String {
    get { defaults.string(forKey: Key.ttsVoice.rawValue) ?? "System Default" }
    set { defaults.set(newValue, forKey: Key.ttsVoice.rawValue) }
  }

  var activationSound: Bool {
    get { defaults.object(forKey: Key.activationSound.rawValue) as? Bool ?? true }
    set { defaults.set(newValue, forKey: Key.activationSound.rawValue) }
  }

  var offlineModelURL: String {
    get { defaults.string(forKey: Key.offlineModelURL.rawValue) ?? "https://huggingface.co/bartowski/Llama..." }
    set { defaults.set(newValue, forKey: Key.offlineModelURL.rawValue) }
  }

  // MARK: - Reset

  func resetAll() {
    for key in [Key.geminiAPIKey, .geminiSystemPrompt, .openClawHost, .openClawPort,
                .openClawHookToken, .openClawGatewayToken, .webrtcSignalingURL,
                .activeAIBackend, .autoReconnect, .showTranscripts, .enableWakeWord,
                .wakePhrase, .autoEndTimeout, .ttsVoice, .activationSound, .offlineModelURL] {
      defaults.removeObject(forKey: key.rawValue)
    }
  }
}
