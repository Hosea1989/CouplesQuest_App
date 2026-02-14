-- =============================================================
-- QuestBond — Content Data Seed Script
-- Run this AFTER 005_content_tables.sql AND 005b_achievements_quests_tables.sql
--
-- Seeds all existing Swift catalog data into Supabase content tables.
-- This is a one-time migration of hard-coded content to server-driven.
-- =============================================================


-- -----------------------------------------------------------
-- EQUIPMENT CATALOG (110 items from EquipmentCatalog.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_equipment (id, name, description, slot, base_type, rarity, primary_stat, stat_bonus, secondary_stat, secondary_stat_bonus, level_requirement, image_name, is_set_piece, set_id, active, sort_order) VALUES
-- Swords
('wep_sword_common_01', 'Worn Training Sword', 'A dull practice blade handed to every new adventurer.', 'weapon', 'sword', 'common', 'strength', 2, NULL, 0, 1, 'equip-sword-common', false, NULL, true, 1),
('wep_sword_uncommon_01', 'Steel Longsword', 'A reliable blade forged from quality steel.', 'weapon', 'sword', 'uncommon', 'strength', 4, 'defense', 1, 5, 'equip-sword-uncommon', false, NULL, true, 2),
('wep_sword_rare_01', 'Runic Claymore', 'Ancient glyphs run down the blade, pulsing faintly when enemies are near.', 'weapon', 'sword', 'rare', 'strength', 6, 'wisdom', 3, 12, 'equip-sword-rare', false, NULL, true, 3),
('wep_sword_epic_01', 'Dragonbane Greatsword', 'Quenched in dragonfire and tempered with starlight.', 'weapon', 'sword', 'epic', 'strength', 10, 'dexterity', 4, 22, 'equip-sword-epic', false, NULL, true, 4),
('wep_sword_legendary_01', 'Excalibur, Blade of Dawn', 'The fabled sword said to choose its wielder.', 'weapon', 'sword', 'legendary', 'strength', 15, 'charisma', 8, 35, 'equip-sword-legendary', false, NULL, true, 5),
-- Axes
('wep_axe_common_01', 'Rusty Hatchet', 'More suited for firewood than combat.', 'weapon', 'axe', 'common', 'strength', 3, NULL, 0, 1, 'equip-axe-common', false, NULL, true, 6),
('wep_axe_uncommon_01', 'Ironclad Battleaxe', 'A double-headed war axe banded with iron.', 'weapon', 'axe', 'uncommon', 'strength', 5, 'defense', 1, 6, 'equip-axe-uncommon', false, NULL, true, 7),
('wep_axe_rare_01', 'Frostbite Cleaver', 'Ice crystals form along the blade''s edge.', 'weapon', 'axe', 'rare', 'strength', 7, 'dexterity', 3, 14, 'equip-axe-rare', false, NULL, true, 8),
('wep_axe_epic_01', 'Worldsplitter', 'Legends say this axe once cleaved a mountain in two.', 'weapon', 'axe', 'epic', 'strength', 11, 'defense', 5, 25, 'equip-axe-epic', false, NULL, true, 9),
('wep_axe_legendary_01', 'Ragnarok, the End of Ages', 'Forged in the heart of a dying star.', 'weapon', 'axe', 'legendary', 'strength', 16, 'luck', 7, 38, 'equip-axe-legendary', false, NULL, true, 10),
-- Staves
('wep_staff_common_01', 'Gnarled Walking Stick', 'A crooked branch whittled into something resembling a staff.', 'weapon', 'staff', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-staff-common', false, NULL, true, 11),
('wep_staff_uncommon_01', 'Oak Channeling Staff', 'Cut from an ancient oak grove, this staff hums with energy.', 'weapon', 'staff', 'uncommon', 'wisdom', 4, 'charisma', 2, 5, 'equip-staff-uncommon', false, NULL, true, 12),
('wep_staff_rare_01', 'Stormcaller''s Crook', 'Lightning arcs between the forked prongs at its crown.', 'weapon', 'staff', 'rare', 'wisdom', 7, 'strength', 2, 13, 'equip-staff-rare', false, NULL, true, 13),
('wep_staff_epic_01', 'Archmage''s Scepter', 'Crystallised mana forms the headpiece.', 'weapon', 'staff', 'epic', 'wisdom', 11, 'luck', 4, 24, 'equip-staff-epic', false, NULL, true, 14),
('wep_staff_legendary_01', 'Yggdrasil''s Root', 'A living branch from the World Tree itself.', 'weapon', 'staff', 'legendary', 'wisdom', 17, 'defense', 7, 40, 'equip-staff-legendary', false, NULL, true, 15),
-- Daggers
('wep_dagger_common_01', 'Chipped Shiv', 'A crude blade that''s more intimidating than effective.', 'weapon', 'dagger', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-dagger-common', false, NULL, true, 16),
('wep_dagger_uncommon_01', 'Viper Fang Stiletto', 'Thin, wickedly sharp, and coated with a subtle toxin.', 'weapon', 'dagger', 'uncommon', 'dexterity', 4, 'luck', 2, 4, 'equip-dagger-uncommon', false, NULL, true, 17),
('wep_dagger_rare_01', 'Shadowstep Kris', 'The wavy blade seems to flicker between dimensions.', 'weapon', 'dagger', 'rare', 'dexterity', 6, 'strength', 3, 11, 'equip-dagger-rare', false, NULL, true, 18),
('wep_dagger_epic_01', 'Nightwhisper', 'A blade forged from condensed shadow.', 'weapon', 'dagger', 'epic', 'dexterity', 10, 'luck', 5, 20, 'equip-dagger-epic', false, NULL, true, 19),
('wep_dagger_legendary_01', 'Oblivion''s Kiss', 'They say this dagger can sever fate itself.', 'weapon', 'dagger', 'legendary', 'dexterity', 14, 'charisma', 9, 34, 'equip-dagger-legendary', false, NULL, true, 20),
-- Bows
('wep_bow_common_01', 'Frayed Shortbow', 'The string needs replacing and the limbs creak.', 'weapon', 'bow', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-bow-common', false, NULL, true, 21),
('wep_bow_uncommon_01', 'Hunter''s Recurve', 'A compact, powerful bow for tracking game.', 'weapon', 'bow', 'uncommon', 'dexterity', 4, 'strength', 1, 5, 'equip-bow-uncommon', false, NULL, true, 22),
('wep_bow_rare_01', 'Windrunner Longbow', 'Arrows from this bow ride the wind.', 'weapon', 'bow', 'rare', 'dexterity', 7, 'luck', 3, 13, 'equip-bow-rare', false, NULL, true, 23),
('wep_bow_epic_01', 'Celestial Warbow', 'Strung with a thread of captured starlight.', 'weapon', 'bow', 'epic', 'dexterity', 10, 'wisdom', 5, 23, 'equip-bow-epic', false, NULL, true, 24),
('wep_bow_legendary_01', 'Artemis, the Moonlit Arc', 'Blessed by the goddess of the hunt.', 'weapon', 'bow', 'legendary', 'dexterity', 15, 'luck', 10, 36, 'equip-bow-legendary', false, NULL, true, 25),
-- Wands
('wep_wand_common_01', 'Splintered Wand', 'A brittle twig that occasionally sparks.', 'weapon', 'wand', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-wand-common', false, NULL, true, 26),
('wep_wand_uncommon_01', 'Ember Wand', 'A wand carved from fire-hardened birch.', 'weapon', 'wand', 'uncommon', 'wisdom', 4, 'luck', 1, 4, 'equip-wand-uncommon', false, NULL, true, 27),
('wep_wand_rare_01', 'Prismatic Focus', 'A crystalline wand that splits magic into a rainbow.', 'weapon', 'wand', 'rare', 'wisdom', 6, 'charisma', 3, 12, 'equip-wand-rare', false, NULL, true, 28),
('wep_wand_epic_01', 'Void Siphon', 'This wand drinks in ambient magic.', 'weapon', 'wand', 'epic', 'wisdom', 10, 'dexterity', 4, 21, 'equip-wand-epic', false, NULL, true, 29),
('wep_wand_legendary_01', 'Merlin''s Last Word', 'The final creation of the greatest mage.', 'weapon', 'wand', 'legendary', 'wisdom', 16, 'luck', 8, 38, 'equip-wand-legendary', false, NULL, true, 30),
-- Maces
('wep_mace_common_01', 'Bent Cudgel', 'A heavy lump of wood and metal.', 'weapon', 'mace', 'common', 'strength', 2, NULL, 0, 1, 'equip-mace-common', false, NULL, true, 31),
('wep_mace_uncommon_01', 'Flanged War Mace', 'Reinforced flanges concentrate impact force.', 'weapon', 'mace', 'uncommon', 'strength', 4, 'defense', 2, 6, 'equip-mace-uncommon', false, NULL, true, 32),
('wep_mace_rare_01', 'Thundering Maul', 'A seismic impact accompanies every blow.', 'weapon', 'mace', 'rare', 'strength', 7, 'defense', 3, 14, 'equip-mace-rare', false, NULL, true, 33),
('wep_mace_epic_01', 'Dawnbreaker', 'A holy mace that blazes with solar fire.', 'weapon', 'mace', 'epic', 'strength', 10, 'charisma', 5, 24, 'equip-mace-epic', false, NULL, true, 34),
('wep_mace_legendary_01', 'Mjolnir, the Stormhammer', 'Only the worthy may lift it.', 'weapon', 'mace', 'legendary', 'strength', 17, 'defense', 8, 40, 'equip-mace-legendary', false, NULL, true, 35),
-- Spears
('wep_spear_common_01', 'Wooden Pike', 'A sharpened stick with delusions of grandeur.', 'weapon', 'spear', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-spear-common', false, NULL, true, 36),
('wep_spear_uncommon_01', 'Bronze Partisan', 'A wide-bladed spear for thrusting and sweeping.', 'weapon', 'spear', 'uncommon', 'dexterity', 4, 'strength', 2, 5, 'equip-spear-uncommon', false, NULL, true, 37),
('wep_spear_rare_01', 'Tidecaller Trident', 'Three prongs of sea-forged steel.', 'weapon', 'spear', 'rare', 'dexterity', 6, 'wisdom', 3, 13, 'equip-spear-rare', false, NULL, true, 38),
('wep_spear_epic_01', 'Skypierce Lance', 'So perfectly balanced it feels weightless.', 'weapon', 'spear', 'epic', 'dexterity', 10, 'strength', 5, 23, 'equip-spear-epic', false, NULL, true, 39),
('wep_spear_legendary_01', 'Gungnir, the Allfather''s Reach', 'Once thrown, it never misses.', 'weapon', 'spear', 'legendary', 'dexterity', 15, 'wisdom', 9, 37, 'equip-spear-legendary', false, NULL, true, 40),
-- Plates
('arm_plate_common_01', 'Dented Iron Plate', 'Heavy, uncomfortable, and has a suspicious dent.', 'armor', 'plate', 'common', 'defense', 3, NULL, 0, 1, 'equip-plate-common', false, NULL, true, 41),
('arm_plate_uncommon_01', 'Steel Guardian Plate', 'Well-fitted plate that distributes weight evenly.', 'armor', 'plate', 'uncommon', 'defense', 5, 'strength', 1, 7, 'equip-plate-uncommon', false, NULL, true, 42),
('arm_plate_rare_01', 'Warden''s Bulwark', 'Enchanted plate that hardens on impact.', 'armor', 'plate', 'rare', 'defense', 7, 'strength', 3, 15, 'equip-plate-rare', false, NULL, true, 43),
('arm_plate_epic_01', 'Titanforge Warplate', 'Forged from an alloy that doesn''t exist in nature.', 'armor', 'plate', 'epic', 'defense', 11, 'strength', 5, 26, 'equip-plate-epic', false, NULL, true, 44),
('arm_plate_legendary_01', 'Aegis of the Immortal', 'Worn by the last of the eternal guardians.', 'armor', 'plate', 'legendary', 'defense', 18, 'charisma', 7, 40, 'equip-plate-legendary', false, NULL, true, 45),
-- Chainmails
('arm_chain_common_01', 'Loose Chain Shirt', 'Links are uneven but it turns a blade.', 'armor', 'chainmail', 'common', 'defense', 2, NULL, 0, 1, 'equip-chainmail-common', false, NULL, true, 46),
('arm_chain_uncommon_01', 'Riveted Hauberk', 'Each ring individually riveted.', 'armor', 'chainmail', 'uncommon', 'defense', 4, 'dexterity', 2, 6, 'equip-chainmail-uncommon', false, NULL, true, 47),
('arm_chain_rare_01', 'Mithril Weave', 'Impossibly light chainmail from mithril.', 'armor', 'chainmail', 'rare', 'defense', 6, 'dexterity', 4, 14, 'equip-chainmail-rare', false, NULL, true, 48),
('arm_chain_epic_01', 'Dragonlink Coat', 'Each link is a miniature dragon scale.', 'armor', 'chainmail', 'epic', 'defense', 9, 'dexterity', 5, 24, 'equip-chainmail-epic', false, NULL, true, 49),
('arm_chain_legendary_01', 'Veil of the Valkyrie', 'Woven by warrior-angels from valor.', 'armor', 'chainmail', 'legendary', 'defense', 15, 'luck', 8, 37, 'equip-chainmail-legendary', false, NULL, true, 50),
-- Robes
('arm_robes_common_01', 'Threadbare Apprentice Robes', 'Patched and re-patched.', 'armor', 'robes', 'common', 'wisdom', 2, NULL, 0, 1, 'equip-robes-common', false, NULL, true, 51),
('arm_robes_uncommon_01', 'Scholar''s Vestments', 'Well-tailored with protective runes.', 'armor', 'robes', 'uncommon', 'wisdom', 4, 'charisma', 2, 5, 'equip-robes-uncommon', false, NULL, true, 52),
('arm_robes_rare_01', 'Astral Silkweave', 'Woven from threads that shimmer with starlight.', 'armor', 'robes', 'rare', 'wisdom', 7, 'defense', 2, 13, 'equip-robes-rare', false, NULL, true, 53),
('arm_robes_epic_01', 'Mantle of the Archmage', 'Spells weave themselves into the fabric.', 'armor', 'robes', 'epic', 'wisdom', 10, 'defense', 5, 24, 'equip-robes-epic', false, NULL, true, 54),
('arm_robes_legendary_01', 'Cosmos Regalia', 'The universe woven into this garment.', 'armor', 'robes', 'legendary', 'wisdom', 16, 'luck', 9, 38, 'equip-robes-legendary', false, NULL, true, 55),
-- Leather Armor
('arm_leather_common_01', 'Patched Hide Vest', 'Stitched from various animal hides.', 'armor', 'leather armor', 'common', 'dexterity', 2, NULL, 0, 1, 'equip-leather-armor-common', false, NULL, true, 56),
('arm_leather_uncommon_01', 'Ranger''s Jerkin', 'Supple dyed-green leather.', 'armor', 'leather armor', 'uncommon', 'dexterity', 4, 'defense', 1, 5, 'equip-leather-armor-uncommon', false, NULL, true, 57),
('arm_leather_rare_01', 'Shadowskin Cuirass', 'Treated with shadow-essence.', 'armor', 'leather armor', 'rare', 'dexterity', 6, 'luck', 3, 12, 'equip-leather-armor-rare', false, NULL, true, 58),
('arm_leather_epic_01', 'Wyrmhide Armor', 'Tanned from the hide of an elder wyrm.', 'armor', 'leather armor', 'epic', 'dexterity', 10, 'defense', 4, 22, 'equip-leather-armor-epic', false, NULL, true, 59),
('arm_leather_legendary_01', 'Phantom Shroud', 'Woven from echoes of whispered secrets.', 'armor', 'leather armor', 'legendary', 'dexterity', 14, 'charisma', 8, 35, 'equip-leather-armor-legendary', false, NULL, true, 60),
-- Breastplates
('arm_breast_common_01', 'Tarnished Breastplate', 'The engraving has worn away to nothing.', 'armor', 'breastplate', 'common', 'defense', 2, NULL, 0, 1, 'equip-breastplate-common', false, NULL, true, 61),
('arm_breast_uncommon_01', 'Knight''s Cuirass', 'Polished breastplate bearing a fallen crest.', 'armor', 'breastplate', 'uncommon', 'defense', 4, 'charisma', 1, 6, 'equip-breastplate-uncommon', false, NULL, true, 62),
('arm_breast_rare_01', 'Emberheart Guard', 'The metal is perpetually warm.', 'armor', 'breastplate', 'rare', 'defense', 6, 'strength', 3, 14, 'equip-breastplate-rare', false, NULL, true, 63),
('arm_breast_epic_01', 'Oathkeeper''s Aegis', 'Engraved with binding oaths of protection.', 'armor', 'breastplate', 'epic', 'defense', 10, 'charisma', 5, 25, 'equip-breastplate-epic', false, NULL, true, 64),
('arm_breast_legendary_01', 'Soulforged Vestment', 'Bound to its wearer''s soul.', 'armor', 'breastplate', 'legendary', 'defense', 16, 'wisdom', 7, 38, 'equip-breastplate-legendary', false, NULL, true, 65),
-- Helms
('arm_helm_common_01', 'Battered Tin Helm', 'Basically a bucket with eye holes.', 'armor', 'helm', 'common', 'defense', 1, NULL, 0, 1, 'equip-helm-common', false, NULL, true, 66),
('arm_helm_uncommon_01', 'Steel Barbute', 'Well-crafted with a T-shaped visor.', 'armor', 'helm', 'uncommon', 'defense', 3, 'wisdom', 2, 5, 'equip-helm-uncommon', false, NULL, true, 67),
('arm_helm_rare_01', 'Crown of the Vigilant', 'Open-faced helm with glowing eye motif.', 'armor', 'helm', 'rare', 'defense', 5, 'wisdom', 4, 13, 'equip-helm-rare', false, NULL, true, 68),
('arm_helm_epic_01', 'Dread Visage', 'A terrifying horned helm.', 'armor', 'helm', 'epic', 'defense', 8, 'charisma', 6, 23, 'equip-helm-epic', false, NULL, true, 69),
('arm_helm_legendary_01', 'Crown of the Conqueror', 'Worn by the one who united all kingdoms.', 'armor', 'helm', 'legendary', 'defense', 13, 'charisma', 10, 36, 'equip-helm-legendary', false, NULL, true, 70),
-- Gauntlets
('arm_gauntlets_common_01', 'Cracked Leather Gloves', 'They barely qualify as gauntlets.', 'armor', 'gauntlets', 'common', 'strength', 1, NULL, 0, 1, 'equip-gauntlets-common', false, NULL, true, 71),
('arm_gauntlets_uncommon_01', 'Iron Grip Gauntlets', 'Reinforced knuckles and articulated fingers.', 'armor', 'gauntlets', 'uncommon', 'strength', 3, 'defense', 2, 5, 'equip-gauntlets-uncommon', false, NULL, true, 72),
('arm_gauntlets_rare_01', 'Flameguard Gauntlets', 'Enchanted to be fireproof.', 'armor', 'gauntlets', 'rare', 'strength', 5, 'defense', 4, 12, 'equip-gauntlets-rare', false, NULL, true, 73),
('arm_gauntlets_epic_01', 'Titan''s Grasp', 'Once you grab something, nothing will make you let go.', 'armor', 'gauntlets', 'epic', 'strength', 9, 'defense', 5, 22, 'equip-gauntlets-epic', false, NULL, true, 74),
('arm_gauntlets_legendary_01', 'Hands of Creation', 'Said to be replicas of the hands that shaped the world.', 'armor', 'gauntlets', 'legendary', 'strength', 14, 'wisdom', 8, 37, 'equip-gauntlets-legendary', false, NULL, true, 75),
-- Rings
('acc_ring_common_01', 'Tarnished Copper Band', 'A thin ring that''s turned your finger green.', 'accessory', 'ring', 'common', 'luck', 1, NULL, 0, 1, 'equip-ring-common', false, NULL, true, 76),
('acc_ring_uncommon_01', 'Silver Promise Ring', 'A simple silver band etched with hearts.', 'accessory', 'ring', 'uncommon', 'charisma', 3, 'luck', 2, 4, 'equip-ring-uncommon', false, NULL, true, 77),
('acc_ring_rare_01', 'Ring of Shared Strength', 'Matching rings that make both wearers stronger.', 'accessory', 'ring', 'rare', 'strength', 5, 'charisma', 4, 11, 'equip-ring-rare', false, NULL, true, 78),
('acc_ring_epic_01', 'Eclipse Band', 'A ring of intertwined sun and moon metals.', 'accessory', 'ring', 'epic', 'luck', 8, 'wisdom', 5, 20, 'equip-ring-epic', false, NULL, true, 79),
('acc_ring_legendary_01', 'The Eternal Vow', 'A ring forged from a promise that transcends time.', 'accessory', 'ring', 'legendary', 'charisma', 14, 'luck', 10, 35, 'equip-ring-legendary', false, NULL, true, 80),
-- Amulets
('acc_amulet_common_01', 'Wooden Totem Necklace', 'A carved animal token on a hemp cord.', 'accessory', 'amulet', 'common', 'luck', 2, NULL, 0, 1, 'equip-amulet-common', false, NULL, true, 81),
('acc_amulet_uncommon_01', 'Jade Guardian Amulet', 'A polished jade stone that wards off hexes.', 'accessory', 'amulet', 'uncommon', 'defense', 3, 'wisdom', 2, 5, 'equip-amulet-uncommon', false, NULL, true, 82),
('acc_amulet_rare_01', 'Phoenix Feather Talisman', 'A genuine phoenix plume encased in crystal.', 'accessory', 'amulet', 'rare', 'wisdom', 5, 'luck', 4, 12, 'equip-amulet-rare', false, NULL, true, 83),
('acc_amulet_epic_01', 'Eye of the Storm', 'A sapphire containing a miniature thunderstorm.', 'accessory', 'amulet', 'epic', 'wisdom', 9, 'defense', 5, 22, 'equip-amulet-epic', false, NULL, true, 84),
('acc_amulet_legendary_01', 'Heart of the World Tree', 'A seed of pure life force from Yggdrasil.', 'accessory', 'amulet', 'legendary', 'wisdom', 15, 'luck', 9, 38, 'equip-amulet-legendary', false, NULL, true, 85),
-- Cloaks
('acc_cloak_common_01', 'Moth-Eaten Travel Cape', 'It keeps some of the rain off.', 'accessory', 'cloak', 'common', 'defense', 1, NULL, 0, 1, 'equip-cloak-common', false, NULL, true, 86),
('acc_cloak_uncommon_01', 'Twilight Mantle', 'A deep-blue cloak that absorbs light.', 'accessory', 'cloak', 'uncommon', 'dexterity', 3, 'defense', 1, 5, 'equip-cloak-uncommon', false, NULL, true, 87),
('acc_cloak_rare_01', 'Windweaver''s Shroud', 'The air moves around this cloak.', 'accessory', 'cloak', 'rare', 'dexterity', 5, 'luck', 3, 13, 'equip-cloak-rare', false, NULL, true, 88),
('acc_cloak_epic_01', 'Cloak of Many Stars', 'The interior shows a different constellation each night.', 'accessory', 'cloak', 'epic', 'wisdom', 8, 'dexterity', 5, 21, 'equip-cloak-epic', false, NULL, true, 89),
('acc_cloak_legendary_01', 'Mantle of the Unseen', 'Woven from pure possibility.', 'accessory', 'cloak', 'legendary', 'dexterity', 13, 'luck', 10, 36, 'equip-cloak-legendary', false, NULL, true, 90),
-- Bracelets
('acc_bracelet_common_01', 'Woven Friendship Band', 'A colorful thread bracelet.', 'accessory', 'bracelet', 'common', 'charisma', 1, NULL, 0, 1, 'equip-bracelet-common', false, NULL, true, 91),
('acc_bracelet_uncommon_01', 'Iron Willpower Cuff', 'A heavy cuff with discipline mantras.', 'accessory', 'bracelet', 'uncommon', 'strength', 3, 'defense', 1, 4, 'equip-bracelet-uncommon', false, NULL, true, 92),
('acc_bracelet_rare_01', 'Oathbound Bangle', 'One of a bonded pair.', 'accessory', 'bracelet', 'rare', 'charisma', 5, 'luck', 4, 11, 'equip-bracelet-rare', false, NULL, true, 93),
('acc_bracelet_epic_01', 'Temporal Armlet', 'A bracelet slightly out of sync with time.', 'accessory', 'bracelet', 'epic', 'dexterity', 8, 'wisdom', 5, 21, 'equip-bracelet-epic', false, NULL, true, 94),
('acc_bracelet_legendary_01', 'Infinity Loop', 'A bracelet with no beginning and no end.', 'accessory', 'bracelet', 'legendary', 'luck', 14, 'dexterity', 9, 37, 'equip-bracelet-legendary', false, NULL, true, 95),
-- Charms
('acc_charm_common_01', 'Lucky Penny Charm', 'It was heads-up when you found it.', 'accessory', 'charm', 'common', 'luck', 2, NULL, 0, 1, 'equip-charm-common', false, NULL, true, 96),
('acc_charm_uncommon_01', 'Four-Leaf Crystal', 'A four-leaf clover preserved in crystal.', 'accessory', 'charm', 'uncommon', 'luck', 4, 'charisma', 1, 4, 'equip-charm-uncommon', false, NULL, true, 97),
('acc_charm_rare_01', 'Heartstone Charm', 'A rose-colored stone that resonates with bonds.', 'accessory', 'charm', 'rare', 'charisma', 6, 'luck', 3, 12, 'equip-charm-rare', false, NULL, true, 98),
('acc_charm_epic_01', 'Dragon''s Eye Charm', 'A gemstone that sees through illusions.', 'accessory', 'charm', 'epic', 'wisdom', 8, 'luck', 6, 20, 'equip-charm-epic', false, NULL, true, 99),
('acc_charm_legendary_01', 'Wishing Star Fragment', 'A piece of a fallen star burning with wishes.', 'accessory', 'charm', 'legendary', 'luck', 15, 'charisma', 8, 34, 'equip-charm-legendary', false, NULL, true, 100),
-- Pendants
('acc_pendant_common_01', 'Polished Stone Pendant', 'A smooth river stone on a leather thong.', 'accessory', 'pendant', 'common', 'defense', 1, NULL, 0, 1, 'equip-pendant-common', false, NULL, true, 101),
('acc_pendant_uncommon_01', 'Moonstone Pendant', 'A pendant that glows softly in darkness.', 'accessory', 'pendant', 'uncommon', 'wisdom', 3, 'defense', 1, 5, 'equip-pendant-uncommon', false, NULL, true, 102),
('acc_pendant_rare_01', 'Locket of Memories', 'Replays cherished memories when opened.', 'accessory', 'pendant', 'rare', 'charisma', 5, 'wisdom', 3, 12, 'equip-pendant-rare', false, NULL, true, 103),
('acc_pendant_epic_01', 'Soulbinder''s Locket', 'Contains a fragment of a bonded partner''s essence.', 'accessory', 'pendant', 'epic', 'charisma', 9, 'strength', 4, 22, 'equip-pendant-epic', false, NULL, true, 104),
('acc_pendant_legendary_01', 'Aether Heart', 'A pendant containing a miniature universe.', 'accessory', 'pendant', 'legendary', 'wisdom', 14, 'charisma', 10, 38, 'equip-pendant-legendary', false, NULL, true, 105),
-- Belts
('acc_belt_common_01', 'Rope Sash', 'A length of rope tied around the waist.', 'accessory', 'belt', 'common', 'strength', 1, NULL, 0, 1, 'equip-belt-common', false, NULL, true, 106),
('acc_belt_uncommon_01', 'Adventurer''s Utility Belt', 'Pockets and pouches for everything.', 'accessory', 'belt', 'uncommon', 'dexterity', 3, 'strength', 1, 4, 'equip-belt-uncommon', false, NULL, true, 107),
('acc_belt_rare_01', 'Belt of the Marathon', 'Enchanted to redistribute weight perfectly.', 'accessory', 'belt', 'rare', 'dexterity', 5, 'strength', 3, 11, 'equip-belt-rare', false, NULL, true, 108),
('acc_belt_epic_01', 'Champion''s War Girdle', 'Won by defeating a hundred challengers.', 'accessory', 'belt', 'epic', 'strength', 8, 'defense', 5, 22, 'equip-belt-epic', false, NULL, true, 109),
('acc_belt_legendary_01', 'Girdle of World-Bearing', 'Replicated from the belt of a titan.', 'accessory', 'belt', 'legendary', 'strength', 14, 'defense', 9, 36, 'equip-belt-legendary', false, NULL, true, 110)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- MILESTONE GEAR (36 items from MilestoneGearCatalog.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_milestone_gear (id, name, description, slot, base_type, rarity, primary_stat, stat_bonus, secondary_stat, secondary_stat_bonus, level_requirement, character_class, gold_cost, image_name, active, sort_order) VALUES
('ms_warrior_lv5', 'Warrior''s Faithful Blade', 'A sturdy sword forged for those who prove their strength.', 'weapon', 'sword', 'uncommon', 'strength', 4, 'defense', 1, 5, 'warrior', 80, NULL, true, 1),
('ms_warrior_lv10', 'Guardian''s Iron Plate', 'Battle-hardened armor for those who stand between danger and the defenseless.', 'armor', 'plate', 'rare', 'defense', 6, 'strength', 2, 10, 'warrior', 200, NULL, true, 2),
('ms_warrior_lv15', 'Warcry Pendant', 'A medallion that amplifies the wearer''s battle cry.', 'accessory', 'pendant', 'rare', 'strength', 5, 'charisma', 3, 15, 'warrior', 320, NULL, true, 3),
('ms_warrior_lv20', 'Champion''s Greatsword', 'A legendary two-handed blade for proven warriors.', 'weapon', 'sword', 'epic', 'strength', 9, 'dexterity', 4, 20, 'warrior', 600, NULL, true, 4),
('ms_mage_lv5', 'Apprentice''s Focus Staff', 'A crystalline-tipped staff for channeling magic.', 'weapon', 'staff', 'uncommon', 'wisdom', 4, 'luck', 1, 5, 'mage', 80, NULL, true, 5),
('ms_mage_lv10', 'Arcane Silk Robes', 'Woven from mana-infused threads.', 'armor', 'robes', 'rare', 'wisdom', 6, 'defense', 2, 10, 'mage', 200, NULL, true, 6),
('ms_mage_lv15', 'Mystic Charm', 'A shimmering charm that sharpens magical intuition.', 'accessory', 'charm', 'rare', 'wisdom', 5, 'luck', 3, 15, 'mage', 320, NULL, true, 7),
('ms_mage_lv20', 'Sorcerer''s Orb Staff', 'An ancient staff topped with a floating mana orb.', 'weapon', 'wand', 'epic', 'wisdom', 9, 'charisma', 4, 20, 'mage', 600, NULL, true, 8),
('ms_archer_lv5', 'Scout''s Shortbow', 'A lightweight fast-draw bow.', 'weapon', 'bow', 'uncommon', 'dexterity', 4, 'luck', 1, 5, 'archer', 80, NULL, true, 9),
('ms_archer_lv10', 'Ranger''s Leather Armor', 'Supple leather treated for silence and flexibility.', 'armor', 'leather armor', 'rare', 'dexterity', 6, 'defense', 2, 10, 'archer', 200, NULL, true, 10),
('ms_archer_lv15', 'Eagle-Eye Ring', 'Enchanted to sharpen sight beyond mortal limits.', 'accessory', 'ring', 'rare', 'dexterity', 5, 'luck', 3, 15, 'archer', 320, NULL, true, 11),
('ms_archer_lv20', 'Windrunner''s Longbow', 'A masterwork bow with wind-speed precision.', 'weapon', 'bow', 'epic', 'dexterity', 9, 'strength', 4, 20, 'archer', 600, NULL, true, 12),
('ms_berserker_lv25', 'Rage-Forged Axe', 'An axe tempered in fury.', 'weapon', 'axe', 'epic', 'strength', 10, 'dexterity', 4, 25, 'berserker', 750, NULL, true, 13),
('ms_berserker_lv30', 'Berserker''s War Plate', 'Spiked armor that channels rage.', 'armor', 'plate', 'epic', 'strength', 8, 'defense', 5, 30, 'berserker', 900, NULL, true, 14),
('ms_berserker_lv40', 'Blood Fury Bracelet', 'A crimson bracelet pulsing with primal energy.', 'accessory', 'bracelet', 'legendary', 'strength', 14, 'dexterity', 6, 40, 'berserker', 1500, NULL, true, 15),
('ms_berserker_lv50', 'Worldsplitter', 'A legendary axe said to cleave mountains.', 'weapon', 'axe', 'legendary', 'strength', 16, 'defense', 8, 50, 'berserker', 2500, NULL, true, 16),
('ms_paladin_lv25', 'Oathkeeper Mace', 'A holy mace that glows near evil.', 'weapon', 'mace', 'epic', 'defense', 10, 'strength', 4, 25, 'paladin', 750, NULL, true, 17),
('ms_paladin_lv30', 'Sanctified Shield Plate', 'Blessed plate that absorbs blows.', 'armor', 'plate', 'epic', 'defense', 9, 'wisdom', 4, 30, 'paladin', 900, NULL, true, 18),
('ms_paladin_lv40', 'Amulet of Devotion', 'An ancient relic shielding the faithful.', 'accessory', 'amulet', 'legendary', 'defense', 14, 'charisma', 6, 40, 'paladin', 1500, NULL, true, 19),
('ms_paladin_lv50', 'Dawn''s Embrace', 'Legendary armor from crystallized sunlight.', 'armor', 'plate', 'legendary', 'defense', 16, 'strength', 8, 50, 'paladin', 2500, NULL, true, 20),
('ms_sorcerer_lv25', 'Voidweaver Staff', 'A staff drawing power from the void.', 'weapon', 'staff', 'epic', 'wisdom', 10, 'luck', 4, 25, 'sorcerer', 750, NULL, true, 21),
('ms_sorcerer_lv30', 'Astral Silk Vestment', 'Robes sewn from starlight threads.', 'armor', 'robes', 'epic', 'wisdom', 8, 'defense', 5, 30, 'sorcerer', 900, NULL, true, 22),
('ms_sorcerer_lv40', 'Infinity Loop Ring', 'Bends mana in a perpetual cycle.', 'accessory', 'ring', 'legendary', 'wisdom', 14, 'luck', 6, 40, 'sorcerer', 1500, NULL, true, 23),
('ms_sorcerer_lv50', 'Archmage''s Epoch Staff', 'The legendary staff of a transcendent mage.', 'weapon', 'staff', 'legendary', 'wisdom', 16, 'charisma', 8, 50, 'sorcerer', 2500, NULL, true, 24),
('ms_enchanter_lv25', 'Harmonist''s Wand', 'A wand resonating with ally emotions.', 'weapon', 'wand', 'epic', 'charisma', 10, 'wisdom', 4, 25, 'enchanter', 750, NULL, true, 25),
('ms_enchanter_lv30', 'Moonshadow Robes', 'Enchanted robes shimmering under moonlight.', 'armor', 'robes', 'epic', 'charisma', 8, 'defense', 5, 30, 'enchanter', 900, NULL, true, 26),
('ms_enchanter_lv40', 'Crown of Whispers', 'A delicate circlet hearing unspoken needs.', 'accessory', 'charm', 'legendary', 'charisma', 14, 'wisdom', 6, 40, 'enchanter', 1500, NULL, true, 27),
('ms_enchanter_lv50', 'Eternal Harmony Staff', 'A legendary staff binding spirits together.', 'weapon', 'wand', 'legendary', 'charisma', 16, 'wisdom', 8, 50, 'enchanter', 2500, NULL, true, 28),
('ms_ranger_lv25', 'Galeforce Bow', 'A bow with wind-enchanted sinew.', 'weapon', 'bow', 'epic', 'dexterity', 10, 'luck', 4, 25, 'ranger', 750, NULL, true, 29),
('ms_ranger_lv30', 'Forestwalker Armor', 'Living armor grown from enchanted bark.', 'armor', 'leather armor', 'epic', 'dexterity', 8, 'defense', 5, 30, 'ranger', 900, NULL, true, 30),
('ms_ranger_lv40', 'Hawk''s Talon Bracelet', 'Carved from a great hawk''s claw.', 'accessory', 'bracelet', 'legendary', 'dexterity', 14, 'luck', 6, 40, 'ranger', 1500, NULL, true, 31),
('ms_ranger_lv50', 'Skypierce, the Eternal Bow', 'The legendary bow of the first ranger.', 'weapon', 'bow', 'legendary', 'dexterity', 16, 'strength', 8, 50, 'ranger', 2500, NULL, true, 32),
('ms_trickster_lv25', 'Fate''s Edge Dagger', 'A dagger guided by destiny.', 'weapon', 'dagger', 'epic', 'luck', 10, 'dexterity', 4, 25, 'trickster', 750, NULL, true, 33),
('ms_trickster_lv30', 'Phantom Cloak', 'A cloak woven from shadow.', 'armor', 'cloak', 'epic', 'luck', 8, 'dexterity', 5, 30, 'trickster', 900, NULL, true, 34),
('ms_trickster_lv40', 'Gambler''s Loaded Dice', 'An enchanted charm bending probability.', 'accessory', 'charm', 'legendary', 'luck', 14, 'charisma', 6, 40, 'trickster', 1500, NULL, true, 35),
('ms_trickster_lv50', 'Whisper of Chaos', 'A legendary dagger across multiple timelines.', 'weapon', 'dagger', 'legendary', 'luck', 16, 'dexterity', 8, 50, 'trickster', 2500, NULL, true, 36)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- GEAR SETS (3 sets from GearSetCatalog.swift)
-- -----------------------------------------------------------
INSERT INTO public.content_gear_sets (id, name, description, character_class_line, pieces_required, bonus_stat, bonus_amount, bonus_description, bonus_type, bonus_value, level_requirement, active) VALUES
('set_warrior', 'Vanguard''s Resolve', 'The armor of frontline champions.', 'warrior', 3, 'defense', 5, '+5 Defense when all 3 pieces equipped', 'flat', 5.0, 8, true),
('set_mage', 'Arcanum''s Embrace', 'Garments of pure arcane energy.', 'mage', 3, 'wisdom', 5, '+5 Wisdom when all 3 pieces equipped', 'flat', 5.0, 8, true),
('set_archer', 'Windstrider''s Mark', 'Gear of the swift and silent.', 'archer', 3, 'dexterity', 5, '+5 Dexterity when all 3 pieces equipped', 'flat', 5.0, 8, true)
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
