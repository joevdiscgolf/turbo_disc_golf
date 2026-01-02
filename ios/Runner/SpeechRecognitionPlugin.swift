import Flutter
import Speech
import AVFoundation

public class SpeechRecognitionPlugin: NSObject, FlutterPlugin, SFSpeechRecognizerDelegate {
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var methodChannel: FlutterMethodChannel?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.turbo_disc_golf/speech_recognition",
            binaryMessenger: registrar.messenger()
        )
        let instance = SpeechRecognitionPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        instance.methodChannel = channel
    }
    
    public func dummyMethodToEnforceBundling(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        result(nil)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            initializeSpeechRecognition(result: result)
        case "warmUp":
            warmUp(result: result)
        case "startListening":
            startListening(result: result)
        case "stopListening":
            stopListening(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initializeSpeechRecognition(result: @escaping FlutterResult) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                if !granted {
                    result(false)
                    return
                }
                
                SFSpeechRecognizer.requestAuthorization { authStatus in
                    DispatchQueue.main.async {
                        switch authStatus {
                        case .authorized:
                            self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
                            self.speechRecognizer?.delegate = self
                            result(true)
                        default:
                            result(false)
                        }
                    }
                }
            }
        }
    }
    
    private func warmUp(result: @escaping FlutterResult) {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
            
            // Pre-initialize speech recognizer if not already created
            if speechRecognizer == nil {
                speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
                speechRecognizer?.delegate = self
            }
            
            // Request both permissions asynchronously in background
            // (won't show dialogs if already granted)
            DispatchQueue.global(qos: .background).async {
                SFSpeechRecognizer.requestAuthorization { _ in }
                AVAudioSession.sharedInstance().requestRecordPermission { _ in }
            }
            
            result(nil)
        } catch {
            result(nil)
        }
    }
    
    private func startListening(result: @escaping FlutterResult) {
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            sendCallback("onError", arguments: "Speech recognizer not available")
            sendCallback("onListeningStateChanged", arguments: false)
            result(nil)
            return
        }

        // Cancel any existing recognition task
        if let recognitionTask = recognitionTask {
            recognitionTask.cancel()
            self.recognitionTask = nil
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: [])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                sendCallback("onError", arguments: "Failed to create recognition request")
                sendCallback("onListeningStateChanged", arguments: false)
                result(nil)
                return
            }

            recognitionRequest.shouldReportPartialResults = true

            // Stop audio engine if already running
            if audioEngine.isRunning {
                audioEngine.stop()
                audioEngine.inputNode.removeTap(onBus: 0)
                // Small delay to ensure cleanup completes
                usleep(50000) // 50ms
            }

            let inputNode = audioEngine.inputNode
            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, when in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            sendCallback("onListeningStateChanged", arguments: true)

            recognitionTask = recognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                var isFinal = false

                if let result = result {
                    let transcription = result.bestTranscription.formattedString
                    if result.isFinal {
                        isFinal = true
                        self?.sendCallback("onSpeechResult", arguments: transcription)
                    } else {
                        self?.sendCallback("onPartialResult", arguments: transcription)
                    }
                }

                if let error = error {
                    self?.sendCallback("onError", arguments: error.localizedDescription)
                    self?.sendCallback("onListeningStateChanged", arguments: false)
                    self?.stopListeningInternal()
                }

                if error != nil || isFinal {
                    self?.audioEngine.stop()
                    self?.audioEngine.inputNode.removeTap(onBus: 0)
                    self?.recognitionRequest = nil
                    self?.recognitionTask = nil
                    self?.sendCallback("onListeningStateChanged", arguments: false)
                }
            }

            result(nil)
        } catch {
            sendCallback("onError", arguments: "Failed to start listening: \(error.localizedDescription)")
            sendCallback("onListeningStateChanged", arguments: false)
            result(nil)
        }
    }
    
    private func stopListening(result: @escaping FlutterResult) {
        stopListeningInternal()
        result(nil)
    }
    
    private func stopListeningInternal() {
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        sendCallback("onListeningStateChanged", arguments: false)
    }
    
    private func sendCallback(_ method: String, arguments: Any?) {
        DispatchQueue.main.async {
            self.methodChannel?.invokeMethod(method, arguments: arguments)
        }
    }
}