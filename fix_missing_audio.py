#!/usr/bin/env python3
"""Regenerate missing placeholder WAV files from the original 43 batch."""

import wave
import struct
import math
import os

OUTPUT_DIR = "CouplesQuest/Resources/Sounds"
SAMPLE_RATE = 44100

ALL_EXPECTED = [
    "fire_crackling.wav", "forest.wav", "night_sounds.wav", "ocean_waves.wav", "rain.wav",
    "sfx_arena_milestone.wav", "sfx_arena_wave_clear.wav", "sfx_arena_wave_horn.wav",
    "sfx_button_tap.wav", "sfx_card_collect.wav", "sfx_card_page_turn.wav",
    "sfx_card_reveal.wav", "sfx_claim_reward.wav", "sfx_dungeon_complete.wav",
    "sfx_dungeon_start.wav", "sfx_equip_item.wav", "sfx_error.wav",
    "sfx_expedition_depart.wav", "sfx_expedition_stage_complete.wav", "sfx_expedition_treasure.wav",
    "sfx_forge_anvil_ring.wav", "sfx_forge_critical.wav", "sfx_forge_crumble.wav",
    "sfx_forge_enhance.wav", "sfx_forge_enhance_fail.wav", "sfx_forge_hammer.wav",
    "sfx_forge_magic_swirl.wav", "sfx_forge_salvage.wav", "sfx_forge_shatter.wav",
    "sfx_level_up.wav", "sfx_loot_drop.wav", "sfx_mismatch.wav", "sfx_partner_paired.wav",
    "sfx_raid_boss_impact.wav", "sfx_raid_boss_roar.wav", "sfx_raid_boss_victory.wav",
    "sfx_research_complete.wav", "sfx_research_node_unlock.wav", "sfx_research_start.wav",
    "sfx_success.wav", "sfx_tab_switch.wav", "sfx_training_complete.wav", "sfx_training_start.wav",
]

def make_placeholder_wav(filename):
    path = os.path.join(OUTPUT_DIR, filename)
    n = int(SAMPLE_RATE * 0.3)
    fade = int(SAMPLE_RATE * 0.01)
    
    # Ambient loops get a longer duration
    is_ambient = not filename.startswith("sfx_")
    if is_ambient:
        n = int(SAMPLE_RATE * 2.0)
    
    freq = 440
    with wave.open(path, 'w') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        for i in range(n):
            env = 1.0
            if i < fade:
                env = i / fade
            elif i > n - fade:
                env = (n - i) / fade
            sample = int(0.5 * 32767 * env * math.sin(2 * math.pi * freq * i / SAMPLE_RATE))
            wf.writeframes(struct.pack('<h', sample))

def main():
    existing = set(os.listdir(OUTPUT_DIR))
    missing = [f for f in ALL_EXPECTED if f not in existing]
    
    if not missing:
        print("All files present!")
        return
    
    print(f"Regenerating {len(missing)} missing placeholder files...")
    for f in missing:
        make_placeholder_wav(f)
        print(f"  Created: {f}")
    print("Done!")

if __name__ == "__main__":
    main()
