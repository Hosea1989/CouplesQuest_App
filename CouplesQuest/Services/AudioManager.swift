import Foundation
import AVFoundation
import AudioToolbox

/// Centralized audio manager for game sound effects.
/// Uses bundled custom audio files when available, with AudioToolbox system sounds as fallbacks.
final class AudioManager: ObservableObject {
    
    static let shared = AudioManager()
    
    // MARK: - Sound Effects
    
    enum SoundEffect: String, CaseIterable {
        // UI
        case buttonTap       = "sfx_button_tap"
        case tabSwitch       = "sfx_tab_switch"
        
        // Game Actions
        case dungeonStart    = "sfx_dungeon_start"
        case dungeonComplete = "sfx_dungeon_complete"
        case trainingStart   = "sfx_training_start"
        case trainingComplete = "sfx_training_complete"
        
        // Rewards
        case lootDrop        = "sfx_loot_drop"
        case claimReward     = "sfx_claim_reward"
        case equipItem       = "sfx_equip_item"
        case levelUp         = "sfx_level_up"
        
        // Feedback
        case success         = "sfx_success"
        case error           = "sfx_error"
        
        /// Fallback system sound ID when no custom audio file is bundled.
        /// Uses IDs from /System/Library/Audio/UISounds/ that produce audible tones.
        var fallbackSystemSound: SystemSoundID {
            switch self {
            case .buttonTap:        return 1306  // short low knock
            case .tabSwitch:        return 1306  // short low knock
            case .dungeonStart:     return 1304  // alarm-ish start tone
            case .dungeonComplete:  return 1025  // new mail chime
            case .trainingStart:    return 1304  // alarm-ish start tone
            case .trainingComplete: return 1025  // new mail chime
            case .lootDrop:         return 1395  // payment success ding
            case .claimReward:      return 1395  // payment success ding
            case .equipItem:        return 1306  // short low knock
            case .levelUp:          return 1335  // photo shutter (celebratory snap)
            case .success:          return 1394  // SMS tone (pleasant ding)
            case .error:            return 1073  // descending alert tone
            }
        }
    }
    
    // MARK: - State
    
    @Published var isMuted: Bool = false {
        didSet {
            UserDefaults.standard.set(isMuted, forKey: "AudioManager_isMuted")
        }
    }
    
    @Published var volume: Float = 0.7 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "AudioManager_volume")
        }
    }
    
    /// Pre-loaded AVAudioPlayer instances keyed by sound effect name
    private var players: [String: AVAudioPlayer] = [:]
    
    // MARK: - Init
    
    private init() {
        isMuted = UserDefaults.standard.bool(forKey: "AudioManager_isMuted")
        let storedVolume = UserDefaults.standard.float(forKey: "AudioManager_volume")
        volume = storedVolume > 0 ? storedVolume : 0.7
        
        configureAudioSession()
        preloadSounds()
    }
    
    // MARK: - Configuration
    
    private func configureAudioSession() {
        do {
            // .ambient respects the device silent switch
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[AudioManager] Failed to configure audio session: \(error)")
        }
    }
    
    /// Attempt to pre-load any bundled sound files.
    private func preloadSounds() {
        for effect in SoundEffect.allCases {
            // Try .wav first, then .mp3
            if let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav")
                ?? Bundle.main.url(forResource: effect.rawValue, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players[effect.rawValue] = player
                } catch {
                    print("[AudioManager] Could not load \(effect.rawValue): \(error)")
                }
            }
        }
    }
    
    // MARK: - Playback
    
    /// Play a sound effect. Uses bundled file if available, otherwise falls back to system sound.
    func play(_ effect: SoundEffect) {
        guard !isMuted else { return }
        
        if let player = players[effect.rawValue] {
            // Custom audio file exists — use it
            player.volume = volume
            player.currentTime = 0
            player.play()
        } else {
            // Fallback to system sound
            AudioServicesPlaySystemSound(effect.fallbackSystemSound)
        }
    }
}
