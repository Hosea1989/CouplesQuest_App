# CouplesQuest SFX Placement Guide

Every sound slot in the app and what it needs.

## How It Works

AudioManager loads any `.wav` or `.mp3` file from the bundle whose filename matches
the `SoundEffect` raw value. Files go inside:

```
CouplesQuest/Resources/Sounds/<subfolder>/
```

**Steps for each sound:**
1. Pick a source file from the candidates listed below
2. Copy it into the correct subfolder under `Resources/Sounds/`
3. Rename it to the exact `sfx_` filename shown
4. In Xcode, drag the file into the matching group so it's added to the target

## Longer Tracks / Songs

Some files (especially victory fanfares, jingles) may be full-length songs.
The app now auto-clips them with a fade-out via `maxDuration`:

```swift
AudioManager.shared.play(.victoryFanfare, maxDuration: 3.5)
```

**Current defaults already set in code:**

| Sound | Max duration | Where |
|---|---|---|
| `victoryFanfare` | 3.5s | DungeonRunView, ArenaView, ExpeditionView |
| `defeatSting` | 2.5s | DungeonRunView, ArenaView |
| `splashIntro` | 3.0s | SplashScreenView |

Tweak the number at the call site after dropping in your audio to find the sweet spot.

---

## MISSING -- No Audio File Yet (12 slots)

These exist in code but play a system fallback beep. Each needs a `.wav` file.

---

### 1. `sfx_victory_fanfare.wav`
**Used when:** Dungeon cleared, Arena conquered, Expedition complete
**Put in:** `Resources/Sounds/Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Encounter_1.wav` | Jingles_Fanfares / Battle |
| b | `Encounter_2.wav` | Jingles_Fanfares / Battle |
| c | `Encounter_3.wav` | Jingles_Fanfares / Battle |
| d | `The Victory.wav` | Hints Stars Points and Rewards |
| e | `Success_2.wav` | Jingles_Fanfares / Puzzle_Minigame |
| f | `Puzzle_Solved.wav` | Jingles_Fanfares / Puzzle_Minigame |
| g | `06 - Victory!.ogg/.wav` | xDeviruchi 16 bit Fantasy |
| h | `Royal Declaration 2.wav` | Hints Stars Points and Rewards |
| i | `Royal Declaration Coin.wav` | Hints Stars Points and Rewards |

---

### 2. `sfx_defeat_sting.wav`
**Used when:** Dungeon failed, Arena defeat
**Put in:** `Resources/Sounds/Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Defeat.wav` | Jingles_Fanfares / Battle |
| b | `Game_Over.wav` | Jingles_Fanfares / Battle |
| c | `Failure.wav` | Jingles_Fanfares / Puzzle_Minigame |
| d | `Quest_Failed.wav` | Jingles_Fanfares / Quest |
| e | `Retro Star Descending 1.wav` | Hints Stars Points and Rewards |
| f | `Retro Star Descending 2.wav` | Hints Stars Points and Rewards |
| g | `Marimba 3 Notes Descend.wav` | Hints Stars Points and Rewards |

---

### 3. `sfx_reward_jingle.wav`
**Used when:** Loot reveals, daily login claim
**Put in:** `Resources/Sounds/Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Shimmery Reward 1.wav` | Hints Stars Points and Rewards |
| b | `Shimmery Reward 2.wav` | Hints Stars Points and Rewards |
| c | `Shimmery Reward 4.wav` | Hints Stars Points and Rewards |
| d | `Shimmery Reward 5.wav` | Hints Stars Points and Rewards |
| e | `Magic Score 1 Enhanced.wav` | Hints Stars Points and Rewards |
| f | `Cosmic Reveal.wav` | Hints Stars Points and Rewards |
| g | `Discovery 2.wav` | Hints Stars Points and Rewards |
| h | `Harp Money 1.wav` | Hints Stars Points and Rewards |
| i | `Harp Money 2.wav` | Hints Stars Points and Rewards |
| j | `DES Reward 1.wav` | Coins And Gems / Designed |
| k | `DES Reward 2.wav` | Coins And Gems / Designed |
| l | `DES Reward 3.wav` | Coins And Gems / Designed |
| m | `Legendary_Drop.wav` | Inventory_SFX / Drops |
| n | `Rare_Drop.wav` | Inventory_SFX / Drops |
| o | `Special_Item_Found.wav` | Jingles_Fanfares / Secrets |
| p | `Small_Secret.wav` | Jingles_Fanfares / Secrets |

