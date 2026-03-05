-- =============================================================
-- QuestBond — Content Data Seed Script
-- Run this AFTER 005_content_tables.sql AND 005b_achievements_quests_tables.sql
--
-- Seeds all existing Swift catalog data into Supabase content tables.
-- This is a one-time migration of hard-coded content to server-driven.
-- =============================================================


-- -----------------------------------------------------------
-- FIX: Ensure slot check constraints allow 'cloak' and 'trinket'
-- (needed if table was created before these slots existed)
-- -----------------------------------------------------------
ALTER TABLE public.content_equipment
    DROP CONSTRAINT IF EXISTS content_equipment_slot_check;
ALTER TABLE public.content_equipment
    ADD CONSTRAINT content_equipment_slot_check
    CHECK (slot IN ('weapon', 'armor', 'accessory', 'trinket', 'cloak'));

ALTER TABLE public.content_milestone_gear
    DROP CONSTRAINT IF EXISTS content_milestone_gear_slot_check;
ALTER TABLE public.content_milestone_gear
    ADD CONSTRAINT content_milestone_gear_slot_check
    CHECK (slot IN ('weapon', 'armor', 'accessory', 'trinket', 'cloak'));


-- -----------------------------------------------------------
-- EQUIPMENT CATALOG (190 items from EquipmentCatalog.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_equipment (id, name, description, slot, base_type, rarity, primary_stat, stat_bonus, secondary_stat, secondary_stat_bonus, level_requirement, image_name, is_set_piece, set_id, active, sort_order) VALUES
-- Swords
('wep_sword_common_01', 'Worn Training Sword', 'A blade so dull it apologizes before each swing. You are technically armed.', 'weapon', 'sword', 'common', 'strength', 2, NULL, 0, 1, 'equip-sword-common', false, NULL, true, 1),
('wep_sword_uncommon_01', 'Steel Longsword', 'Does exactly what it says on the tin. No frills, no magic, just competent steel and a quiet sense of superiority.', 'weapon', 'sword', 'uncommon', 'strength', 4, 'defense', 1, 5, 'equip-sword-uncommon', false, NULL, true, 2),
('wep_sword_rare_01', 'Runic Claymore', 'Found in a lake by a confused fisherman who was just trying to catch bass. The runes translate to ''Return to Sender.''', 'weapon', 'sword', 'rare', 'strength', 6, 'wisdom', 3, 12, 'equip-sword-rare', false, NULL, true, 3),
('wep_sword_epic_01', 'Dragonbane Greatsword', 'Tempered in dragonfire, quenched in the tears of a weeping god, and polished with DRAMA. It''s a lot.', 'weapon', 'sword', 'epic', 'strength', 10, 'dexterity', 4, 22, 'equip-sword-epic', false, NULL, true, 4),
('wep_sword_legendary_01', 'Excalibur, Blade of Dawn', 'The legendary sword that chooses its wielder through a sacred ritual of destiny and fate. It chose you, which raises concerns about its judgment.', 'weapon', 'sword', 'legendary', 'strength', 15, 'charisma', 8, 35, 'equip-sword-legendary', false, NULL, true, 5),
-- Axes
('wep_axe_common_01', 'Rusty Hatchet', 'This axe has killed more firewood than monsters. Your enemies will die of tetanus before blood loss.', 'weapon', 'axe', 'common', 'strength', 3, NULL, 0, 1, 'equip-axe-common', false, NULL, true, 6),
('wep_axe_uncommon_01', 'Ironclad Battleaxe', 'Heavy enough to solve most problems. The problems it can''t solve weren''t worth solving.', 'weapon', 'axe', 'uncommon', 'strength', 5, 'defense', 1, 6, 'equip-axe-uncommon', false, NULL, true, 7),
('wep_axe_rare_01', 'Frostbite Cleaver', 'Accidentally left in a glacier by a forgetful frost giant for three thousand years. He wants it back, by the way.', 'weapon', 'axe', 'rare', 'strength', 7, 'dexterity', 3, 14, 'equip-axe-rare', false, NULL, true, 8),
('wep_axe_epic_01', 'Worldsplitter', 'They say this axe once cleaved a mountain in two. The mountain''s therapist says it''s still working through it.', 'weapon', 'axe', 'epic', 'strength', 11, 'defense', 5, 25, 'equip-axe-epic', false, NULL, true, 9),
('wep_axe_legendary_01', 'Ragnarok, the End of Ages', 'Forged in the heart of a dying star by a blacksmith with anger issues. The universe trembled. The blacksmith''s Yelp review was 3 stars.', 'weapon', 'axe', 'legendary', 'strength', 16, 'luck', 7, 38, 'equip-axe-legendary', false, NULL, true, 10),
-- Staves
('wep_staff_common_01', 'Gnarled Walking Stick', 'It''s a stick. You''re holding a stick. Somewhere, a dog is very jealous.', 'weapon', 'staff', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-staff-common', false, NULL, true, 11),
('wep_staff_uncommon_01', 'Oak Channeling Staff', 'Channels magic about as well as a garden hose channels Niagara Falls. But it tries, and that''s what matters.', 'weapon', 'staff', 'uncommon', 'wisdom', 4, 'charisma', 2, 5, 'equip-staff-uncommon', false, NULL, true, 12),
('wep_staff_rare_01', 'Stormcaller''s Crook', 'Carved by a shepherd who got REALLY tired of wolves. The local weather service has filed multiple complaints.', 'weapon', 'staff', 'rare', 'wisdom', 7, 'strength', 2, 13, 'equip-staff-rare', false, NULL, true, 13),
('wep_staff_epic_01', 'Archmage''s Scepter', 'Contains the accumulated wisdom of seventeen archmages, all of whom are backseat-casting from beyond the grave. Shut up, Aldric.', 'weapon', 'staff', 'epic', 'wisdom', 11, 'luck', 4, 24, 'equip-staff-epic', false, NULL, true, 14),
('wep_staff_legendary_01', 'Yggdrasil''s Root', 'A living branch from the World Tree itself. It has opinions about your spellcasting. It is not impressed.', 'weapon', 'staff', 'legendary', 'wisdom', 17, 'defense', 7, 40, 'equip-staff-legendary', false, NULL, true, 15),
-- Daggers
('wep_dagger_common_01', 'Chipped Shiv', 'Looks like it was forged by someone who heard a description of a knife but never actually saw one. Still pointy though.', 'weapon', 'dagger', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-dagger-common', false, NULL, true, 16),
('wep_dagger_uncommon_01', 'Viper Fang Stiletto', 'Wickedly sharp, subtle, and sophisticated. Everything you''re not, but at least you''re holding it.', 'weapon', 'dagger', 'uncommon', 'dexterity', 4, 'luck', 2, 4, 'equip-dagger-uncommon', false, NULL, true, 17),
('wep_dagger_rare_01', 'Shadowstep Kris', 'Won in a poker game against a shadow demon who, it turns out, has a terrible poker face. Well, no face.', 'weapon', 'dagger', 'rare', 'dexterity', 6, 'strength', 3, 11, 'equip-dagger-rare', false, NULL, true, 18),
('wep_dagger_epic_01', 'Nightwhisper', 'A blade so silent it once snuck up on ITSELF. The resulting paradox destroyed two taverns and a philosophy department.', 'weapon', 'dagger', 'epic', 'dexterity', 10, 'luck', 5, 20, 'equip-dagger-epic', false, NULL, true, 19),
('wep_dagger_legendary_01', 'Oblivion''s Kiss', 'They say this dagger can sever fate itself. One scratch rewrites destiny. The warranty, however, is non-transferable.', 'weapon', 'dagger', 'legendary', 'dexterity', 14, 'charisma', 9, 34, 'equip-dagger-legendary', false, NULL, true, 20),
-- Bows
('wep_bow_common_01', 'Frayed Shortbow', 'Fires arrows in the general direction of ''over there.'' Your accuracy is a you problem, not a bow problem.', 'weapon', 'bow', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-bow-common', false, NULL, true, 21),
('wep_bow_uncommon_01', 'Hunter''s Recurve', 'It doesn''t miss often, and when it does, it has the decency to look embarrassed about it.', 'weapon', 'bow', 'uncommon', 'dexterity', 4, 'strength', 1, 5, 'equip-bow-uncommon', false, NULL, true, 22),
('wep_bow_rare_01', 'Windrunner Longbow', 'Originally owned by an elf who got lost, fired an arrow for directions, and accidentally founded an archery school.', 'weapon', 'bow', 'rare', 'dexterity', 7, 'luck', 3, 13, 'equip-bow-rare', false, NULL, true, 23),
('wep_bow_epic_01', 'Celestial Warbow', 'Each arrow trails a comet''s tail across the sky, which is breathtaking, beautiful, and absolutely RUINS any attempt at stealth.', 'weapon', 'bow', 'epic', 'dexterity', 10, 'wisdom', 5, 23, 'equip-bow-epic', false, NULL, true, 24),
('wep_bow_legendary_01', 'Artemis, the Moonlit Arc', 'Blessed by the goddess of the hunt herself. Under moonlight, every shot hits. Under fluorescent lighting, no promises.', 'weapon', 'bow', 'legendary', 'dexterity', 15, 'luck', 10, 36, 'equip-bow-legendary', false, NULL, true, 25),
-- Wands
('wep_wand_common_01', 'Splintered Wand', 'It''s basically a sparkler with a self-esteem problem. Wave it around and hope the enemy is impressed. They won''t be.', 'weapon', 'wand', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-wand-common', false, NULL, true, 26),
('wep_wand_uncommon_01', 'Ember Wand', 'Perpetually warm, like a cup of tea you forgot about but can still technically drink. Casts spells the same way.', 'weapon', 'wand', 'uncommon', 'wisdom', 4, 'luck', 1, 4, 'equip-wand-uncommon', false, NULL, true, 27),
('wep_wand_rare_01', 'Prismatic Focus', 'Invented by a color-blind wizard who just wanted to see a rainbow. He saw one. Then it exploded. He''s fine.', 'weapon', 'wand', 'rare', 'wisdom', 6, 'charisma', 3, 12, 'equip-wand-rare', false, NULL, true, 28),
('wep_wand_epic_01', 'Void Siphon', 'Drinks magic from the air like a dehydrated camel at an oasis. The raw destructive output is terrifying. The slurping sound is worse.', 'weapon', 'wand', 'epic', 'wisdom', 10, 'dexterity', 4, 21, 'equip-wand-epic', false, NULL, true, 29),
('wep_wand_legendary_01', 'Merlin''s Last Word', 'The final creation of the greatest mage who ever lived. It thinks, it judges, and it will NOT stop giving unsolicited career advice.', 'weapon', 'wand', 'legendary', 'wisdom', 16, 'luck', 8, 38, 'equip-wand-legendary', false, NULL, true, 30),
-- Maces
('wep_mace_common_01', 'Bent Cudgel', 'A lump of metal on a stick. This is where weapon design starts and ambition ends. You''re welcome.', 'weapon', 'mace', 'common', 'strength', 2, NULL, 0, 1, 'equip-mace-common', false, NULL, true, 31),
('wep_mace_uncommon_01', 'Flanged War Mace', 'Armor is merely a suggestion to this weapon. The suggestion is ''crumple.''', 'weapon', 'mace', 'uncommon', 'strength', 4, 'defense', 2, 6, 'equip-mace-uncommon', false, NULL, true, 32),
('wep_mace_rare_01', 'Thundering Maul', 'Fell off the back of a thunder god''s chariot during a particularly nasty pothole. Nobody''s come to claim it.', 'weapon', 'mace', 'rare', 'strength', 7, 'defense', 3, 14, 'equip-mace-rare', false, NULL, true, 33),
('wep_mace_epic_01', 'Dawnbreaker', 'A holy mace that blazes with the fury of a thousand suns. The undead flee. Your eyebrows also flee. Worth it.', 'weapon', 'mace', 'epic', 'strength', 10, 'charisma', 5, 24, 'equip-mace-epic', false, NULL, true, 34),
('wep_mace_legendary_01', 'Mjolnir, the Stormhammer', 'Only the worthy may lift it. So far the ''worthy'' includes two heroes, a golden retriever, and one very determined toddler.', 'weapon', 'mace', 'legendary', 'strength', 17, 'defense', 8, 40, 'equip-mace-legendary', false, NULL, true, 35),
-- Spears
('wep_spear_common_01', 'Wooden Pike', 'A sharp stick that got promoted way above its pay grade. It has impostor syndrome and, honestly, valid.', 'weapon', 'spear', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-spear-common', false, NULL, true, 36),
('wep_spear_uncommon_01', 'Bronze Partisan', 'Perfectly adequate for both thrusting and sweeping. Also makes a surprisingly good coat rack in a pinch.', 'weapon', 'spear', 'uncommon', 'dexterity', 4, 'strength', 2, 5, 'equip-spear-uncommon', false, NULL, true, 37),
('wep_spear_rare_01', 'Tidecaller Trident', 'Pulled from the ocean by a fisherman who immediately quit his job and became an adventurer. His wife is still furious.', 'weapon', 'spear', 'rare', 'dexterity', 6, 'wisdom', 3, 13, 'equip-spear-rare', false, NULL, true, 38),
('wep_spear_epic_01', 'Skypierce Lance', 'So perfectly balanced it feels weightless. Thrown, it can punch through castle walls. The HOA is going to be livid.', 'weapon', 'spear', 'epic', 'dexterity', 10, 'strength', 5, 23, 'equip-spear-epic', false, NULL, true, 39),
('wep_spear_legendary_01', 'Gungnir, the Allfather''s Reach', 'Once thrown, it never misses. NEVER. The Allfather threw it once as a test and it''s been awkward at family dinners ever since.', 'weapon', 'spear', 'legendary', 'dexterity', 15, 'wisdom', 9, 37, 'equip-spear-legendary', false, NULL, true, 40),
-- Shields
('wep_shield_common_01', 'Splintered Buckler', 'More splinter than shield at this point. Blocks attacks the way a screen door blocks rain.', 'weapon', 'shield', 'common', 'defense', 2, NULL, 0, 1, 'equip-shield-common', false, NULL, true, 41),
('wep_shield_uncommon_01', 'Iron Kite Shield', 'It''s called a kite shield but it absolutely cannot fly. Several adventurers have tested this. From cliffs.', 'weapon', 'shield', 'uncommon', 'defense', 4, 'strength', 2, 6, 'equip-shield-uncommon', false, NULL, true, 42),
('wep_shield_rare_01', 'Tower Shield of the Vanguard', 'Commissioned by a knight who was allergic to getting hit. The blacksmith made it the size of a door. The knight was 4''11".', 'weapon', 'shield', 'rare', 'defense', 7, 'strength', 3, 14, 'equip-shield-rare', false, NULL, true, 43),
('wep_shield_epic_01', 'Dragon Scale Aegis', 'Forged from real dragon scales, which the dragon did NOT consent to donating. Legal proceedings are ongoing.', 'weapon', 'shield', 'epic', 'defense', 11, 'strength', 5, 25, 'equip-shield-epic', false, NULL, true, 44),
('wep_shield_legendary_01', 'Aegis of Ages', 'This shield has witnessed every war in recorded history and it is TIRED. Blocks attacks out of sheer spite at this point.', 'weapon', 'shield', 'legendary', 'defense', 17, 'charisma', 8, 40, 'equip-shield-legendary', false, NULL, true, 45),
-- Crossbows
('wep_crossbow_common_01', 'Light Crossbow', 'Point the dangerous end away from your face. That''s it. That''s the whole instruction manual.', 'weapon', 'crossbow', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-crossbow-common', false, NULL, true, 46),
('wep_crossbow_uncommon_01', 'Repeating Crossbow', 'Fires bolts faster than you can aim. Accuracy is a state of mind, and that state is ''optimistic.''', 'weapon', 'crossbow', 'uncommon', 'dexterity', 4, 'strength', 2, 5, 'equip-crossbow-uncommon', false, NULL, true, 47),
('wep_crossbow_rare_01', 'Heavy Arbalest', 'Built by a dwarf who was told crossbows couldn''t be ''too much.'' He took that personally.', 'weapon', 'crossbow', 'rare', 'dexterity', 7, 'strength', 3, 13, 'equip-crossbow-rare', false, NULL, true, 48),
('wep_crossbow_epic_01', 'Siege Crossbow', 'Designed to breach castle walls, which is wildly excessive for dungeon crawling. You''ll use it anyway because you have no chill.', 'weapon', 'crossbow', 'epic', 'dexterity', 10, 'defense', 5, 23, 'equip-crossbow-epic', false, NULL, true, 49),
('wep_crossbow_legendary_01', 'Arbalest of Ruin', 'Its bolts pierce through dimensions. The last person who fired it accidentally sent a bolt into next Tuesday. Tuesday was not happy.', 'weapon', 'crossbow', 'legendary', 'dexterity', 16, 'luck', 8, 37, 'equip-crossbow-legendary', false, NULL, true, 50),
-- Tomes
('wep_tome_common_01', 'Worn Tome', 'Half the pages are missing, the rest are sticky, and chapter three is just someone''s grocery list. Still technically a spellbook.', 'weapon', 'tome', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-tome-common', false, NULL, true, 51),
('wep_tome_uncommon_01', 'Scholar''s Tome', 'Well-organized, thoroughly annotated, and deeply passive-aggressive in the margins. ''See, THIS is how you cast fireball.''', 'weapon', 'tome', 'uncommon', 'wisdom', 5, 'charisma', 1, 5, 'equip-tome-uncommon', false, NULL, true, 52),
('wep_tome_rare_01', 'Arcane Grimoire', 'Written by a wizard who couldn''t decide on a font, so every page is in a different one. Chapter 7 is in Wingdings.', 'weapon', 'tome', 'rare', 'wisdom', 7, 'luck', 3, 13, 'equip-tome-rare', false, NULL, true, 53),
('wep_tome_epic_01', 'Eldritch Codex', 'Bound in shadow-leather, written in a language that makes your eyes water. Reading it aloud summons a migraine and, occasionally, eldritch power.', 'weapon', 'tome', 'epic', 'wisdom', 11, 'defense', 4, 24, 'equip-tome-epic', false, NULL, true, 54),
('wep_tome_legendary_01', 'Tome of Infinite Wisdom', 'A book with no last page. It knows everything, including what you did last summer. It''s not angry, just disappointed.', 'weapon', 'tome', 'legendary', 'wisdom', 17, 'charisma', 9, 40, 'equip-tome-legendary', false, NULL, true, 55),
-- Halberds
('wep_halberd_common_01', 'Rusty Halberd', 'A polearm that can''t decide if it''s an axe or a spear. Identity crisis on a stick.', 'weapon', 'halberd', 'common', 'strength', 3, NULL, 0, 1, 'equip-halberd-common', false, NULL, true, 56),
('wep_halberd_uncommon_01', 'Footman''s Halberd', 'Standard issue for guards who wanted a sword AND a spear but only had one equipment slot.', 'weapon', 'halberd', 'uncommon', 'strength', 5, 'defense', 2, 6, 'equip-halberd-uncommon', false, NULL, true, 57),
('wep_halberd_rare_01', 'Wyvern''s Beak Halberd', 'Forged to resemble a wyvern''s beak. The wyvern was not consulted and is reportedly furious.', 'weapon', 'halberd', 'rare', 'strength', 8, 'dexterity', 3, 14, 'equip-halberd-rare', false, NULL, true, 58),
('wep_halberd_epic_01', 'Siegebreaker Halberd', 'Designed to breach castle gates. Slightly overkill for dungeon rats, but style points matter.', 'weapon', 'halberd', 'epic', 'strength', 12, 'defense', 5, 25, 'equip-halberd-epic', false, NULL, true, 59),
('wep_halberd_legendary_01', 'Worldsplitter Halberd', 'Legend says one swing split a continent in half. Geologists disagree but they weren''t there.', 'weapon', 'halberd', 'legendary', 'strength', 17, 'luck', 8, 38, 'equip-halberd-legendary', false, NULL, true, 60),
-- Plates
('arm_plate_common_01', 'Dented Iron Plate', 'Offers the protection of a tin can and roughly the same comfort. Your starter armor, because the game had to give you something.', 'armor', 'plate', 'common', 'defense', 3, NULL, 0, 1, 'equip-plate-common', false, NULL, true, 61),
('arm_plate_uncommon_01', 'Steel Guardian Plate', 'Properly fitted and only slightly crushing your organs. A solid upgrade for those who enjoy breathing occasionally.', 'armor', 'plate', 'uncommon', 'defense', 5, 'strength', 1, 7, 'equip-plate-uncommon', false, NULL, true, 62),
('arm_plate_rare_01', 'Warden''s Bulwark', 'Enchanted by a wizard who got hit one too many times and said ''never again.'' The harder you hit it, the more offended it gets.', 'armor', 'plate', 'rare', 'defense', 7, 'strength', 3, 15, 'equip-plate-rare', false, NULL, true, 63),
('arm_plate_epic_01', 'Titanforge Warplate', 'Forged from an alloy so rare the periodic table filed a restraining order. Blades don''t just bounce off — they apologize.', 'armor', 'plate', 'epic', 'defense', 11, 'strength', 5, 26, 'equip-plate-epic', false, NULL, true, 64),
('arm_plate_legendary_01', 'Aegis of the Immortal', 'The last eternal guardian wore this into a thousand battles and zero funerals. Dry cleaning it requires a permit from three different gods.', 'armor', 'plate', 'legendary', 'defense', 18, 'charisma', 7, 40, 'equip-plate-legendary', false, NULL, true, 65),
-- Chainmails
('arm_chain_common_01', 'Loose Chain Shirt', 'Sounds like a wind chime in combat. Enemies hear you coming from three rooms away, but at least you''re jingly.', 'armor', 'chainmail', 'common', 'defense', 2, NULL, 0, 1, 'equip-chainmail-common', false, NULL, true, 66),
('arm_chain_uncommon_01', 'Riveted Hauberk', 'Each ring individually riveted by someone with incredible patience and questionable life choices.', 'armor', 'chainmail', 'uncommon', 'defense', 4, 'dexterity', 2, 6, 'equip-chainmail-uncommon', false, NULL, true, 67),
('arm_chain_rare_01', 'Mithril Weave', 'Won in a poker game against an elf who swore it was ''just regular chainmail.'' That elf doesn''t play poker anymore.', 'armor', 'chainmail', 'rare', 'defense', 6, 'dexterity', 4, 14, 'equip-chainmail-rare', false, NULL, true, 68),
('arm_chain_epic_01', 'Dragonlink Coat', 'Each link is a miniature dragon scale. The dragons are furious about the unauthorized merchandise.', 'armor', 'chainmail', 'epic', 'defense', 9, 'dexterity', 5, 24, 'equip-chainmail-epic', false, NULL, true, 69),
('arm_chain_legendary_01', 'Veil of the Valkyrie', 'Woven by warrior-angels from threads of pure valor. The return policy requires dying honorably in battle.', 'armor', 'chainmail', 'legendary', 'defense', 15, 'luck', 8, 37, 'equip-chainmail-legendary', false, NULL, true, 70),
-- Leather Armor
('arm_leather_common_01', 'Patched Hide Vest', 'Stitched from the hides of animals who probably weren''t using them anymore. At least, you hope they weren''t.', 'armor', 'leather armor', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-leather-armor-common', false, NULL, true, 71),
('arm_leather_uncommon_01', 'Ranger''s Jerkin', 'Dyed green for forest stealth. Unfortunately, you''re rarely in a forest and now you just look like an asparagus.', 'armor', 'leather armor', 'uncommon', 'dexterity', 4, 'defense', 1, 5, 'equip-leather-armor-uncommon', false, NULL, true, 72),
('arm_leather_rare_01', 'Shadowskin Cuirass', 'Treated with shadow-essence by a rogue who charged triple because ''you can''t see me working.'' Nobody could argue.', 'armor', 'leather armor', 'rare', 'dexterity', 6, 'luck', 3, 12, 'equip-leather-armor-rare', false, NULL, true, 73),
('arm_leather_epic_01', 'Wyrmhide Armor', 'Tanned from an elder wyrm''s hide. The wyrm was already dead. Probably. Look, don''t ask follow-up questions.', 'armor', 'leather armor', 'epic', 'dexterity', 10, 'defense', 4, 22, 'equip-leather-armor-epic', false, NULL, true, 74),
('arm_leather_legendary_01', 'Phantom Shroud', 'Woven from the echoes of a thousand whispered secrets. Most of them are just gossip, but the defense stats are real.', 'armor', 'leather armor', 'legendary', 'dexterity', 14, 'charisma', 8, 35, 'equip-leather-armor-legendary', false, NULL, true, 75),
-- Breastplates
('arm_breast_common_01', 'Tarnished Breastplate', 'The engraving wore off so long ago nobody knows whose crest it was. Including the breastplate.', 'armor', 'breastplate', 'common', 'defense', 2, NULL, 0, 1, 'equip-breastplate-common', false, NULL, true, 76),
('arm_breast_uncommon_01', 'Knight''s Cuirass', 'Bears the crest of a fallen order. They fell because they kept polishing their armor instead of fighting.', 'armor', 'breastplate', 'uncommon', 'defense', 4, 'charisma', 1, 6, 'equip-breastplate-uncommon', false, NULL, true, 77),
('arm_breast_rare_01', 'Emberheart Guard', 'Forged by a blacksmith who fell into his own furnace and emerged ''enlightened.'' Perpetually warm and slightly unhinged.', 'armor', 'breastplate', 'rare', 'defense', 6, 'strength', 3, 14, 'equip-breastplate-rare', false, NULL, true, 78),
('arm_breast_epic_01', 'Oathkeeper''s Aegis', 'Engraved with binding oaths of protection so lengthy, enemies fall asleep reading them. Technically a feature.', 'armor', 'breastplate', 'epic', 'defense', 10, 'charisma', 5, 25, 'equip-breastplate-epic', false, NULL, true, 79),
('arm_breast_legendary_01', 'Soulforged Vestment', 'Bound to its wearer''s soul. It heals itself, grows with its bearer, and gets really passive-aggressive when you look at other armor.', 'armor', 'breastplate', 'legendary', 'defense', 16, 'wisdom', 7, 38, 'equip-breastplate-legendary', false, NULL, true, 80),
-- Helms
('arm_helm_common_01', 'Battered Tin Helm', 'It''s basically a bucket with eye holes. You''ll look ridiculous, but head injuries don''t care about fashion.', 'armor', 'helm', 'common', 'defense', 1, NULL, 0, 1, 'equip-helm-common', false, NULL, true, 81),
('arm_helm_uncommon_01', 'Steel Barbute', 'A well-crafted helm with a T-shaped visor. Excellent protection. Terrible for eating soup.', 'armor', 'helm', 'uncommon', 'defense', 3, 'wisdom', 2, 5, 'equip-helm-uncommon', false, NULL, true, 82),
('arm_helm_rare_01', 'Crown of the Vigilant', 'Forged by an insomniac king who demanded to see everything at all times. He saw too much. He doesn''t talk about it.', 'armor', 'helm', 'rare', 'defense', 5, 'wisdom', 4, 13, 'equip-helm-rare', false, NULL, true, 83),
('arm_helm_epic_01', 'Dread Visage', 'A terrifying horned helm that makes enemies flee in terror. Also makes doorways your mortal enemy.', 'armor', 'helm', 'epic', 'defense', 8, 'charisma', 6, 23, 'equip-helm-epic', false, NULL, true, 84),
('arm_helm_legendary_01', 'Crown of the Conqueror', 'Worn by the one who united all kingdoms. Mostly because nobody wanted to tell him the horns looked silly.', 'armor', 'helm', 'legendary', 'defense', 13, 'charisma', 10, 36, 'equip-helm-legendary', false, NULL, true, 85),
-- Gauntlets
('arm_gauntlets_common_01', 'Cracked Leather Gloves', 'They barely qualify as gauntlets. They barely qualify as gloves. But your hands are slightly less naked now.', 'armor', 'gauntlets', 'common', 'strength', 1, NULL, 0, 1, 'equip-gauntlets-common', false, NULL, true, 86),
('arm_gauntlets_uncommon_01', 'Iron Grip Gauntlets', 'Reinforced knuckles for a firm handshake that doubles as a threat. Networking has never been so aggressive.', 'armor', 'gauntlets', 'uncommon', 'strength', 3, 'defense', 2, 5, 'equip-gauntlets-uncommon', false, NULL, true, 87),
('arm_gauntlets_rare_01', 'Flameguard Gauntlets', 'Enchanted by a wizard who kept burning his toast. Fireproof from fingertip to elbow. The toast issue remains unsolved.', 'armor', 'gauntlets', 'rare', 'strength', 5, 'defense', 4, 12, 'equip-gauntlets-rare', false, NULL, true, 88),
('arm_gauntlets_epic_01', 'Titan''s Grasp', 'Once you grab something, divine intervention is required to let go. Terrible for first dates. Incredible for battle.', 'armor', 'gauntlets', 'epic', 'strength', 9, 'defense', 5, 22, 'equip-gauntlets-epic', false, NULL, true, 89),
('arm_gauntlets_legendary_01', 'Hands of Creation', 'Said to be replicas of the hands that shaped the world. Also excellent for opening stubborn pickle jars.', 'armor', 'gauntlets', 'legendary', 'strength', 14, 'wisdom', 8, 37, 'equip-gauntlets-legendary', false, NULL, true, 90),
-- Boots
('arm_boots_common_01', 'Worn Sandals', 'Technically footwear the same way a napkin is technically a blanket. Your toes have filed a formal complaint.', 'armor', 'boots', 'common', 'dexterity', 1, NULL, 0, 1, 'equip-boots-common', false, NULL, true, 91),
('arm_boots_uncommon_01', 'Leather Boots', 'Sturdy, reliable, and completely unremarkable. The sensible sedan of adventuring footwear.', 'armor', 'boots', 'uncommon', 'dexterity', 3, 'defense', 1, 5, 'equip-boots-uncommon', false, NULL, true, 92),
('arm_boots_rare_01', 'Plated Greaves', 'Forged after a hero stubbed his toe on a treasure chest and demanded justice. One awkward injury, one legendary innovation.', 'armor', 'boots', 'rare', 'dexterity', 5, 'defense', 3, 12, 'equip-boots-rare', false, NULL, true, 93),
('arm_boots_epic_01', 'Enchanted Greaves', 'Defy physics by getting lighter the faster you run. Isaac Newton''s ghost filed a bug report.', 'armor', 'boots', 'epic', 'dexterity', 9, 'defense', 4, 22, 'equip-boots-epic', false, NULL, true, 94),
('arm_boots_legendary_01', 'Stormstrider Boots', 'Each step crackles with lightning. You move at the speed of thought — mostly the thought ''I should not have worn these indoors.''', 'armor', 'boots', 'legendary', 'dexterity', 14, 'luck', 8, 36, 'equip-boots-legendary', false, NULL, true, 95),
-- Pauldrons
('arm_pauldrons_common_01', 'Cloth Pauldrons', 'Padded shoulder wraps that say ''I''m trying'' without saying ''I''m succeeding.''', 'armor', 'pauldrons', 'common', 'defense', 1, NULL, 0, 1, 'equip-pauldrons-common', false, NULL, true, 96),
('arm_pauldrons_uncommon_01', 'Iron Pauldrons', 'Solid iron shoulder guards. Your shrugs now deal bludgeoning damage.', 'armor', 'pauldrons', 'uncommon', 'defense', 3, 'strength', 2, 6, 'equip-pauldrons-uncommon', false, NULL, true, 97),
('arm_pauldrons_rare_01', 'Steel Pauldrons', 'Mirror-polished to blind enemies. Invented by a blacksmith tired of being stabbed in the shoulders specifically.', 'armor', 'pauldrons', 'rare', 'defense', 5, 'strength', 4, 13, 'equip-pauldrons-rare', false, NULL, true, 98),
('arm_pauldrons_epic_01', 'Dragonbone Pauldrons', 'Carved from a dragon''s shoulder bones. The dragon''s estate formally requests you stop wearing its grandma.', 'armor', 'pauldrons', 'epic', 'defense', 8, 'strength', 6, 24, 'equip-pauldrons-epic', false, NULL, true, 99),
('arm_pauldrons_legendary_01', 'Titan Pauldrons', 'Forged from a fallen titan''s armor. Your shoulders are now wider than most doorways and all of your social plans.', 'armor', 'pauldrons', 'legendary', 'defense', 13, 'strength', 10, 38, 'equip-pauldrons-legendary', false, NULL, true, 100),
-- Heavy Helms
('arm_hhhelm_common_01', 'Dented Heavy Helm', 'Limited visibility, questionable ventilation, and a mysterious smell inside. Welcome to the tank life.', 'armor', 'heavy helm', 'common', 'defense', 2, NULL, 0, 3, 'equip-heavy-helm-common', false, NULL, true, 101),
('arm_hhhelm_uncommon_01', 'Iron Heavy Helm', 'A solid iron greathelm for when you want to cosplay as a very angry mailbox.', 'armor', 'heavy helm', 'uncommon', 'defense', 4, 'strength', 2, 8, 'equip-heavy-helm-uncommon', false, NULL, true, 102),
('arm_hhhelm_rare_01', 'Steel Heavy Helm', 'Commissioned by a knight who headbutted a dragon and wanted to try again. Swords bounce off it like suggestions.', 'armor', 'heavy helm', 'rare', 'defense', 6, 'strength', 4, 15, 'equip-heavy-helm-rare', false, NULL, true, 103),
('arm_hhhelm_epic_01', 'Warlord''s Heavy Helm', 'A crowned greathelm etched with battle runes. Its wearer commands respect on any battlefield.', 'armor', 'heavy helm', 'epic', 'defense', 9, 'charisma', 6, 25, 'equip-heavy-helm-epic', false, NULL, true, 104),
('arm_hhhelm_legendary_01', 'Helm of the Immortal', 'No warrior wearing this has ever fallen in battle. Mainly because the weight keeps them firmly planted on the ground.', 'armor', 'heavy helm', 'legendary', 'defense', 14, 'strength', 10, 38, 'equip-heavy-helm-legendary', false, NULL, true, 105),
-- Heavy Gauntlets
('arm_hgauntlets_common_01', 'Rusty Heavy Gauntlets', 'Your fists are now legally classified as blunt weapons. Also, good luck picking up coins.', 'armor', 'heavy gauntlets', 'common', 'strength', 2, NULL, 0, 3, 'equip-heavy-gauntlets-common', false, NULL, true, 106),
('arm_hgauntlets_uncommon_01', 'Plated Heavy Gauntlets', 'Articulated steel plates over chainmail. Each finger moves like a tiny, deeply committed battering ram.', 'armor', 'heavy gauntlets', 'uncommon', 'strength', 4, 'defense', 2, 8, 'equip-heavy-gauntlets-uncommon', false, NULL, true, 107),
('arm_hgauntlets_rare_01', 'Forgemaster''s Heavy Gauntlets', 'Invented after the ''bare hands incident'' at the dragon-fire forge that nobody discusses. Fireproof, trauma-proof.', 'armor', 'heavy gauntlets', 'rare', 'strength', 6, 'defense', 4, 14, 'equip-heavy-gauntlets-rare', false, NULL, true, 108),
('arm_hgauntlets_epic_01', 'Siegebreaker Heavy Gauntlets', 'Enchanted to amplify grip strength tenfold. Opening a jar of pickles with these constitutes a war crime.', 'armor', 'heavy gauntlets', 'epic', 'strength', 10, 'defense', 6, 24, 'equip-heavy-gauntlets-epic', false, NULL, true, 109),
('arm_hgauntlets_legendary_01', 'Fists of the Mountain King', 'Carved from living stone and bound with adamantine. One punch reshapes the landscape. One high-five reshapes your friend.', 'armor', 'heavy gauntlets', 'legendary', 'strength', 15, 'defense', 10, 38, 'equip-heavy-gauntlets-legendary', false, NULL, true, 110),
-- Heavy Boots
('arm_hboots_common_01', 'Iron Heavy Boots', 'Clunky, loud, and guaranteed to ruin every wooden floor you walk on. Stealth is no longer an option.', 'armor', 'heavy boots', 'common', 'defense', 2, NULL, 0, 3, 'equip-heavy-boots-common', false, NULL, true, 111),
('arm_hboots_uncommon_01', 'Steel Heavy Boots', 'Every step sounds like a war drum. Enemies know you''re coming. So does everyone in a three-mile radius.', 'armor', 'heavy boots', 'uncommon', 'defense', 4, 'dexterity', 1, 8, 'equip-heavy-boots-uncommon', false, NULL, true, 112),
('arm_hboots_rare_01', 'Warplate Heavy Boots', 'Enchanted to grip any surface. Invented after one too many embarrassing deaths by slippery dungeon floors.', 'armor', 'heavy boots', 'rare', 'defense', 6, 'dexterity', 3, 14, 'equip-heavy-boots-rare', false, NULL, true, 113),
('arm_hboots_epic_01', 'Earthshaker Heavy Boots', 'Each stomp sends tremors through the ground. Your upstairs neighbors filed a formal complaint with the Guild.', 'armor', 'heavy boots', 'epic', 'defense', 9, 'strength', 5, 24, 'equip-heavy-boots-epic', false, NULL, true, 114),
('arm_hboots_legendary_01', 'Colossus Treads', 'Forged from the same metal as the ancient war colossus. The ground bows beneath them, mostly because it has no choice.', 'armor', 'heavy boots', 'legendary', 'defense', 14, 'strength', 9, 38, 'equip-heavy-boots-legendary', false, NULL, true, 115),
-- Tunics
('arm_tunic_common_01', 'Moth-Eaten Tunic', 'More holes than fabric. The moths left a one-star review.', 'armor', 'tunic', 'common', 'wisdom', 1, NULL, 0, 1, 'equip-tunic-common', false, NULL, true, 116),
('arm_tunic_uncommon_01', 'Apprentice''s Vestment', 'Comes pre-stained with potion residue. The previous owner ''graduated'' abruptly.', 'armor', 'tunic', 'uncommon', 'wisdom', 3, 'defense', 1, 5, 'equip-tunic-uncommon', false, NULL, true, 117),
('arm_tunic_rare_01', 'Runewoven Vestment', 'Protective runes stitched by someone who clearly ran out of thread halfway through.', 'armor', 'tunic', 'rare', 'wisdom', 6, 'defense', 3, 13, 'equip-tunic-rare', false, NULL, true, 118),
('arm_tunic_epic_01', 'Arcane-Threaded Vestment', 'Each thread is a tiny spell. Dry cleaning costs more than most castles.', 'armor', 'tunic', 'epic', 'wisdom', 9, 'defense', 5, 24, 'equip-tunic-epic', false, NULL, true, 119),
('arm_tunic_legendary_01', 'Vestment of the Infinite', 'Woven from the fabric of reality itself. Ironically, it wrinkles if you look at it wrong.', 'armor', 'tunic', 'legendary', 'wisdom', 14, 'luck', 8, 38, 'equip-tunic-legendary', false, NULL, true, 120),
-- Rings
('acc_ring_common_01', 'Tarnished Copper Band', 'It''s technically jewelry in the same way a participation trophy is technically an award.', 'accessory', 'ring', 'common', 'luck', 1, NULL, 0, 1, 'equip-ring-common', false, NULL, true, 121),
('acc_ring_uncommon_01', 'Silver Promise Ring', 'Promises were made. Whether they''ll be kept is above this ring''s pay grade.', 'accessory', 'ring', 'uncommon', 'charisma', 3, 'luck', 2, 4, 'equip-ring-uncommon', false, NULL, true, 122),
('acc_ring_rare_01', 'Ring of Shared Strength', 'Forged by a blacksmith couple who argued over the design for eleven years. The tension made it stronger.', 'accessory', 'ring', 'rare', 'strength', 5, 'charisma', 4, 11, 'equip-ring-rare', false, NULL, true, 123),
('acc_ring_epic_01', 'Eclipse Band', 'The sun and moon metals were sworn enemies until a jeweler forced them into couples therapy. Now they dance.', 'accessory', 'ring', 'epic', 'luck', 8, 'wisdom', 5, 20, 'equip-ring-epic', false, NULL, true, 124),
('acc_ring_legendary_01', 'The Eternal Vow', 'Forged in the heart of a dying star by an immortal who just really didn''t want to be single anymore. Commitment issues: solved.', 'accessory', 'ring', 'legendary', 'charisma', 14, 'luck', 10, 35, 'equip-ring-legendary', false, NULL, true, 125),
-- Amulets
('acc_amulet_common_01', 'Wooden Totem Necklace', 'A carved token on a hemp cord. You tell people it''s enchanted. They smile politely.', 'accessory', 'amulet', 'common', 'luck', 2, NULL, 0, 1, 'equip-amulet-common', false, NULL, true, 126),
('acc_amulet_uncommon_01', 'Jade Guardian Amulet', 'Wards off minor hexes and major conversations. Introverts swear by it.', 'accessory', 'amulet', 'uncommon', 'defense', 3, 'wisdom', 2, 5, 'equip-amulet-uncommon', false, NULL, true, 127),
('acc_amulet_rare_01', 'Phoenix Feather Talisman', 'Plucked from a phoenix mid-sneeze. The bird was furious, but what''s it gonna do — die?', 'accessory', 'amulet', 'rare', 'wisdom', 5, 'luck', 4, 12, 'equip-amulet-rare', false, NULL, true, 128),
('acc_amulet_epic_01', 'Eye of the Storm', 'Houses a genuine tiny thunderstorm. The HOA inside is livid about the property damage.', 'accessory', 'amulet', 'epic', 'wisdom', 9, 'defense', 5, 22, 'equip-amulet-epic', false, NULL, true, 129),
('acc_amulet_legendary_01', 'Heart of the World Tree', 'Yggdrasil''s actual beating heart, donated willingly. Just kidding — someone stole it. The tree is still upset.', 'accessory', 'amulet', 'legendary', 'wisdom', 15, 'luck', 9, 38, 'equip-amulet-legendary', false, NULL, true, 130),
-- Earrings
('acc_earring_common_01', 'Copper Stud', 'Your ear turns green, your stats go up by one. The math checks out if you don''t think about it.', 'accessory', 'earring', 'common', 'luck', 1, NULL, 0, 1, 'equip-earring-common', false, NULL, true, 131),
('acc_earring_uncommon_01', 'Silver Earring', 'Glints suggestively when fortune is nearby. Won''t warn you about misfortune, though. Bit of a one-trick pony.', 'accessory', 'earring', 'uncommon', 'luck', 3, 'charisma', 2, 4, 'equip-earring-uncommon', false, NULL, true, 132),
('acc_earring_rare_01', 'Gold Earring', 'Won by a pirate in a card game against Lady Luck herself. She let him win. She always lets them win.', 'accessory', 'earring', 'rare', 'luck', 6, 'charisma', 3, 12, 'equip-earring-rare', false, NULL, true, 133),
('acc_earring_epic_01', 'Gemmed Earring', 'A perfect ruby that whispers probability equations directly into your ear canal. Unsettling, but statistically significant.', 'accessory', 'earring', 'epic', 'luck', 9, 'wisdom', 5, 21, 'equip-earring-epic', false, NULL, true, 134),
('acc_earring_legendary_01', 'Earring of Fate', 'Woven from a literal thread of destiny. The Fates sent a cease-and-desist, but it got lost in the mail. Convenient.', 'accessory', 'earring', 'legendary', 'luck', 15, 'charisma', 9, 36, 'equip-earring-legendary', false, NULL, true, 135),
-- Talismans
('acc_talisman_common_01', 'Wooden Talisman', 'Hand-carved from a sacred tree that was, honestly, just a regular tree with good PR.', 'accessory', 'talisman', 'common', 'wisdom', 1, NULL, 0, 1, 'equip-talisman-common', false, NULL, true, 136),
('acc_talisman_uncommon_01', 'Carved Talisman', 'Covered in runes that roughly translate to ''please work please work please work.''', 'accessory', 'talisman', 'uncommon', 'wisdom', 3, 'defense', 2, 5, 'equip-talisman-uncommon', false, NULL, true, 137),
('acc_talisman_rare_01', 'Enchanted Talisman', 'A monk meditated for forty years to enchant this. Halfway through he forgot why. The confusion somehow made it stronger.', 'accessory', 'talisman', 'rare', 'wisdom', 5, 'luck', 4, 12, 'equip-talisman-rare', false, NULL, true, 138),
('acc_talisman_epic_01', 'Ancient Talisman', 'Pre-dates recorded history, which is just a fancy way of saying nobody kept the receipt.', 'accessory', 'talisman', 'epic', 'wisdom', 9, 'defense', 5, 22, 'equip-talisman-epic', false, NULL, true, 139),
('acc_talisman_legendary_01', 'Talisman of the Void', 'Contains a pocket of pure nothingness. Existentially terrifying. Excellent stats though, so you learn to cope.', 'accessory', 'talisman', 'legendary', 'wisdom', 14, 'luck', 10, 38, 'equip-talisman-legendary', false, NULL, true, 140),
-- Pendants
('acc_pendant_common_01', 'Tarnished Pendant', 'It''s either bronze or really committed copper. Nobody''s brave enough to polish it and find out.', 'accessory', 'pendant', 'common', 'charisma', 1, NULL, 0, 1, 'equip-pendant-common', false, NULL, true, 141),
('acc_pendant_uncommon_01', 'Moonstone Pendant', 'Glows faintly at night. Mostly useful for finding the bathroom without stubbing your toe.', 'accessory', 'pendant', 'uncommon', 'charisma', 3, 'wisdom', 1, 5, 'equip-pendant-uncommon', false, NULL, true, 142),
('acc_pendant_rare_01', 'Serpent''s Eye Pendant', 'The gemstone follows your gaze. Creepy? Yes. Fashionable? Also yes.', 'accessory', 'pendant', 'rare', 'charisma', 6, 'dexterity', 3, 12, 'equip-pendant-rare', false, NULL, true, 143),
('acc_pendant_epic_01', 'Heartstone Pendant', 'Pulses in sync with its wearer''s heartbeat. Cardiology wizards are deeply conflicted about this.', 'accessory', 'pendant', 'epic', 'charisma', 10, 'luck', 4, 22, 'equip-pendant-epic', false, NULL, true, 144),
('acc_pendant_legendary_01', 'Pendant of the Eternal Flame', 'Houses a flame that has burned since before time. Great conversation starter. Terrible pillow.', 'accessory', 'pendant', 'legendary', 'charisma', 15, 'wisdom', 8, 36, 'equip-pendant-legendary', false, NULL, true, 145),
-- Brooches
('acc_brooch_common_01', 'Bent Pin Brooch', 'Technically jewelry. Technically.', 'accessory', 'brooch', 'common', 'defense', 1, NULL, 0, 1, 'equip-brooch-common', false, NULL, true, 146),
('acc_brooch_uncommon_01', 'Silver Leaf Brooch', 'Shaped like an autumn leaf. The silversmith was ''going through a nature phase.''', 'accessory', 'brooch', 'uncommon', 'defense', 3, 'charisma', 1, 5, 'equip-brooch-uncommon', false, NULL, true, 147),
('acc_brooch_rare_01', 'Phoenix Feather Brooch', 'Warm to the touch and occasionally catches fire. Dry clean only.', 'accessory', 'brooch', 'rare', 'defense', 6, 'luck', 3, 12, 'equip-brooch-rare', false, NULL, true, 148),
('acc_brooch_epic_01', 'Dragon''s Crest Brooch', 'Grants the wearer an air of authority. Also makes you smell faintly of sulfur.', 'accessory', 'brooch', 'epic', 'defense', 9, 'strength', 5, 22, 'equip-brooch-epic', false, NULL, true, 149),
('acc_brooch_legendary_01', 'Brooch of the First King', 'Worn by the first king of the realm. He lost it in a bet. Kings are terrible gamblers.', 'accessory', 'brooch', 'legendary', 'defense', 14, 'charisma', 9, 36, 'equip-brooch-legendary', false, NULL, true, 150),
-- Charms
('trk_charm_common_01', 'Lucky Penny Charm', 'Found heads-up in a puddle. Your luck stat says +2 but your dignity says -10.', 'trinket', 'charm', 'common', 'luck', 2, NULL, 0, 1, 'equip-charm-common', false, NULL, true, 151),
('trk_charm_uncommon_01', 'Four-Leaf Crystal', 'Statistically, you''d find a four-leaf clover faster than a good party member. This one skips both problems.', 'trinket', 'charm', 'uncommon', 'luck', 4, 'charisma', 1, 4, 'equip-charm-uncommon', false, NULL, true, 152),
('trk_charm_rare_01', 'Heartstone Charm', 'Fell out of a love god''s pocket during a particularly messy breakup. Resonates with emotional chaos.', 'trinket', 'charm', 'rare', 'charisma', 6, 'luck', 3, 12, 'equip-charm-rare', false, NULL, true, 153),
('trk_charm_epic_01', 'Dragon''s Eye Charm', 'Sees through illusions, lies, and excuses for not doing the dishes. Terrifyingly perceptive.', 'trinket', 'charm', 'epic', 'wisdom', 8, 'luck', 6, 20, 'equip-charm-epic', false, NULL, true, 154),
('trk_charm_legendary_01', 'Wishing Star Fragment', 'A piece of a star that granted exactly one wish before crash-landing. The wish was for ''better loot drops.'' Respect.', 'trinket', 'charm', 'legendary', 'luck', 15, 'charisma', 8, 34, 'equip-charm-legendary', false, NULL, true, 155),
-- Belts
('trk_belt_common_01', 'Rope Sash', 'It holds your pants up. In a world of dragons and demons, that''s honestly the most important job.', 'trinket', 'belt', 'common', 'strength', 1, NULL, 0, 1, 'equip-belt-common', false, NULL, true, 156),
('trk_belt_uncommon_01', 'Adventurer''s Utility Belt', 'Pockets, loops, and pouches for everything. Organization is the real superpower.', 'trinket', 'belt', 'uncommon', 'dexterity', 3, 'strength', 1, 4, 'equip-belt-uncommon', false, NULL, true, 157),
('trk_belt_rare_01', 'Belt of the Marathon', 'Enchanted by a wizard who cast a marathon spell on himself, then forgot the finish line was optional. He''s still running.', 'trinket', 'belt', 'rare', 'dexterity', 5, 'strength', 3, 11, 'equip-belt-rare', false, NULL, true, 158),
('trk_belt_epic_01', 'Champion''s War Girdle', 'Forged from the accumulated ego of a hundred defeated challengers. It''s heavy, but mostly from the drama.', 'trinket', 'belt', 'epic', 'strength', 8, 'defense', 5, 22, 'equip-belt-epic', false, NULL, true, 159),
('trk_belt_legendary_01', 'Girdle of World-Bearing', 'Modeled after the belt of the titan who holds up the sky. He asked for royalties. Nobody called him back.', 'trinket', 'belt', 'legendary', 'strength', 14, 'defense', 9, 36, 'equip-belt-legendary', false, NULL, true, 160),
-- Orbs
('trk_orb_common_01', 'Cloudy Glass Orb', 'Predicts the future with all the accuracy of a coin flip. Less useful, more aesthetic.', 'trinket', 'orb', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-orb-common', false, NULL, true, 161),
('trk_orb_uncommon_01', 'Mana-Spun Orb', 'Swirling with blue energy. Touching it feels like licking a battery, but for your soul.', 'trinket', 'orb', 'uncommon', 'wisdom', 4, 'charisma', 2, 5, 'equip-orb-uncommon', false, NULL, true, 162),
('trk_orb_rare_01', 'Void-Touched Orb', 'Stare into the void. The void stares back. Then the void blinks first. You win.', 'trinket', 'orb', 'rare', 'wisdom', 7, 'luck', 3, 13, 'equip-orb-rare', false, NULL, true, 163),
('trk_orb_epic_01', 'Orb of Shattered Realities', 'Shows glimpses of parallel worlds. In most of them, you still forgot to buy milk.', 'trinket', 'orb', 'epic', 'wisdom', 11, 'charisma', 5, 24, 'equip-orb-epic', false, NULL, true, 164),
('trk_orb_legendary_01', 'Orb of the Cosmic Architect', 'Contains the blueprint for all of creation. The fine print is in a language nobody speaks.', 'trinket', 'orb', 'legendary', 'wisdom', 16, 'luck', 9, 38, 'equip-orb-legendary', false, NULL, true, 165),
-- Bracelets
('trk_bracelet_common_01', 'Frayed Friendship Bracelet', 'The friend who made this moved away. The bracelet stayed. It''s complicated.', 'trinket', 'bracelet', 'common', 'charisma', 1, NULL, 0, 1, 'equip-bracelet-common', false, NULL, true, 166),
('trk_bracelet_uncommon_01', 'Copper Chain Bracelet', 'Turns your wrist green but boosts your stats. Fashion is sacrifice.', 'trinket', 'bracelet', 'uncommon', 'charisma', 3, 'dexterity', 1, 5, 'equip-bracelet-uncommon', false, NULL, true, 167),
('trk_bracelet_rare_01', 'Serpentine Bracelet', 'Wraps around your wrist like a tiny snake. It''s not alive. Probably.', 'trinket', 'bracelet', 'rare', 'charisma', 5, 'luck', 3, 12, 'equip-bracelet-rare', false, NULL, true, 168),
('trk_bracelet_epic_01', 'Stormforged Bracelet', 'Crackles with static electricity. High-fives have never been more exciting.', 'trinket', 'bracelet', 'epic', 'charisma', 9, 'strength', 4, 22, 'equip-bracelet-epic', false, NULL, true, 169),
('trk_bracelet_legendary_01', 'Bracelet of Unbroken Bonds', 'Forged from the chains of a love that transcended death. Heavy on the wrist, heavier on the feelings.', 'trinket', 'bracelet', 'legendary', 'charisma', 14, 'luck', 8, 36, 'equip-bracelet-legendary', false, NULL, true, 170),
-- Robes (cloak slot)
('arm_robes_common_01', 'Threadbare Apprentice Robes', 'Smells like old parchment and shattered academic dreams. The previous owner was expelled for ''creative spell interpretation.''', 'cloak', 'robes', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-robes-common', false, NULL, true, 171),
('arm_robes_uncommon_01', 'Scholar''s Vestments', 'Clean, pressed, and covered in runes that roughly translate to ''please don''t hit me.''', 'cloak', 'robes', 'uncommon', 'wisdom', 4, 'charisma', 2, 5, 'equip-robes-uncommon', false, NULL, true, 172),
('arm_robes_rare_01', 'Astral Silkweave', 'Woven by spiders from a dimension where fashion is the highest form of magic. Dry clean only — in that dimension.', 'cloak', 'robes', 'rare', 'wisdom', 7, 'defense', 2, 13, 'equip-robes-rare', false, NULL, true, 173),
('arm_robes_epic_01', 'Mantle of the Archmage', 'Spells weave themselves into the fabric. The robes actively deflect hostile magic.', 'cloak', 'robes', 'epic', 'wisdom', 10, 'defense', 5, 24, 'equip-robes-epic', false, NULL, true, 174),
('arm_robes_legendary_01', 'Cosmos Regalia', 'Woven from the dreams of a thousand sleeping wizards. Smells like lavender and existential dread.', 'cloak', 'robes', 'legendary', 'wisdom', 16, 'luck', 9, 38, 'equip-robes-legendary', false, NULL, true, 175),
-- Standard Cloaks
('trk_cloak_common_01', 'Moth-Eaten Travel Cape', 'The moths ate most of it. The remaining fabric stays out of loyalty. Or maybe habit.', 'cloak', 'cloak', 'common', 'defense', 1, NULL, 0, 1, 'equip-cloak-common', false, NULL, true, 176),
('trk_cloak_uncommon_01', 'Twilight Mantle', 'Absorbs light so well you once lost it in your own shadow. Finding it required a torch and emotional support.', 'cloak', 'cloak', 'uncommon', 'dexterity', 3, 'defense', 1, 5, 'equip-cloak-uncommon', false, NULL, true, 177),
('trk_cloak_rare_01', 'Windweaver''s Shroud', 'Woven by a tailor who got struck by lightning mid-stitch. The static cling is permanent but so is the speed boost.', 'cloak', 'cloak', 'rare', 'dexterity', 5, 'luck', 3, 13, 'equip-cloak-rare', false, NULL, true, 178),
('trk_cloak_epic_01', 'Cloak of Many Stars', 'Shows a different constellation each night. Last Tuesday it showed one that spelled out ''WASH ME.''', 'cloak', 'cloak', 'epic', 'wisdom', 8, 'dexterity', 5, 21, 'equip-cloak-epic', false, NULL, true, 179),
('trk_cloak_legendary_01', 'Mantle of the Unseen', 'Woven from pure possibility. You can be anywhere and nowhere at once — mostly nowhere, because you forgot where you left it.', 'cloak', 'cloak', 'legendary', 'dexterity', 13, 'luck', 10, 36, 'equip-cloak-legendary', false, NULL, true, 180),
-- Mantles
('clk_mantle_common_01', 'Tattered War Mantle', 'Survived more battles than its owner. Currently winning on pure stubbornness.', 'cloak', 'mantle', 'common', 'defense', 2, NULL, 0, 1, 'equip-mantle-common', false, NULL, true, 181),
('clk_mantle_uncommon_01', 'Iron-Trimmed Mantle', 'The iron trim makes it defensive. The weight makes stairs your new nemesis.', 'cloak', 'mantle', 'uncommon', 'defense', 4, 'strength', 2, 5, 'equip-mantle-uncommon', false, NULL, true, 182),
('clk_mantle_rare_01', 'Warlord''s Mantle', 'Worn by a warlord who conquered twelve kingdoms. He''s retired now. Runs a bakery.', 'cloak', 'mantle', 'rare', 'defense', 7, 'strength', 3, 13, 'equip-mantle-rare', false, NULL, true, 183),
('clk_mantle_epic_01', 'Titan''s Mantle', 'Sized for a titan, tailored for a human. The alterations alone cost a small fortune.', 'cloak', 'mantle', 'epic', 'defense', 11, 'strength', 5, 24, 'equip-mantle-epic', false, NULL, true, 184),
('clk_mantle_legendary_01', 'Mantle of the Mountain King', 'Carved from living granite. Literally rock-solid defense. Dry cleaners refuse it on sight.', 'cloak', 'mantle', 'legendary', 'defense', 16, 'luck', 8, 38, 'equip-mantle-legendary', false, NULL, true, 185),
-- Capes
('clk_cape_common_01', 'Dusty Traveler''s Cape', 'Collects dust, memories, and an unreasonable number of burrs.', 'cloak', 'cape', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-cape-common', false, NULL, true, 186),
('clk_cape_uncommon_01', 'Woodland Cape', 'Dyed forest green. Perfect camouflage if you stand perfectly still. Forever.', 'cloak', 'cape', 'uncommon', 'dexterity', 4, 'luck', 2, 5, 'equip-cape-uncommon', false, NULL, true, 187),
('clk_cape_rare_01', 'Windrunner''s Cape', 'Aerodynamically designed for maximum dramatic billowing. Function follows fashion.', 'cloak', 'cape', 'rare', 'dexterity', 7, 'luck', 3, 13, 'equip-cape-rare', false, NULL, true, 188),
('clk_cape_epic_01', 'Shadowstep Cape', 'Lets you melt into shadows. Terrible at parties. Incredible at leaving them unnoticed.', 'cloak', 'cape', 'epic', 'dexterity', 11, 'luck', 5, 24, 'equip-cape-epic', false, NULL, true, 189),
('clk_cape_legendary_01', 'Cape of the Phantom Archer', 'Grants near-invisibility. Your arrows arrive before your enemies know you exist.', 'cloak', 'cape', 'legendary', 'dexterity', 16, 'luck', 9, 38, 'equip-cape-legendary', false, NULL, true, 190)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- MILESTONE GEAR (36 items from MilestoneGearCatalog.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_milestone_gear (id, name, description, slot, base_type, rarity, primary_stat, stat_bonus, secondary_stat, secondary_stat_bonus, level_requirement, character_class, gold_cost, image_name, active, sort_order) VALUES
('ms_warrior_lv5', 'Warrior''s Faithful Blade', 'Technically just a sword, but the merchant who sold it insists the loyalty is built-in.', 'weapon', 'sword', 'uncommon', 'strength', 4, 'defense', 1, 5, 'warrior', 80, NULL, true, 1),
('ms_warrior_lv10', 'Guardian''s Iron Plate', 'Commissioned by a knight who was tired of dying. The blacksmith added extra iron where the complaints were loudest.', 'armor', 'plate', 'rare', 'defense', 6, 'strength', 2, 10, 'warrior', 200, NULL, true, 2),
('ms_warrior_lv15', 'Warcry Pendant', 'Originally a dinner bell from a very angry chef. Turns out screaming at people is transferable technology.', 'accessory', 'pendant', 'rare', 'strength', 5, 'charisma', 3, 15, 'warrior', 320, NULL, true, 3),
('ms_warrior_lv20', 'Champion''s Greatsword', 'Wielded by a champion who defeated 10,000 foes, then retired to open a bakery. The sword did not approve.', 'weapon', 'sword', 'epic', 'strength', 9, 'dexterity', 4, 20, 'warrior', 600, NULL, true, 4),
('ms_mage_lv5', 'Apprentice''s Focus Staff', 'Helps you focus your magic. Also works as a walking stick, which honestly sees more use.', 'weapon', 'staff', 'uncommon', 'wisdom', 4, 'luck', 1, 5, 'mage', 80, NULL, true, 5),
('ms_mage_lv10', 'Arcane Silk Robes', 'Woven by spiders who minored in thaumaturgy. They still send invoices.', 'armor', 'robes', 'rare', 'wisdom', 6, 'defense', 2, 10, 'mage', 200, NULL, true, 6),
('ms_mage_lv15', 'Mystic Charm', 'Found in a wizard''s junk drawer labeled ''miscellaneous power.'' Nobody knows what it does, but the stats don''t lie.', 'accessory', 'charm', 'rare', 'wisdom', 5, 'luck', 3, 15, 'mage', 320, NULL, true, 7),
('ms_mage_lv20', 'Sorcerer''s Orb Staff', 'The orb floats menacingly. The staff is just there for emotional support. Together, they make your enemies deeply uncomfortable.', 'weapon', 'staff', 'epic', 'wisdom', 9, 'charisma', 4, 20, 'mage', 600, NULL, true, 8),
('ms_archer_lv5', 'Scout''s Shortbow', 'Light enough that you''ll forget you''re carrying it. You''ll also forget to reload, but that''s a you problem.', 'weapon', 'bow', 'uncommon', 'dexterity', 4, 'luck', 1, 5, 'archer', 80, NULL, true, 9),
('ms_archer_lv10', 'Ranger''s Leather Armor', 'Crafted by a tanner who was also a ninja. It''s silent because the tanner refuses to tell anyone his secrets.', 'armor', 'leather armor', 'rare', 'dexterity', 6, 'defense', 2, 10, 'archer', 200, NULL, true, 10),
('ms_archer_lv15', 'Eagle-Eye Ring', 'Enchanted by an optometrist who got lost on the way to a wizarding convention. You can read signs from three kingdoms away.', 'accessory', 'ring', 'rare', 'dexterity', 5, 'luck', 3, 15, 'archer', 320, NULL, true, 11),
('ms_archer_lv20', 'Windrunner''s Longbow', 'Arrows arrive before the archer finishes their dramatic one-liner. Very inconsiderate.', 'weapon', 'bow', 'epic', 'dexterity', 9, 'strength', 4, 20, 'archer', 600, NULL, true, 12),
('ms_berserker_lv25', 'Rage-Forged Axe', 'The blacksmith was having a really bad day. Like, a historically bad day. Anyway, the axe turned out great.', 'weapon', 'axe', 'epic', 'strength', 10, 'dexterity', 4, 25, 'berserker', 750, NULL, true, 13),
('ms_berserker_lv30', 'Berserker''s War Plate', 'The spikes are decorative. The rage is structural. Enemies don''t know the difference, and that''s the whole point.', 'armor', 'plate', 'epic', 'strength', 8, 'defense', 5, 30, 'berserker', 900, NULL, true, 14),
('ms_berserker_lv40', 'Blood Fury Bracelet', 'Forged in the heart of a dying star by an ancient being of unfathomable power. He was also running late for dinner, so the craftsmanship is a bit uneven.', 'accessory', 'bracelet', 'legendary', 'strength', 14, 'dexterity', 6, 40, 'berserker', 1500, NULL, true, 15),
('ms_berserker_lv50', 'Worldsplitter', 'Prophesied to cleave the world in two. It hasn''t yet, but everyone''s too afraid to ask if it''s even trying.', 'weapon', 'axe', 'legendary', 'strength', 16, 'defense', 8, 50, 'berserker', 2500, NULL, true, 16),
('ms_paladin_lv25', 'Oathkeeper Mace', 'Glows when evil is near, which is convenient. Also glows near expired milk, which is less heroic but arguably more useful.', 'weapon', 'mace', 'epic', 'defense', 10, 'strength', 4, 25, 'paladin', 750, NULL, true, 17),
('ms_paladin_lv30', 'Sanctified Shield Plate', 'Blessed by seventeen different clerics as a precaution. Fourteen of those blessings are redundant, but nobody wants to say so.', 'armor', 'plate', 'epic', 'defense', 9, 'wisdom', 4, 30, 'paladin', 900, NULL, true, 18),
('ms_paladin_lv40', 'Amulet of Devotion', 'Handed down through generations of paladins, each adding their own prayer. The last one accidentally added a grocery list, but the amulet accepted it anyway.', 'accessory', 'amulet', 'legendary', 'defense', 14, 'charisma', 6, 40, 'paladin', 1500, NULL, true, 19),
('ms_paladin_lv50', 'Dawn''s Embrace', 'Forged from crystallized sunlight by an angel on a deadline. Impervious to darkness, criticism, and mild staining.', 'armor', 'plate', 'legendary', 'defense', 16, 'strength', 8, 50, 'paladin', 2500, NULL, true, 20),
('ms_sorcerer_lv25', 'Voidweaver Staff', 'Draws power from the void between worlds. The void didn''t agree to this arrangement, but what''s it going to do? It''s a void.', 'weapon', 'staff', 'epic', 'wisdom', 10, 'luck', 4, 25, 'sorcerer', 750, NULL, true, 21),
('ms_sorcerer_lv30', 'Astral Silk Vestment', 'Sewn from actual starlight, which was a logistical nightmare. The tailor charged triple and honestly deserved more.', 'armor', 'robes', 'epic', 'wisdom', 8, 'defense', 5, 30, 'sorcerer', 900, NULL, true, 22),
('ms_sorcerer_lv40', 'Infinity Loop Ring', 'Bends mana in a perpetual cycle, granting limitless power. The ring''s terms of service are 400 pages long and nobody has read them.', 'accessory', 'ring', 'legendary', 'wisdom', 14, 'luck', 6, 40, 'sorcerer', 1500, NULL, true, 23),
('ms_sorcerer_lv50', 'Archmage''s Epoch Staff', 'Its creator transcended mortality through pure knowledge. He''s still out there somewhere, refusing to answer questions about the warranty.', 'weapon', 'staff', 'legendary', 'wisdom', 16, 'charisma', 8, 50, 'sorcerer', 2500, NULL, true, 24),
('ms_enchanter_lv25', 'Harmonist''s Wand', 'Resonates with the emotions of allies. Unfortunately, this includes when they''re annoyed at you for standing in the fire.', 'weapon', 'wand', 'epic', 'charisma', 10, 'wisdom', 4, 25, 'enchanter', 750, NULL, true, 25),
('ms_enchanter_lv30', 'Moonshadow Robes', 'Shimmer beautifully under moonlight. Under fluorescent lighting, they just look like a bathrobe. Choose your battles wisely.', 'armor', 'robes', 'epic', 'charisma', 8, 'defense', 5, 30, 'enchanter', 900, NULL, true, 26),
('ms_enchanter_lv40', 'Crown of Whispers', 'Lets the wearer hear the unspoken needs of allies. Mostly it''s snacks. The unspoken need is almost always snacks.', 'accessory', 'charm', 'legendary', 'charisma', 14, 'wisdom', 6, 40, 'enchanter', 1500, NULL, true, 27),
('ms_enchanter_lv50', 'Eternal Harmony Wand', 'Binds the spirits of allies into an unbreakable bond. Previous owners report a strong urge to start a book club. There is no known cure.', 'weapon', 'wand', 'legendary', 'charisma', 16, 'wisdom', 8, 50, 'enchanter', 2500, NULL, true, 28),
('ms_ranger_lv25', 'Galeforce Bow', 'Fires arrows faster than the eye can follow, which makes showing off to your friends completely pointless.', 'weapon', 'bow', 'epic', 'dexterity', 10, 'luck', 4, 25, 'ranger', 750, NULL, true, 29),
('ms_ranger_lv30', 'Forestwalker Armor', 'Grown from enchanted bark that''s technically still alive. It judges your posture silently but constantly.', 'armor', 'leather armor', 'epic', 'dexterity', 8, 'defense', 5, 30, 'ranger', 900, NULL, true, 30),
('ms_ranger_lv40', 'Hawk''s Talon Bracelet', 'Carved from the claw of a great hawk who reportedly gave it willingly. The hawk''s lawyer tells a different story.', 'accessory', 'bracelet', 'legendary', 'dexterity', 14, 'luck', 6, 40, 'ranger', 1500, NULL, true, 31),
('ms_ranger_lv50', 'Skypierce, the Eternal Bow', 'Wielded by the first ranger who ever walked the wilds. She later trademarked the word ''nature'' and this bow is the receipt.', 'weapon', 'bow', 'legendary', 'dexterity', 16, 'strength', 8, 50, 'ranger', 2500, NULL, true, 32),
('ms_trickster_lv25', 'Fate''s Edge Dagger', 'Guides itself toward weak points, as if destiny wills it. Destiny is apparently very passive-aggressive.', 'weapon', 'dagger', 'epic', 'luck', 10, 'dexterity', 4, 25, 'trickster', 750, NULL, true, 33),
('ms_trickster_lv30', 'Phantom Cloak', 'Woven from shadow itself, which was surprisingly cooperative once you offered it health insurance.', 'cloak', 'cloak', 'epic', 'luck', 8, 'dexterity', 5, 30, 'trickster', 900, NULL, true, 34),
('ms_trickster_lv40', 'Gambler''s Loaded Dice', 'Bends probability in your favor, which technically isn''t cheating because nobody wrote a rule against magical dice. Yet.', 'accessory', 'charm', 'legendary', 'luck', 14, 'charisma', 6, 40, 'trickster', 1500, NULL, true, 35),
('ms_trickster_lv50', 'Whisper of Chaos', 'Exists in multiple timelines simultaneously. In three of them, you already won. In one, you''re a duck. Best not to think about it.', 'weapon', 'dagger', 'legendary', 'luck', 16, 'dexterity', 8, 50, 'trickster', 2500, NULL, true, 36)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- GEAR SETS (3 sets from GearSetCatalog.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_gear_sets (id, name, description, character_class_line, pieces_required, bonus_stat, bonus_amount, bonus_description, bonus_type, bonus_value, level_requirement, active) VALUES
('set_warrior', 'Vanguard''s Resolve', 'The official uniform of people who solve problems by standing in front of them. Equip any 2 pieces for +10% Defense in dungeons.', 'warrior', 3, 'defense', 5, 'Equip any 2 pieces for +10% Defense in dungeons', 'flat', 5.0, 8, true),
('set_mage', 'Arcanum''s Embrace', 'Robes that hug you with pure arcane energy. It''s not weird, it''s magical. Equip any 2 pieces for -10% AFK mission time.', 'mage', 3, 'wisdom', 5, 'Equip any 2 pieces for -10% AFK mission time', 'flat', 5.0, 8, true),
('set_archer', 'Windstrider''s Mark', 'For archers who want to look fast while standing completely still. Equip any 2 pieces for +10% loot drop chance.', 'archer', 3, 'dexterity', 5, 'Equip any 2 pieces for +10% loot drop chance', 'flat', 5.0, 8, true)
ON CONFLICT (id) DO NOTHING;

-- Mark gear set pieces in equipment table
UPDATE public.content_equipment SET is_set_piece = true, set_id = 'set_warrior' WHERE id IN ('wep_sword_uncommon_01', 'arm_plate_uncommon_01', 'acc_amulet_uncommon_01');
UPDATE public.content_equipment SET is_set_piece = true, set_id = 'set_mage' WHERE id IN ('wep_staff_uncommon_01', 'arm_robes_uncommon_01', 'acc_charm_uncommon_01');
UPDATE public.content_equipment SET is_set_piece = true, set_id = 'set_archer' WHERE id IN ('wep_bow_uncommon_01', 'arm_leather_uncommon_01', 'acc_ring_uncommon_01');


-- -----------------------------------------------------------
-- CONSUMABLES (22 items from Consumable.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_consumables (id, name, description, consumable_type, icon, effect_value, effect_stat, duration_seconds, gold_cost, gem_cost, level_requirement, tier, is_premium, max_stack, active, sort_order) VALUES
('herbal_tea', 'Herbal Tea', 'A warm soothing blend that restores vitality.', 'hp_potion', 'cup.and.saucer.fill', 20, NULL, NULL, 30, 0, 1, 'common', false, 99, true, 1),
('healing_draught', 'Healing Draught', 'A potent medicinal brew for deep restoration.', 'hp_potion', 'cross.vial.fill', 50, NULL, NULL, 80, 0, 5, 'common', false, 99, true, 2),
('greater_healing_draught', 'Greater Healing Draught', 'A masterfully brewed elixir of powerful restoration.', 'hp_potion', 'cross.vial.fill', 100, NULL, NULL, 200, 0, 15, 'uncommon', false, 99, true, 3),
('supreme_elixir', 'Supreme Elixir', 'A legendary potion that can mend even the gravest wounds.', 'hp_potion', 'cross.vial.fill', 200, NULL, NULL, 500, 0, 30, 'rare', false, 99, true, 4),
('energy_bar', 'Energy Bar', 'A packed snack that sharpens focus. +50% EXP for 3 tasks.', 'exp_boost', 'bolt.fill', 3, NULL, NULL, 60, 0, 3, 'common', false, 99, true, 5),
('power_bar', 'Power Bar', 'Premium energy snack. +50% EXP for 5 tasks.', 'exp_boost', 'bolt.fill', 5, NULL, NULL, 150, 0, 12, 'uncommon', false, 99, true, 6),
('mega_energy_bar', 'Mega Energy Bar', 'Elite performance fuel. +50% EXP for 8 tasks.', 'exp_boost', 'bolt.circle.fill', 8, NULL, NULL, 300, 0, 20, 'rare', false, 99, true, 7),
('lucky_coin', 'Lucky Coin', 'A glimmering coin that attracts fortune. +50% Gold for 3 tasks.', 'gold_boost', 'dollarsign.circle.fill', 3, NULL, NULL, 50, 0, 3, 'common', false, 99, true, 8),
('fortune_stone', 'Fortune Stone', 'A polished gem that radiates prosperity. +50% Gold for 5 tasks.', 'gold_boost', 'dollarsign.circle.fill', 5, NULL, NULL, 120, 0, 12, 'uncommon', false, 99, true, 9),
('golden_chalice', 'Golden Chalice', 'An enchanted chalice overflowing with fortune. +50% Gold for 8 tasks.', 'gold_boost', 'cup.and.saucer.fill', 8, NULL, NULL, 280, 0, 20, 'rare', false, 99, true, 10),
('espresso_shot', 'Espresso Shot', 'A jolt of energy that speeds everything up.', 'mission_speed_up', 'cup.and.saucer.fill', 1, NULL, NULL, 40, 0, 5, 'common', false, 99, true, 11),
('cozy_blanket', 'Cozy Blanket', 'Wraps you in comfort, protecting your streak for a day.', 'streak_shield', 'shield.checkered', 1, NULL, NULL, 100, 0, 5, 'uncommon', false, 99, true, 12),
('enchanted_cloak', 'Enchanted Cloak', 'A magically woven cloak that shields your streak for 3 days.', 'streak_shield', 'shield.checkered', 3, NULL, NULL, 350, 0, 15, 'rare', false, 99, true, 13),
('protein_shake', 'Protein Shake', 'A thick creamy shake packed with muscle fuel.', 'stat_food', 'dumbbell.fill', 3, 'strength', NULL, 45, 0, 3, 'common', false, 99, true, 14),
('green_tea', 'Green Tea', 'A calming brew that clears the mind.', 'stat_food', 'leaf.fill', 3, 'wisdom', NULL, 45, 0, 3, 'common', false, 99, true, 15),
('trail_mix', 'Trail Mix', 'A hearty snack of nuts and dried fruit for agility.', 'stat_food', 'carrot.fill', 3, 'dexterity', NULL, 45, 0, 3, 'common', false, 99, true, 16),
('power_meal', 'Power Meal', 'A champion''s feast surging with raw strength.', 'stat_food', 'dumbbell.fill', 5, 'strength', NULL, 150, 0, 15, 'uncommon', false, 99, true, 17),
('sage_tea', 'Sage Tea', 'A rare herbal infusion brewed by scholars.', 'stat_food', 'leaf.fill', 5, 'wisdom', NULL, 150, 0, 15, 'uncommon', false, 99, true, 18),
('swift_berries', 'Swift Berries', 'Enchanted berries that quicken reflexes.', 'stat_food', 'carrot.fill', 5, 'dexterity', NULL, 150, 0, 15, 'uncommon', false, 99, true, 19),
('revive_token', 'Revive Token', 'A phoenix feather that can revive a fallen dungeon party.', 'dungeon_revive', 'arrow.counterclockwise.circle.fill', 1, NULL, NULL, 0, 5, 10, 'rare', true, 99, true, 20),
('loot_reroll', 'Loot Reroll', 'A magical die that reshapes equipment stats.', 'loot_reroll', 'dice.fill', 1, NULL, NULL, 0, 3, 10, 'rare', true, 99, true, 21),
('instant_mission_scroll', 'Instant Mission Scroll', 'A scroll of haste that instantly completes a mission.', 'mission_speed_up', 'bolt.circle.fill', 1, NULL, NULL, 0, 5, 10, 'rare', true, 99, true, 22)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- DUNGEON TEMPLATES (6 dungeons from Dungeon.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_dungeons (id, name, description, theme, difficulty, level_requirement, recommended_stat_total, max_party_size, base_exp_reward, base_gold_reward, loot_tier, rooms, is_party_only, party_bond_level_req, active, sort_order) VALUES
('dungeon_goblin_caves', 'Goblin Caves', 'A network of shallow caves infested with goblins.', 'cave', 'normal', 1, 30, 2, 150, 80, 1,
 '[{"name":"Cave Entrance","description":"Goblins guard the entrance.","encounter_type":"combat","primary_stat":"strength","difficulty_rating":12,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Trapped Corridor","description":"Pit traps line the corridor.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":10,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Goblin Chief","description":"The goblin chief awaits!","encounter_type":"boss","primary_stat":"strength","difficulty_rating":18,"is_boss_room":true,"bonus_loot_chance":0.3}]'::jsonb,
 false, 0, true, 1),
('dungeon_ancient_ruins', 'Ancient Ruins', 'Crumbling ruins filled with ancient puzzles.', 'ruins', 'normal', 5, 45, 2, 300, 175, 2,
 '[{"name":"The Entry Hall","description":"Faded murals. A puzzle blocks the path.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":14,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Guardian Chamber","description":"Stone golems awaken!","encounter_type":"combat","primary_stat":"strength","difficulty_rating":16,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Treasure Vault","description":"A hidden vault glimmers.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":10,"is_boss_room":false,"bonus_loot_chance":0.5},{"name":"The Sealed Door","description":"An ancient mechanism guards the chamber.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":20,"is_boss_room":true,"bonus_loot_chance":0.35}]'::jsonb,
 false, 0, true, 2),
('dungeon_shadow_forest', 'Shadow Forest', 'An enchanted forest where shadows are alive.', 'forest', 'hard', 10, 60, 2, 500, 300, 3,
 '[{"name":"Whispering Path","description":"The trees watch your every move.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":20,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Spider Nest","description":"Giant spiders descend!","encounter_type":"combat","primary_stat":"dexterity","difficulty_rating":22,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"The Riddle Tree","description":"An ancient treant blocks the path.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":24,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Shadow Ambush","description":"Living shadows attack!","encounter_type":"combat","primary_stat":"dexterity","difficulty_rating":26,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"The Forest Heart","description":"The corrupted heart pulses with dark energy.","encounter_type":"boss","primary_stat":"charisma","difficulty_rating":30,"is_boss_room":true,"bonus_loot_chance":0.4}]'::jsonb,
 false, 0, true, 3),
('dungeon_iron_fortress', 'Iron Fortress', 'A heavily fortified stronghold.', 'fortress', 'hard', 15, 80, 2, 700, 425, 3,
 '[{"name":"The Gates","description":"Massive iron gates block the entrance.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":25,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Guard Barracks","description":"Alert guards rush to stop you!","encounter_type":"combat","primary_stat":"strength","difficulty_rating":28,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Trapped Armory","description":"Explosive traps fill the armory!","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":26,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"The War Room","description":"The commander can be defeated by blade or words.","encounter_type":"combat","primary_stat":"charisma","difficulty_rating":30,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Fortress Vault","description":"The legendary vault lies before you.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":20,"is_boss_room":false,"bonus_loot_chance":0.6},{"name":"The Iron Warden","description":"A massive construct guards the depths!","encounter_type":"boss","primary_stat":"strength","difficulty_rating":35,"is_boss_room":true,"bonus_loot_chance":0.45}]'::jsonb,
 false, 0, true, 4),
('dungeon_dragons_peak', 'Dragon''s Peak', 'Scale the volcanic peak where an ancient dragon hoards untold riches.', 'volcano', 'heroic', 25, 100, 2, 1400, 850, 4,
 '[{"name":"Lava Fields","description":"Molten rivers block the path.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":32,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Fire Elementals","description":"Creatures of pure flame block your ascent!","encounter_type":"combat","primary_stat":"strength","difficulty_rating":35,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Dragon Riddle","description":"Ancient draconic runes must be deciphered.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":38,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Wyvern Ambush","description":"Lesser dragons swoop down from above!","encounter_type":"combat","primary_stat":"dexterity","difficulty_rating":36,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Dragon Hoard","description":"Mountains of gold and rare artifacts!","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":25,"is_boss_room":false,"bonus_loot_chance":0.7},{"name":"Atherion the Ancient","description":"The ancient dragon awakens!","encounter_type":"boss","primary_stat":"dexterity","difficulty_rating":45,"is_boss_room":true,"bonus_loot_chance":0.6}]'::jsonb,
 false, 0, true, 5),
('dungeon_the_abyss', 'The Abyss', 'The deepest, darkest dungeon known to exist.', 'abyss', 'mythic', 40, 140, 2, 2800, 1700, 5,
 '[{"name":"The Void Gate","description":"Reality bends as you step through.","encounter_type":"puzzle","primary_stat":"wisdom","difficulty_rating":42,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Hall of Shadows","description":"Your shadow detaches and attacks!","encounter_type":"combat","primary_stat":"strength","difficulty_rating":45,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Labyrinth of Madness","description":"The walls shift. Trust nothing.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":44,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"The Negotiator","description":"A demon offers a deal.","encounter_type":"puzzle","primary_stat":"charisma","difficulty_rating":46,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Stamina Trial","description":"An endless corridor saps your will.","encounter_type":"trap","primary_stat":"dexterity","difficulty_rating":48,"is_boss_room":false,"bonus_loot_chance":0.0},{"name":"Fortune Edge","description":"A chamber of pure chaos.","encounter_type":"treasure","primary_stat":"luck","difficulty_rating":40,"is_boss_room":false,"bonus_loot_chance":0.8},{"name":"The Abyssal Lord","description":"The ruler of the Abyss awaits.","encounter_type":"boss","primary_stat":"strength","difficulty_rating":55,"is_boss_room":true,"bonus_loot_chance":0.75}]'::jsonb,
 false, 0, true, 6)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- CLASS-SPECIFIC TRAINING (replaces old generic AFK missions)
-- Warrior line: Strength/Defense focus
-- Mage line: Wisdom/Charisma focus
-- Archer line: Dexterity/Luck focus
-- -----------------------------------------------------------
INSERT INTO public.content_missions (id, name, description, mission_type, rarity, duration_seconds, stat_requirements, level_requirement, base_success_rate, exp_reward, gold_reward, can_drop_equipment, possible_drops, active, sort_order, class_requirement, training_stat) VALUES
-- Warrior Training
('train_warrior_strength',     'Strength Training',    'Lift heavy stones and swing weighted weapons to build raw power.',                    'combat', 'common',   1800,  '[]'::jsonb,                                              1,  0.95, 20,  5,  false, '[]'::jsonb, true, 1,  'warrior', 'Strength'),
('train_warrior_sparring',     'Sparring Practice',    'Trade blows with a training dummy to sharpen your combat instincts.',                'combat', 'common',   3600,  '[{"stat":"strength","value":6}]'::jsonb,                 3,  0.90, 40,  10, false, '[]'::jsonb, true, 2,  'warrior', 'Strength'),
('train_warrior_shield',       'Shield Wall Drills',   'Practice holding the line against repeated impacts. Your defense will grow.',         'combat', 'uncommon', 7200,  '[{"stat":"defense","value":8}]'::jsonb,                  8,  0.85, 80,  20, false, '[]'::jsonb, true, 3,  'warrior', 'Defense'),
('train_warrior_endurance',    'Endurance March',      'A grueling long-distance march in full armor.',                                      'combat', 'uncommon', 14400, '[{"stat":"strength","value":12}]'::jsonb,                15, 0.80, 150, 40, false, '[]'::jsonb, true, 4,  'warrior', 'Strength'),
('train_warrior_conditioning', 'Battle Conditioning',  'An intense combat regimen that pushes your body to its absolute limit.',              'combat', 'rare',     28800, '[{"stat":"strength","value":18},{"stat":"defense","value":14}]'::jsonb, 25, 0.70, 300, 80, false, '[]'::jsonb, true, 5, 'warrior', 'Strength'),
-- Mage Training
('train_mage_study',        'Study Magic',           'Pore over basic spell tomes to deepen your arcane understanding.',                      'research', 'common',   1800,  '[]'::jsonb,                                                1,  0.95, 20,  5,  false, '[]'::jsonb, true, 10, 'mage', 'Wisdom'),
('train_mage_arcane',       'Arcane Research',       'Study ancient scrolls and practice rune-drawing to refine your magical knowledge.',     'research', 'common',   3600,  '[{"stat":"wisdom","value":6}]'::jsonb,                     3,  0.90, 40,  10, false, '[]'::jsonb, true, 11, 'mage', 'Wisdom'),
('train_mage_enchantment',  'Enchantment Practice',  'Practice weaving enchantments into objects. Strengthens your force of personality.',    'research', 'uncommon', 7200,  '[{"stat":"charisma","value":8}]'::jsonb,                   8,  0.85, 80,  20, false, '[]'::jsonb, true, 12, 'mage', 'Charisma'),
('train_mage_elemental',    'Elemental Attunement',  'Meditate on the primal forces of nature to attune your mind to deeper magic.',          'research', 'uncommon', 14400, '[{"stat":"wisdom","value":12}]'::jsonb,                    15, 0.80, 150, 40, false, '[]'::jsonb, true, 13, 'mage', 'Wisdom'),
('train_mage_deep',         'Deep Meditation',       'Enter a trance-like state pushing the boundaries of your intellect.',                   'research', 'rare',     28800, '[{"stat":"wisdom","value":18},{"stat":"charisma","value":14}]'::jsonb, 25, 0.70, 300, 80, false, '[]'::jsonb, true, 14, 'mage', 'Wisdom'),
-- Archer Training
('train_archer_target',     'Target Practice',       'Fire arrows at targets from increasing distances to sharpen your aim.',                 'stealth', 'common',   1800,  '[]'::jsonb,                                                  1,  0.95, 20,  5,  false, '[]'::jsonb, true, 20, 'archer', 'Dexterity'),
('train_archer_agility',    'Agility Drills',        'Sprint, dodge, and roll through an obstacle course to build speed and reflexes.',       'stealth', 'common',   3600,  '[{"stat":"dexterity","value":6}]'::jsonb,                    3,  0.90, 40,  10, false, '[]'::jsonb, true, 21, 'archer', 'Dexterity'),
('train_archer_stealth',    'Stealth Training',      'Move unseen through dense terrain. Sharpens both agility and awareness.',               'stealth', 'uncommon', 7200,  '[{"stat":"dexterity","value":8}]'::jsonb,                    8,  0.85, 80,  20, false, '[]'::jsonb, true, 22, 'archer', 'Dexterity'),
('train_archer_wilderness', 'Wilderness Survival',   'Spend time in the wild relying on instinct and resourcefulness.',                       'exploration', 'uncommon', 14400, '[{"stat":"luck","value":10}]'::jsonb,                     15, 0.80, 150, 40, false, '[]'::jsonb, true, 23, 'archer', 'Luck'),
('train_archer_precision',  'Precision Focus',       'An exhaustive regimen of trick shots and reaction drills.',                             'stealth', 'rare',     28800, '[{"stat":"dexterity","value":18},{"stat":"luck","value":14}]'::jsonb, 25, 0.70, 300, 80, false, '[]'::jsonb, true, 24, 'archer', 'Dexterity'),
-- Universal Training
('train_universal_conditioning', 'Basic Conditioning', 'A general fitness routine. Good for any aspiring adventurer.',                        'exploration', 'common',   1800,  '[]'::jsonb, 1, 0.95, 15, 5, false, '[]'::jsonb, true, 50, NULL, 'Dexterity'),
('train_universal_luck',         'Luck Meditation',    'Clear your mind and open yourself to fortune''s favor.',                              'gathering',   'uncommon', 3600,  '[]'::jsonb, 5, 0.85, 30, 10, false, '[]'::jsonb, true, 51, NULL, 'Luck')
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- DUTY BOARD (34 templates from DutyBoardGenerator.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_duties (id, title, description, category, icon, exp_multiplier, is_seasonal, active, sort_order) VALUES
('duty_20_pushups', 'Do 20 Push-ups', 'Drop and give me 20!', 'physical', NULL, 1.0, false, true, 1),
('duty_30_min_workout', '30-Minute Workout', 'Any exercise — gym, run, or home workout', 'physical', NULL, 1.0, false, true, 2),
('duty_plank_1_min', 'Plank for 1 Minute', 'Hold a plank — build that core!', 'physical', NULL, 1.0, false, true, 3),
('duty_go_for_run', 'Go for a Run', 'Run for at least 15 minutes', 'physical', NULL, 1.0, false, true, 4),
('duty_go_for_walk', 'Go for a Walk', 'Walk outside for at least 15 minutes', 'physical', NULL, 1.0, false, true, 5),
('duty_yoga_session', 'Yoga Session', '15 minutes of yoga flow', 'physical', NULL, 1.0, false, true, 6),
('duty_read_15_min', 'Read for 15 Minutes', 'A book, article, or anything inspiring', 'mental', NULL, 1.0, false, true, 7),
('duty_sudoku', 'Sudoku Challenge', 'Solve a Sudoku puzzle', 'mental', NULL, 1.0, false, true, 8),
('duty_memory_match', 'Memory Match', 'Match all pairs', 'mental', NULL, 1.0, false, true, 9),
('duty_math_blitz', 'Math Blitz', 'Solve 20 math problems fast!', 'mental', NULL, 1.0, false, true, 10),
('duty_word_search', 'Word Search', 'Find all hidden words', 'mental', NULL, 1.0, false, true, 11),
('duty_2048', '2048 Challenge', 'Merge tiles to reach 2048', 'mental', NULL, 1.0, false, true, 12),
('duty_learn_new', 'Learn Something New', 'Watch a tutorial or read a new topic', 'mental', NULL, 1.0, false, true, 13),
('duty_journal_10_min', 'Journal for 10 Minutes', 'Write about your day, goals, or gratitude', 'mental', NULL, 1.0, false, true, 14),
('duty_listen_podcast', 'Listen to a Podcast', 'Pick something educational or inspiring', 'mental', NULL, 1.0, false, true, 15),
('duty_call_friend', 'Call a Friend or Family', 'Catch up with someone you care about', 'social', NULL, 1.0, false, true, 16),
('duty_compliment_3', 'Compliment 3 People', 'Brighten someone''s day', 'social', NULL, 1.0, false, true, 17),
('duty_real_conversation', 'Have a Real Conversation', 'Put the phone away and connect', 'social', NULL, 1.0, false, true, 18),
('duty_write_thank_you', 'Write a Thank You', 'Send a message of gratitude', 'social', NULL, 1.0, false, true, 19),
('duty_clean_kitchen', 'Clean the Kitchen', 'Dishes, counters, and all!', 'household', NULL, 1.0, false, true, 20),
('duty_do_laundry', 'Do the Laundry', 'Wash, dry, fold — the full cycle', 'household', NULL, 1.0, false, true, 21),
('duty_organize_drawer', 'Organize a Drawer', 'Pick one drawer and tidy it up', 'household', NULL, 1.0, false, true, 22),
('duty_take_out_trash', 'Take Out the Trash', 'Quick win — take it out and replace the bag', 'household', NULL, 1.0, false, true, 23),
('duty_vacuum_sweep', 'Vacuum or Sweep', 'Give the floors some love', 'household', NULL, 1.0, false, true, 24),
('duty_drink_water', 'Drink 8 Glasses of Water', 'Stay hydrated throughout the day', 'wellness', NULL, 1.0, false, true, 25),
('duty_meditate_5_min', 'Meditate for 5 Minutes', 'Find a quiet spot and breathe', 'wellness', NULL, 1.0, false, true, 26),
('duty_no_phone_1hr', 'No Phone for 1 Hour', 'Put the phone down and be present', 'wellness', NULL, 1.0, false, true, 27),
('duty_8hrs_sleep', 'Get 8 Hours of Sleep', 'Prioritize rest tonight', 'wellness', NULL, 1.0, false, true, 28),
('duty_10_min_stretch', '10-Minute Stretch', 'Full body stretch to start or end the day', 'wellness', NULL, 1.0, false, true, 29),
('duty_sketch_doodle', 'Sketch or Doodle', 'Draw anything — no judgment', 'creative', NULL, 1.0, false, true, 30),
('duty_write_15_min', 'Write for 15 Minutes', 'Story, poem, blog — let words flow', 'creative', NULL, 1.0, false, true, 31),
('duty_play_instrument', 'Play an Instrument', 'Practice for at least 10 minutes', 'creative', NULL, 1.0, false, true, 32),
('duty_cook_new', 'Cook Something New', 'Try a recipe you''ve never made', 'creative', NULL, 1.0, false, true, 33),
('duty_take_photo', 'Take a Photo', 'Capture something beautiful', 'creative', NULL, 1.0, false, true, 34)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- NARRATIVES — Shopkeeper Dialogue (44 lines)
-- -----------------------------------------------------------
INSERT INTO public.content_narratives (id, context, text, theme, sort_order, active) VALUES
('shop_equip_1', 'shopkeeper_equipment_greeting', 'Fresh steel and enchanted gear, just for you!', NULL, 1, true),
('shop_equip_2', 'shopkeeper_equipment_greeting', 'Today''s stock won''t last — better grab something before it rotates!', NULL, 2, true),
('shop_equip_3', 'shopkeeper_equipment_greeting', 'I hand-pick every piece myself. Only the finest!', NULL, 3, true),
('shop_equip_4', 'shopkeeper_equipment_greeting', 'That armor over there? Saved a knight''s life last week.', NULL, 4, true),
('shop_equip_5', 'shopkeeper_equipment_greeting', 'New day, new gear. Take a look, adventurer!', NULL, 5, true),
('shop_equip_6', 'shopkeeper_equipment_greeting', 'Got some real beauties in stock today.', NULL, 6, true),
('shop_equip_7', 'shopkeeper_equipment_greeting', 'Legendary gear don''t show up every day — keep your eyes peeled.', NULL, 7, true),
('shop_equip_8', 'shopkeeper_equipment_greeting', 'Weapons, armor, accessories — everything a hero needs.', NULL, 8, true),
('shop_consum_1', 'shopkeeper_consumable_greeting', 'Potions, boosts, and shields — everything an adventurer needs.', NULL, 9, true),
('shop_consum_2', 'shopkeeper_consumable_greeting', 'A wise hero stocks up before the dungeon, not after!', NULL, 10, true),
('shop_consum_3', 'shopkeeper_consumable_greeting', 'These EXP boosts? Best seller in the shop.', NULL, 11, true),
('shop_consum_4', 'shopkeeper_consumable_greeting', 'Streak about to break? I got just the thing.', NULL, 12, true),
('shop_consum_5', 'shopkeeper_consumable_greeting', 'Never go into battle without a healing draught.', NULL, 13, true),
('shop_consum_6', 'shopkeeper_consumable_greeting', 'That Lucky Coin brings fortune to anyone who carries it.', NULL, 14, true),
('shop_consum_7', 'shopkeeper_consumable_greeting', 'A Protein Shake before a quest? Smart move.', NULL, 15, true),
('shop_consum_8', 'shopkeeper_consumable_greeting', 'Stock up now — you''ll thank me deep in a dungeon.', NULL, 16, true),
('shop_prem_1', 'shopkeeper_premium_greeting', 'Ah, the gem collection. Only the rarest items here.', NULL, 17, true),
('shop_prem_2', 'shopkeeper_premium_greeting', 'Gems unlock power you can''t buy with gold alone.', NULL, 18, true),
('shop_prem_3', 'shopkeeper_premium_greeting', 'That Revive Token has saved many a party.', NULL, 19, true),
('shop_prem_4', 'shopkeeper_premium_greeting', 'These are my finest wares. Gem-worthy, every one.', NULL, 20, true),
('shop_prem_5', 'shopkeeper_premium_greeting', 'The Loot Reroll? Turns a common blade into a legendary one.', NULL, 21, true),
('shop_prem_6', 'shopkeeper_premium_greeting', 'Instant Mission Scroll — for the adventurer who values time.', NULL, 22, true),
('shop_prem_7', 'shopkeeper_premium_greeting', 'Premium items, premium results.', NULL, 23, true),
('shop_prem_8', 'shopkeeper_premium_greeting', 'Only the most dedicated adventurers earn enough gems for these.', NULL, 24, true),
('shop_store_1', 'shopkeeper_storefront_greeting', 'Welcome! Check out today''s hot deal.', NULL, 25, true),
('shop_store_2', 'shopkeeper_storefront_greeting', 'The storefront has my finest picks. Don''t miss the daily deal!', NULL, 26, true),
('shop_store_3', 'shopkeeper_storefront_greeting', 'Looking to gear up? Deals, bundles, and class items.', NULL, 27, true),
('shop_store_4', 'shopkeeper_storefront_greeting', 'Your milestone gear is waiting — level up and claim it!', NULL, 28, true),
('shop_store_5', 'shopkeeper_storefront_greeting', 'Bundles save you gold. Smart heroes shop smart.', NULL, 29, true),
('shop_store_6', 'shopkeeper_storefront_greeting', 'Got a deal of the day that''ll make your jaw drop!', NULL, 30, true),
('shop_store_7', 'shopkeeper_storefront_greeting', 'Class gear sets give that extra edge. Collect all three!', NULL, 31, true),
('shop_store_8', 'shopkeeper_storefront_greeting', 'Welcome — where the best deals live.', NULL, 32, true),
('shop_deal_1', 'shopkeeper_deal', 'Today''s deal is a steal! Don''t sleep on it.', NULL, 33, true),
('shop_deal_2', 'shopkeeper_deal', 'That deal won''t last — grab it before midnight!', NULL, 34, true),
('shop_deal_3', 'shopkeeper_deal', 'I barely make gold on this one. It''s all for you.', NULL, 35, true),
('shop_mile_1', 'shopkeeper_milestone', 'Milestone gear is forged for your class. No one else can wield it like you.', NULL, 36, true),
('shop_mile_2', 'shopkeeper_milestone', 'Level up and new gear becomes available. That''s how legends are made.', NULL, 37, true),
('shop_mile_3', 'shopkeeper_milestone', 'Each milestone piece is hand-crafted for your path.', NULL, 38, true),
('shop_welcome_1', 'shopkeeper_welcome', 'Welcome to my shop, adventurer! Take a look around.', NULL, 39, true),
('shop_welcome_2', 'shopkeeper_welcome', 'Ah, a customer! Browse as long as you like.', NULL, 40, true),
('shop_welcome_3', 'shopkeeper_welcome', 'Welcome, welcome! Something for every hero.', NULL, 41, true),
('shop_welcome_4', 'shopkeeper_welcome', 'Step right in! The finest goods in the realm.', NULL, 42, true),
('shop_welcome_5', 'shopkeeper_welcome', 'Good to see you, adventurer. What''ll it be?', NULL, 43, true),
('shop_gem_explain', 'shopkeeper_gem_explanation', 'Gems are your premium currency, adventurer. You earn them from achievements, special events, and leveling milestones. Spend wisely — these items are powerful!', NULL, 44, true)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- NARRATIVES — Forgekeeper Dialogue (30 lines)
-- -----------------------------------------------------------
INSERT INTO public.content_narratives (id, context, text, theme, sort_order, active) VALUES
('forge_welcome_1', 'forgekeeper_welcome', 'Welcome to the Forge, adventurer! Let''s craft something mighty.', NULL, 1, true),
('forge_welcome_2', 'forgekeeper_welcome', 'Ah, a crafter approaches! What shall we forge today?', NULL, 2, true),
('forge_welcome_3', 'forgekeeper_welcome', 'The anvil is hot and the hammer is ready. Let''s get to work!', NULL, 3, true),
('forge_welcome_4', 'forgekeeper_welcome', 'Step up to the Forge! Every great hero needs great gear.', NULL, 4, true),
('forge_welcome_5', 'forgekeeper_welcome', 'Good to see you, adventurer. Ready to turn materials into legend?', NULL, 5, true),
('forge_slot_1', 'forgekeeper_slot_selection', 'Choose your equipment type wisely — each serves a different purpose.', NULL, 6, true),
('forge_slot_2', 'forgekeeper_slot_selection', 'Weapons for offense, armor for defense, accessories for extra edge.', NULL, 7, true),
('forge_slot_3', 'forgekeeper_slot_selection', 'What''ll it be? A mighty weapon, sturdy armor, or clever accessory?', NULL, 8, true),
('forge_slot_4', 'forgekeeper_slot_selection', 'Every piece tells a story. Let''s start writing yours.', NULL, 9, true),
('forge_tier_1', 'forgekeeper_tier_selection', 'Higher tiers demand rarer materials, but the results speak for themselves.', NULL, 10, true),
('forge_tier_2', 'forgekeeper_tier_selection', 'Start with Apprentice if you''re new, or go bold with Master!', NULL, 11, true),
('forge_tier_3', 'forgekeeper_tier_selection', 'The Master Forge has produced the finest equipment in the realm.', NULL, 12, true),
('forge_tier_4', 'forgekeeper_tier_selection', 'Choose your tier based on what you''ve gathered.', NULL, 13, true),
('forge_ready_1', 'forgekeeper_ready', 'Everything''s set! Hit that Forge button!', NULL, 14, true),
('forge_ready_2', 'forgekeeper_ready', 'Materials ready, slot chosen, tier locked in. Time to forge!', NULL, 15, true),
('forge_ready_3', 'forgekeeper_ready', 'The forge is hungry for those materials. Let''s make something special!', NULL, 16, true),
('forge_ready_4', 'forgekeeper_ready', 'All set! Swing that hammer and claim your new gear!', NULL, 17, true),
('forge_success_1', 'forgekeeper_success', 'A masterpiece! The forge spirits smile upon you!', NULL, 18, true),
('forge_success_2', 'forgekeeper_success', 'Now THAT is a fine piece! Well forged, adventurer!', NULL, 19, true),
('forge_success_3', 'forgekeeper_success', 'Beautiful work! The materials took shape perfectly.', NULL, 20, true),
('forge_success_4', 'forgekeeper_success', 'Another legendary craft from this forge!', NULL, 21, true),
('forge_cant_1', 'forgekeeper_cant_afford', 'A bit short on materials. Try a lower tier or head out to gather!', NULL, 22, true),
('forge_cant_2', 'forgekeeper_cant_afford', 'Not quite enough. Complete more tasks and dungeons to stock up!', NULL, 23, true),
('forge_cant_3', 'forgekeeper_cant_afford', 'The forge needs more — tasks give Essence, dungeons give Materials.', NULL, 24, true),
('forge_cant_4', 'forgekeeper_cant_afford', 'Almost there! A few more adventures should do it.', NULL, 25, true),
('forge_explain_essence', 'forgekeeper_explanation', 'Essence is earned every time you complete a real-life task. Verified tasks give even more!', NULL, 26, true),
('forge_explain_materials', 'forgekeeper_explanation', 'Materials come from dungeon adventures. Combat drops Ore, puzzles yield Crystal, and bosses give Hide.', NULL, 27, true),
('forge_explain_fragments', 'forgekeeper_explanation', 'Fragments remain when you dismantle unwanted equipment. Nothing goes to waste!', NULL, 28, true),
('forge_explain_gold', 'forgekeeper_explanation', 'Gold fuels higher-tier recipes. Earn it from tasks, dungeons, and quests.', NULL, 29, true),
('forge_explain_herbs', 'forgekeeper_explanation', 'Herbs are gathered during AFK Missions. Send your hero on training to collect them.', NULL, 30, true)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- STORE BUNDLES (4 from GearSetCatalog.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_store_bundles (id, name, description, icon, contents, gold_cost, gem_cost, discount_percent, level_requirement, is_one_time_purchase, is_seasonal, active, sort_order) VALUES
('bundle_starter', 'Adventurer''s Starter Pack', 'Everything a new hero needs to begin their journey.', 'bag.fill',
 '[{"type":"equipment","id":"wep_sword_common_01","quantity":1},{"type":"consumable","id":"herbal_tea","quantity":2},{"type":"consumable","id":"energy_bar","quantity":1}]'::jsonb,
 80, 0, 33, 1, true, false, true, 1),
('bundle_dungeon', 'Dungeon Prep Kit', 'Gear up before descending into the depths.', 'door.left.hand.open',
 '[{"type":"equipment","id":"wep_sword_uncommon_01","quantity":1},{"type":"consumable","id":"healing_draught","quantity":2},{"type":"consumable","id":"cozy_blanket","quantity":1}]'::jsonb,
 200, 0, 33, 5, true, false, true, 2),
('bundle_champion', 'Champion''s Bundle', 'Premium gear for the seasoned warrior.', 'crown.fill',
 '[{"type":"equipment","id":"wep_sword_rare_01","quantity":1},{"type":"consumable","id":"greater_healing_draught","quantity":1},{"type":"consumable","id":"power_bar","quantity":1}]'::jsonb,
 400, 0, 25, 15, true, false, true, 3),
('bundle_gem_starter', 'Gem Starter Pack', 'Essential premium items to give you the edge.', 'diamond.fill',
 '[{"type":"consumable","id":"revive_token","quantity":1},{"type":"consumable","id":"loot_reroll","quantity":1}]'::jsonb,
 0, 6, 25, 10, true, false, true, 4)
ON CONFLICT (id) DO NOTHING;


-- =============================================================
-- DONE — Verify counts:
-- SELECT 'equipment' AS tbl, count(*) FROM content_equipment
-- UNION ALL SELECT 'milestone', count(*) FROM content_milestone_gear
-- UNION ALL SELECT 'gear_sets', count(*) FROM content_gear_sets
-- UNION ALL SELECT 'consumables', count(*) FROM content_consumables
-- UNION ALL SELECT 'dungeons', count(*) FROM content_dungeons
-- UNION ALL SELECT 'missions', count(*) FROM content_missions
-- UNION ALL SELECT 'duties', count(*) FROM content_duties
-- UNION ALL SELECT 'narratives', count(*) FROM content_narratives
-- UNION ALL SELECT 'bundles', count(*) FROM content_store_bundles
-- UNION ALL SELECT 'achievements', count(*) FROM content_achievements
-- UNION ALL SELECT 'quests', count(*) FROM content_quests;
-- =============================================================
