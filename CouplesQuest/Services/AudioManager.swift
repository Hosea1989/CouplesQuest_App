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
        
        // Forge
        case forgeHammer     = "sfx_forge_hammer"
        case forgeAnvilRing  = "sfx_forge_anvil_ring"
        case forgeShatter    = "sfx_forge_shatter"
        case forgeCrumble    = "sfx_forge_crumble"
        case forgeMagicSwirl = "sfx_forge_magic_swirl"
        case forgeSalvage    = "sfx_forge_salvage"
        case forgeEnhance    = "sfx_forge_enhance"
        case forgeEnhanceFail = "sfx_forge_enhance_fail"
        case forgeCritical   = "sfx_forge_critical"
        
        // Cards
        case cardReveal      = "sfx_card_reveal"
        case cardCollect     = "sfx_card_collect"
        case cardPageTurn    = "sfx_card_page_turn"
        
        // Arena
        case arenaWaveHorn       = "sfx_arena_wave_horn"
        case arenaWaveClear      = "sfx_arena_wave_clear"
        case arenaMilestone      = "sfx_arena_milestone"
        
        // Raid Boss
        case raidBossImpact      = "sfx_raid_boss_impact"
        case raidBossRoar        = "sfx_raid_boss_roar"
        case raidBossVictory     = "sfx_raid_boss_victory"
        
        // Research
        case researchStart       = "sfx_research_start"
        case researchComplete    = "sfx_research_complete"
        case researchNodeUnlock  = "sfx_research_node_unlock"
        
        // Expeditions
        case expeditionDepart        = "sfx_expedition_depart"
        case expeditionStageComplete = "sfx_expedition_stage_complete"
        case expeditionTreasure      = "sfx_expedition_treasure"
        
        // Partner
        case partnerPaired       = "sfx_partner_paired"
        
        // Feedback
        case success         = "sfx_success"
        case error           = "sfx_error"
        case mismatch        = "sfx_mismatch"
        
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
            case .forgeHammer:      return 1306  // short knock (hammer strike)
            case .forgeAnvilRing:   return 1025  // chime (anvil ring)
            case .forgeShatter:     return 1073  // descending alert (break)
            case .forgeCrumble:     return 1073  // descending alert (crumble)
            case .forgeMagicSwirl:  return 1032  // bloom tone (magic)
            case .forgeSalvage:     return 1306  // knock (dismantle)
            case .forgeEnhance:     return 1395  // payment ding (enhance success)
            case .forgeEnhanceFail: return 1073  // descending alert (enhance fail)
            case .forgeCritical:    return 1335  // photo shutter (critical moment)
            case .cardReveal:       return 1032  // bloom tone (magical reveal)
            case .cardCollect:      return 1395  // payment success ding (collection chime)
            case .cardPageTurn:     return 1306  // short low knock (page flip)
            // Arena
            case .arenaWaveHorn:    return 1304  // alarm-ish start (horn)
            case .arenaWaveClear:   return 1394  // pleasant ding (clear sting)
            case .arenaMilestone:   return 1335  // celebratory snap (fanfare)
            // Raid Boss
            case .raidBossImpact:   return 1306  // low knock (heavy impact)
            case .raidBossRoar:     return 1073  // descending alert (roar)
            case .raidBossVictory:  return 1025  // new mail chime (victory)
            // Research
            case .researchStart:     return 1304  // alarm-ish start (begin research)
            case .researchComplete:  return 1025  // new mail chime (research done)
            case .researchNodeUnlock: return 1335 // celebratory snap (node unlocked)
            // Expeditions
            case .expeditionDepart:        return 1304  // alarm-ish start (departure horn)
            case .expeditionStageComplete: return 1394  // pleasant ding (stage complete)
            case .expeditionTreasure:      return 1335  // celebratory snap (treasure chest)
            // Partner
            case .partnerPaired:    return 1335  // photo shutter (celebratory snap)
            // Feedback
            case .success:          return 1394  // SMS tone (pleasant ding)
            case .error:            return 1073  // descending alert tone
            case .mismatch:         return 1057  // gentle soft tone (wrong pair)
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
    
    // MARK: - Meditation Bell Sounds
    
    /// Curated iOS system sounds suitable for meditation ending bells
    enum MeditationBell: String, CaseIterable, Identifiable {
        case none      = "none"
        case vibrate   = "vibrate"
        case chime     = "chime"
        case glass     = "glass"
        case bloom     = "bloom"
        case calypso   = "calypso"
        case bellTower = "bell_tower"
        case zen       = "zen"
        
        var id: String { rawValue }
        
        /// Human-readable display name
        var displayName: String {
            switch self {
            case .none:      return "None"
            case .vibrate:   return "Vibrate"
            case .chime:     return "Chime"
            case .glass:     return "Glass"
            case .bloom:     return "Bloom"
            case .calypso:   return "Calypso"
            case .bellTower: return "Bell Tower"
            case .zen:       return "Zen"
            }
        }
        
        /// SF Symbol icon for the bell picker
        var icon: String {
            switch self {
            case .none:      return "speaker.slash.fill"
            case .vibrate:   return "iphone.radiowaves.left.and.right"
            case .chime:     return "bell.fill"
            case .glass:     return "wineglass.fill"
            case .bloom:     return "sparkle"
            case .calypso:   return "music.note"
            case .bellTower: return "building.columns.fill"
            case .zen:       return "leaf.fill"
            }
        }
        
        /// iOS system sound ID (0 for none/vibrate)
        var systemSoundID: SystemSoundID {
            switch self {
            case .none:      return 0
            case .vibrate:   return SystemSoundID(kSystemSoundID_Vibrate)
            case .chime:     return 1025  // new mail chime
            case .glass:     return 1029  // glass tap
            case .bloom:     return 1032  // bloom tone
            case .calypso:   return 1033  // calypso tone
            case .bellTower: return 1016  // anticipate bell
            case .zen:       return 1013  // short zen tone
            }
        }
        
        /// Load saved ending bell selection from UserDefaults, or return default
        static var savedEnding: MeditationBell {
            let raw = UserDefaults.standard.string(forKey: "Meditation_bell") ?? "chime"
            return MeditationBell(rawValue: raw) ?? .chime
        }
        
        /// Load saved starting bell selection from UserDefaults, or return default
        static var savedStarting: MeditationBell {
            let raw = UserDefaults.standard.string(forKey: "Meditation_startingBell") ?? "none"
            return MeditationBell(rawValue: raw) ?? .none
        }
        
        /// Legacy accessor for backward compatibility
        static var saved: MeditationBell { savedEnding }
        
        /// Persist this bell as the user's ending bell selection
        func saveAsEnding() {
            UserDefaults.standard.set(rawValue, forKey: "Meditation_bell")
        }
        
        /// Persist this bell as the user's starting bell selection
        func saveAsStarting() {
            UserDefaults.standard.set(rawValue, forKey: "Meditation_startingBell")
        }
        
        /// Legacy save (ending bell)
        func save() { saveAsEnding() }
    }
    
    // MARK: - Ambient Sounds
    
    /// Ambient background sounds for meditation sessions
    enum AmbientSound: String, CaseIterable, Identifiable {
        case none         = "none"
        case oceanWaves   = "ocean_waves"
        case rain         = "rain"
        case forest       = "forest"
        case fireCrackling = "fire_crackling"
        case nightSounds  = "night_sounds"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .none:          return "None"
            case .oceanWaves:    return "Ocean Waves"
            case .rain:          return "Rain"
            case .forest:        return "Forest"
            case .fireCrackling: return "Fire Crackling"
            case .nightSounds:   return "Night Sounds"
            }
        }
        
        var icon: String {
            switch self {
            case .none:          return "speaker.slash"
            case .oceanWaves:    return "water.waves"
            case .rain:          return "cloud.rain.fill"
            case .forest:        return "tree.fill"
            case .fireCrackling: return "flame.fill"
            case .nightSounds:   return "moon.stars.fill"
            }
        }
        
        /// Load saved selection from UserDefaults
        static var saved: AmbientSound {
            let raw = UserDefaults.standard.string(forKey: "Meditation_ambientSound") ?? "none"
            return AmbientSound(rawValue: raw) ?? .none
        }
        
        func save() {
            UserDefaults.standard.set(rawValue, forKey: "Meditation_ambientSound")
        }
    }
    
    // MARK: - Interval Bell Options
    
    /// How often interval bells ring during a meditation session
    enum IntervalBellOption: String, CaseIterable, Identifiable {
        case none       = "none"
        case every1Min  = "every_1_min"
        case every2Min  = "every_2_min"
        case every5Min  = "every_5_min"
        case every10Min = "every_10_min"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .none:       return "None"
            case .every1Min:  return "Every 1 min"
            case .every2Min:  return "Every 2 min"
            case .every5Min:  return "Every 5 min"
            case .every10Min: return "Every 10 min"
            }
        }
        
        /// Interval in seconds (0 for none)
        var intervalSeconds: Int {
            switch self {
            case .none:       return 0
            case .every1Min:  return 60
            case .every2Min:  return 120
            case .every5Min:  return 300
            case .every10Min: return 600
            }
        }
        
        /// Load saved selection from UserDefaults
        static var saved: IntervalBellOption {
            let raw = UserDefaults.standard.string(forKey: "Meditation_intervalBell") ?? "none"
            return IntervalBellOption(rawValue: raw) ?? .none
        }
        
        func save() {
            UserDefaults.standard.set(rawValue, forKey: "Meditation_intervalBell")
        }
    }
    
    // MARK: - Ambient Sound Playback
    
    private var ambientPlayer: AVAudioPlayer?
    
    /// Start playing an ambient sound on a loop
    func playAmbientSound(_ sound: AmbientSound) {
        stopAmbientSound()
        guard sound != .none else { return }
        
        // Try to load bundled audio file
        if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3")
            ?? Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1 // loop indefinitely
                player.volume = volume * 0.5 // ambient is quieter
                player.prepareToPlay()
                player.play()
                ambientPlayer = player
            } catch {
                print("[AudioManager] Could not play ambient sound \(sound.rawValue): \(error)")
            }
        }
        // If no bundled file, ambient sound is silently unavailable
    }
    
    /// Fade out and stop ambient sound
    func stopAmbientSound(fadeDuration: TimeInterval = 1.0) {
        guard let player = ambientPlayer else { return }
        
        let fadeSteps = 20
        let stepDuration = fadeDuration / Double(fadeSteps)
        let volumeStep = player.volume / Float(fadeSteps)
        
        // Simple fade-out using a dispatch queue
        for step in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(step)) { [weak player] in
                player?.volume -= volumeStep
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeDuration) { [weak self] in
            self?.ambientPlayer?.stop()
            self?.ambientPlayer = nil
        }
    }
    
    // MARK: - Bell Playback
    
    /// Play a meditation bell sound
    func playBell(_ bell: MeditationBell) {
        switch bell {
        case .none:
            break
        case .vibrate:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        default:
            AudioServicesPlaySystemSound(bell.systemSoundID)
        }
    }
    
    /// Preview a meditation bell sound (always plays, even if muted, for picker feedback)
    func previewBell(_ bell: MeditationBell) {
        switch bell {
        case .none:
            break
        case .vibrate:
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
        default:
            AudioServicesPlaySystemSound(bell.systemSoundID)
        }
    }
}