---

### 4. `sfx_coin_collect.wav`
**Used when:** Gold counter animations
**Put in:** `Resources/Sounds/Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Bell Coin Reward.wav` | Hints Stars Points and Rewards |
| b | `Marimba Coin.wav` | Hints Stars Points and Rewards |
| c | `Coin Handful.wav` | Hints Stars Points and Rewards |
| d | `Cosmic Coin.wav` | Hints Stars Points and Rewards |
| e | `Mellow Hint Coin.wav` | Hints Stars Points and Rewards |
| f | `Simple Jar Coin.wav` | Hints Stars Points and Rewards |
| g | `Shimmer Jar Coin.wav` | Hints Stars Points and Rewards |
| h | `Positive Vibes Coin.wav` | Hints Stars Points and Rewards |
| i | `Mysterious Chapter Coin.wav` | Hints Stars Points and Rewards |
| j | `Retro Star Coins.wav` | Hints Stars Points and Rewards |
| k | `Falling Penny.wav` | Hints Stars Points and Rewards |
| l | `DES Magic Coin 1.wav` | Coins And Gems / Designed |
| m | `DES Magic Coin 2.wav` | Coins And Gems / Designed |
| n | `DES Swoosh Coin 1.wav` | Coins And Gems / Designed |
| o | `Holy Coins 1.wav` | Coins And Gems / Designed |
| p | `Coin 1.wav` -- `Coin 21.wav` | Coins And Gems / Basic / Coins |
| q | `Bell Coin 2.wav` -- `Bell Coin 6.wav` | Coins And Gems / Basic / Coins |

---

### 5. `sfx_stage_complete.wav`
**Used when:** Expedition stage transitions
**Put in:** `Resources/Sounds/Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Checkpoint 2.wav` | Hints Stars Points and Rewards |
| b | `Marimba Completed.wav` | Hints Stars Points and Rewards |
| c | `Marimba 3 Notes Ascend.wav` | Hints Stars Points and Rewards |
| d | `Score Point 1.wav` | Hints Stars Points and Rewards |
| e | `Score Point 2.wav` | Hints Stars Points and Rewards |
| f | `Score Point 3.wav` | Hints Stars Points and Rewards |
| g | `Score Point 4.wav` | Hints Stars Points and Rewards |
| h | `Brightest Star 1.wav` | Hints Stars Points and Rewards |
| i | `Minigame_End.wav` | Jingles_Fanfares / Puzzle_Minigame |
| j | `Save_Point.wav` | Jingles_Fanfares / UI |

---

### 6. `sfx_arena_wave_horn.wav`
**Used when:** New arena wave starts
**Put in:** `Resources/Sounds/Arena & Raid Boss/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `54_Encounter_01.wav` | 90_RPG_Battle_SFX |
| b | `55_Encounter_02.wav` | 90_RPG_Battle_SFX |
| c | `56_Encounter_03.wav` | 90_RPG_Battle_SFX |
| d | `57_Encounter_04.wav` | 90_RPG_Battle_SFX |
| e | `58_Encounter_05.wav` | 90_RPG_Battle_SFX |
| f | `Round_Start.wav` | Jingles_Fanfares / Round |
| g | `Drums_1.wav` | Jingles_Fanfares / Drums |
| h | `Drums_3.wav` | Jingles_Fanfares / Drums |

---

### 7. `sfx_arena_wave_clear.wav`
**Used when:** Arena wave cleared
**Put in:** `Resources/Sounds/Arena & Raid Boss/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Score Point 1.wav` | Hints Stars Points and Rewards |
| b | `Score Point 2.wav` | Hints Stars Points and Rewards |
| c | `Score Point 3.wav` | Hints Stars Points and Rewards |
| d | `Score Point 4.wav` | Hints Stars Points and Rewards |
| e | `Brightest Star 1.wav` | Hints Stars Points and Rewards |
| f | `Solo Shimmer 1.wav` | Hints Stars Points and Rewards |
| g | `Solo Shimmer 2.wav` | Hints Stars Points and Rewards |
| h | `Marimba 3 Notes Ascend.wav` | Hints Stars Points and Rewards |

---

### 8. `sfx_arena_milestone.wav`
**Used when:** Arena milestone reached (wave 10, 25, etc.)
**Put in:** `Resources/Sounds/Arena & Raid Boss/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Retro Star 1.wav` | Hints Stars Points and Rewards |
| b | `Retro Star 2.wav` | Hints Stars Points and Rewards |
| c | `Retro Star 3.wav` | Hints Stars Points and Rewards |
| d | `Brightest Star 2.wav` | Hints Stars Points and Rewards |
| e | `Bell Star 2.wav` | Hints Stars Points and Rewards |
| f | `Magic Score 2.wav` | Hints Stars Points and Rewards |
| g | `Magic Score 3.wav` | Hints Stars Points and Rewards |
| h | `Harp 1.wav` -- `Harp 6.wav` | Hints Stars Points and Rewards |

---

### 9. `sfx_raid_boss_impact.wav`
**Used when:** Raid boss attack lands
**Put in:** `Resources/Sounds/Arena & Raid Boss/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `09_Impact_01.wav` | 90_RPG_Battle_SFX |
| b | `10_Impact_02.wav` | 90_RPG_Battle_SFX |
| c | `11_Impact_03.wav` | 90_RPG_Battle_SFX |
| d | `12_Impact_04.wav` | 90_RPG_Battle_SFX |
| e | `13_Impact_05.wav` | 90_RPG_Battle_SFX |
| f | `14_Impact_flesh_01.wav` -- `18_Impact_flesh_05.wav` | 90_RPG_Battle_SFX |
| g | `37_Block_01.wav` -- `40_Block_04.wav` | 90_RPG_Battle_SFX |
| h | `Paladin_Shield_Bash_Hit.wav` | Minifantasy True Heroes II / Paladin |
| i | `01_Fighter_Attack_1.wav` | Minifantasy True Heroes III / Fighter |

---

### 10. `sfx_raid_boss_roar.wav`
**Used when:** Raid boss enrages
**Put in:** `Resources/Sounds/Arena & Raid Boss/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `69_Enemy_death_01.wav` | 90_RPG_Battle_SFX |
| b | `70_Enemy_death_02.wav` | 90_RPG_Battle_SFX |
| c | `71_Enemy_death_03_long.wav` | 90_RPG_Battle_SFX |
| d | `59_Special_move_01.wav` | 90_RPG_Battle_SFX |
| e | `60_Special_move_02.wav` | 90_RPG_Battle_SFX |
| f | `63_Special_move_05.wav` | 90_RPG_Battle_SFX |
| g | `09_Fighter_Cataclism.wav` | Minifantasy True Heroes III / Fighter |
| h | `Destruction_1.wav` | LEOHPAZ_HumanSettlement / Construction |
| i | `Destruction_2.wav` | LEOHPAZ_HumanSettlement / Construction |

---

### 11. `sfx_send_challenge.wav`
**Used when:** Send challenge to partner
**Put in:** `Resources/Sounds/Research, Expeditions, Partner/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `28_swoosh_01.wav` | 90_RPG_Battle_SFX |
| b | `29_swoosh_02.wav` | 90_RPG_Battle_SFX |
| c | `30_swoosh_03.wav` | 90_RPG_Battle_SFX |
| d | `Simple Whoosh 1.wav` | Hints Stars Points and Rewards |
| e | `Simple Whoosh 2.wav` | Hints Stars Points and Rewards |
| f | `Drop_Whoosh.wav` | Inventory_SFX / Drops |
| g | `Notification_1.wav` -- `Notification_4.wav` | Leohpaz_Modern_UI_SFX |

---

### 12. `sfx_forge_enter.wav`
**Used when:** Enter the forge screen
**Put in:** `Resources/Sounds/Forge Sounds/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `04_Smith_Foundry_Loop.wav` | Minifantasy Crafting / Blacksmith |
| b | `05_Smith_Foundry_Pour.wav` | Minifantasy Crafting / Blacksmith |
| c | `06_Smith_Furnace_Loop.wav` | Minifantasy Crafting / Blacksmith |
| d | `07_Smith_Ignition.wav` | Minifantasy Crafting / Blacksmith |
| e | `Blacksmith_1.wav` | LEOHPAZ_HumanSettlement / Facilities |
| f | `Blacksmith_2.wav` | LEOHPAZ_HumanSettlement / Facilities |
| g | `Hell_Portal_Open.wav` | LEOHPAZ_Portals_Runes / Hell |
| h | `Generic_Portal_Open.wav` | LEOHPAZ_Portals_Runes / Generic |
| i | `Fire_Rune_Activate.wav` | LEOHPAZ_Portals_Runes / Fire |

---
---

## HAS AUDIO -- Could Upgrade (19 slots)

These already have a `.wav` file but could sound better with your new packs.
To upgrade: replace the file in its current subfolder, keeping the same filename.

---

### `sfx_level_up.wav` -- Level up celebration
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Level_Up.wav` | Jingles_Fanfares / UI |
| b | `The Victory.wav` | Hints Stars Points and Rewards |
| c | `Royal Declaration Coin.wav` | Hints Stars Points and Rewards |
| d | `73_Lvl_up_01.wav` | 90_RPG_Battle_SFX |
| e | `74_Lvl_up_02.wav` | 90_RPG_Battle_SFX |
| f | `75_Lvl_up_03.wav` | 90_RPG_Battle_SFX |
| g | `Ascending Mystery 1.wav` | Hints Stars Points and Rewards |

---

### `sfx_dungeon_start.wav` -- Dungeon entry
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Round_Start.wav` | Jingles_Fanfares / Round |
| b | `Minigame_Start.wav` | Jingles_Fanfares / Puzzle_Minigame |
| c | `Drums_1.wav` | Jingles_Fanfares / Drums |
| d | `54_Encounter_01.wav` -- `58_Encounter_05.wav` | 90_RPG_Battle_SFX |

---

### `sfx_dungeon_complete.wav` -- Dungeon completed
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Special_Item_Found.wav` | Jingles_Fanfares / Secrets |
| b | `Small_Secret.wav` | Jingles_Fanfares / Secrets |
| c | `Puzzle_Solved.wav` | Jingles_Fanfares / Puzzle_Minigame |
| d | `Shimmery Reward 1.wav` | Hints Stars Points and Rewards |

---

### `sfx_achievement_unlock.wav` -- Achievement unlocked
**Currently in:** `New Game Actions/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Unlocked Secret.wav` | Hints Stars Points and Rewards |
| b | `Unlocked Secret (Asian).wav` | Hints Stars Points and Rewards |
| c | `Discovery 2.wav` | Hints Stars Points and Rewards |
| d | `Cosmic Reveal.wav` | Hints Stars Points and Rewards |
| e | `Magic Score 1 Enhanced.wav` | Hints Stars Points and Rewards |

---

### `sfx_loot_drop.wav` -- Loot dropped
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Cosmic Coin.wav` | Hints Stars Points and Rewards |
| b | `Shimmer Jar Coin.wav` | Hints Stars Points and Rewards |
| c | `Legendary_Drop.wav` | Inventory_SFX / Drops |
| d | `Rare_Drop.wav` | Inventory_SFX / Drops |
| e | `Jewel.wav` | Inventory_SFX / Drops |
| f | `DES Magic Gems 1.wav` -- `DES Magic Gems 4.wav` | Coins And Gems / Designed |

---

### `sfx_claim_reward.wav` -- Reward claimed
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Well Deserved Coin.wav` | Hints Stars Points and Rewards |
| b | `Harp Money 1.wav` | Hints Stars Points and Rewards |
| c | `DES Reward 1.wav` -- `DES Reward 3.wav` | Coins And Gems / Designed |
| d | `Positive Vibes Coin.wav` | Hints Stars Points and Rewards |
| e | `Shimmery Reward 2.wav` | Hints Stars Points and Rewards |

---

### `sfx_class_evolution.wav` -- Class evolution
**Currently in:** `New Game Actions/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Ascending Mystery 1.wav` | Hints Stars Points and Rewards |
| b | `Mysterious Chapter.wav` | Hints Stars Points and Rewards |
| c | `Space Probe.wav` | Hints Stars Points and Rewards |
| d | `Generic_Portal_Teleport.wav` | LEOHPAZ_Portals_Runes |

---

### `sfx_rebirth.wav` -- Character rebirth
**Currently in:** `New Game Actions/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Ascending Mystery 2.wav` | Hints Stars Points and Rewards |
| b | `Mysterious Chapter (No Drums).wav` | Hints Stars Points and Rewards |
| c | `Time_Portal_Open.wav` | LEOHPAZ_Portals_Runes / Time |
| d | `28_Revive_01.wav` -- `31_Revive_04.wav` | 50_RPG_Heals_Buffs_SFX |

---

### `sfx_streak_milestone.wav` -- Streak milestone
**Currently in:** `New Game Actions/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Brightest Star 2.wav` | Hints Stars Points and Rewards |
| b | `Retro Star 1.wav` -- `Retro Star 3.wav` | Hints Stars Points and Rewards |
| c | `Bell Star 2.wav` | Hints Stars Points and Rewards |
| d | `Magic Score 8.wav` -- `Magic Score 10.wav` | Hints Stars Points and Rewards |

---

### `sfx_equip_item.wav` -- Equip gear
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `061_Equip_01.wav` -- `069_Equip_09.wav` | 100_rpg_ui_sfx |
| b | `09_equip_1.wav` | 22_book_parchment_ui_SFX |
| c | `Equip.wav` | Inventory_SFX / Managing |
| d | `Socket_Equip.wav` | Inventory_SFX / Managing |

---

### `sfx_store_enter.wav` -- Enter the shop
**Currently in:** `New Game Actions/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `079_Buy_sell_01.wav` | 100_rpg_ui_sfx |
| b | `08 - Shop.ogg/.wav` | xDeviruchi 16 bit Fantasy (first few seconds) |
| c | `Market_2.wav` | LEOHPAZ_HumanSettlement / Facilities |
| d | `Bag_Close.wav` | Inventory_SFX / Bag |

---

### `sfx_store_purchase.wav` -- Buy something
**Currently in:** `New Game Actions/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `080_Buy_sell_02.wav` -- `083_Buy_sell_05.wav` | 100_rpg_ui_sfx |
| b | `DES Buy & Sell 1.wav` -- `DES Buy & Sell 3.wav` | Coins And Gems / Designed |
| c | `Cash Register 2.wav` | Coins And Gems / Update 1 |
| d | `Well Deserved Coin.wav` | Hints Stars Points and Rewards |

---

### `sfx_use_consumable.wav` -- Use a potion/item
**Currently in:** `New Game Actions/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `02_Heal_02.wav` -- `04_Heal_04.wav` | 50_RPG_Heals_Buffs_SFX |
| b | `051_use_item_01.wav` -- `055_use_item_05.wav` | 100_rpg_ui_sfx |
| c | `01_Alchemy_Lab.wav` | Minifantasy Crafting / Alchemy |
| d | `02_Alchemy_Glass_handling_1.wav` | Minifantasy Crafting / Alchemy |

---

### `sfx_training_start.wav` -- Start training
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `87_exp_up_1_short.wav` | 90_RPG_Battle_SFX |
| b | `88_exp_up_2_short.wav` | 90_RPG_Battle_SFX |
| c | `09_Buff_01.wav` -- `12_Buff_04.wav` | 50_RPG_Heals_Buffs_SFX |

---

### `sfx_training_complete.wav` -- Training done
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `73_Lvl_up_01.wav` -- `75_Lvl_up_03.wav` | 90_RPG_Battle_SFX |
| b | `Marimba Completed.wav` | Hints Stars Points and Rewards |
| c | `Checkpoint 2.wav` | Hints Stars Points and Rewards |

---

### `sfx_expedition_depart.wav` -- Expedition departs
**Currently in:** `Research, Expeditions, Partner/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Round_Start.wav` | Jingles_Fanfares / Round |
| b | `Drums_1.wav` | Jingles_Fanfares / Drums |
| c | `Generic_Portal_Open.wav` | LEOHPAZ_Portals_Runes |
| d | `20 - The Journey.ogg/.wav` | xDeviruchi 16 bit Fantasy (first few seconds) |

---

### `sfx_card_reveal.wav` -- Card flip reveal
**Currently in:** `Card Sounds/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `03_flip_page_once_1a.wav` | 22_book_parchment_ui_SFX |
| b | `03_flip_page_once_3.wav` | 22_book_parchment_ui_SFX |
| c | `03_flip_page_once_4a.wav` | 22_book_parchment_ui_SFX |
| d | `Page_Turn.wav` | Inventory_SFX / Managing |

---

### `sfx_research_start.wav` -- Begin research
**Currently in:** `Research, Expeditions, Partner/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `01_book_open_2_slow.wav` | 22_book_parchment_ui_SFX |
| b | `08_start_game.wav` | 22_book_parchment_ui_SFX |
| c | `Scroll.wav` | Inventory_SFX / Drops |

---

### `sfx_research_complete.wav` -- Research finished
**Currently in:** `Research, Expeditions, Partner/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `11_upgrade.wav` | 22_book_parchment_ui_SFX |
| b | `Unlocked Secret.wav` | Hints Stars Points and Rewards |
| c | `Discovery 2.wav` | Hints Stars Points and Rewards |
| d | `Identify.wav` | Inventory_SFX / Managing |

---

### `sfx_splash_intro.wav` -- App launch
**Currently in:** `Core UI & Game SFX/`
**Pick from:**

| # | File | Pack |
|---|---|---|
| a | `Game_Start.wav` | Jingles_Fanfares / UI |
| b | `02 - Title Theme.ogg/.wav` | xDeviruchi 16 bit Fantasy (first 3s) |
| c | `Start_1.wav` | Leohpaz_Modern_UI_SFX / Start |
| d | `Start_2.wav` | Leohpaz_Modern_UI_SFX / Start |

---
---

## ALREADY COMPLETE -- No Action Needed

These slots have custom audio and sound good as-is:

`sfx_button_tap`, `sfx_tab_switch`, `sfx_error`, `sfx_success`, `sfx_mismatch`,
`sfx_task_create`, `sfx_task_delete`, `sfx_daily_quest_claim`, `sfx_goal_milestone`,
`sfx_duty_accept`, `sfx_duty_complete`, `sfx_duty_board_shuffle`,
`sfx_send_kudos`, `sfx_send_nudge`, `sfx_receive_kudos`, `sfx_receive_nudge`,
`sfx_partner_paired`, `sfx_character_created`, `sfx_class_warrior`, `sfx_class_mage`,
`sfx_class_archer`, `sfx_card_collect`, `sfx_card_page_turn`,
`sfx_forge_hammer`, `sfx_forge_anvil_ring`, `sfx_forge_shatter`, `sfx_forge_crumble`,
`sfx_forge_magic_swirl`, `sfx_forge_salvage`, `sfx_forge_enhance`,
`sfx_forge_enhance_fail`, `sfx_forge_critical`,
`sfx_expedition_stage_complete`, `sfx_expedition_treasure`,
`sfx_research_node_unlock`, `sfx_raid_boss_victory`

---

## Quick Reference: Folder Layout

```
Resources/Sounds/
  Ambient Meditation Loops/    (ambient loop .wav files)
  Arena & Raid Boss/           (arena + raid sfx)
  Card Sounds/                 (card reveal/collect/page)
  Core UI & Game SFX/          (buttons, rewards, dungeon, victory, defeat)
  Forge Sounds/                (forge hammer, enhance, etc.)
  New Game Actions/            (class select, store, tasks, streaks)
  Research, Expeditions, Partner/ (research, expedition, partner sfx)
```
