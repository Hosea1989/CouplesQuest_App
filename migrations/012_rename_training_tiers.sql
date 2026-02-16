-- =============================================================
-- Rename Training Missions — Distinct Tier-Appropriate Names
--
-- Replaces generic names like "Strength Training" with more
-- distinctive, RPG-flavored names that clearly communicate
-- progression tiers across all three class lines.
-- =============================================================

-- ===========================
-- WARRIOR LINE
-- ===========================
UPDATE public.content_missions SET
    name = 'Iron Foundations',
    description = 'Begin your warrior''s path by lifting heavy stones and swinging weighted weapons to build raw power.'
WHERE id = 'train_warrior_strength';

UPDATE public.content_missions SET
    name = 'Sparring Gauntlet',
    description = 'Test your combat reflexes against the training arena''s toughest dummies and sparring partners.'
WHERE id = 'train_warrior_sparring';

UPDATE public.content_missions SET
    name = 'Bulwark Trials',
    description = 'Endure relentless shield impacts to forge an unbreakable defense. Only the steadfast prevail.'
WHERE id = 'train_warrior_shield';

UPDATE public.content_missions SET
    name = 'Ironclad March',
    description = 'A grueling long-distance march in full armor across hostile terrain. Only the strongest endure.'
WHERE id = 'train_warrior_endurance';

UPDATE public.content_missions SET
    name = 'Crucible of War',
    description = 'An extreme combat regimen that separates warriors from legends. Push your body to its absolute limit.'
WHERE id = 'train_warrior_conditioning';

-- ===========================
-- MAGE LINE
-- ===========================
UPDATE public.content_missions SET
    name = 'Cantrip Studies',
    description = 'Learn the fundamental incantations every mage must master before wielding true power.'
WHERE id = 'train_mage_study';

UPDATE public.content_missions SET
    name = 'Rune Scribing',
    description = 'Study ancient scrolls and practice drawing runes of power to deepen your arcane knowledge.'
WHERE id = 'train_mage_arcane';

UPDATE public.content_missions SET
    name = 'Enchantment Weaving',
    description = 'Practice weaving enchantments into objects, strengthening your force of will and personality.'
WHERE id = 'train_mage_enchantment';

UPDATE public.content_missions SET
    name = 'Elemental Communion',
    description = 'Meditate on primal forces to attune your mind to deeper, more volatile magic.'
WHERE id = 'train_mage_elemental';

UPDATE public.content_missions SET
    name = 'Astral Sanctum',
    description = 'Enter a trance at the boundary of realms, pushing your intellect beyond mortal limits.'
WHERE id = 'train_mage_deep';

-- ===========================
-- ARCHER LINE
-- ===========================
UPDATE public.content_missions SET
    name = 'Steady Aim',
    description = 'Fire arrows at targets from increasing distances to sharpen your aim and focus.'
WHERE id = 'train_archer_target';

UPDATE public.content_missions SET
    name = 'Windrunner Drills',
    description = 'Sprint, dodge, and roll through an obstacle course designed to push your reflexes to the limit.'
WHERE id = 'train_archer_agility';

UPDATE public.content_missions SET
    name = 'Shadowstep Training',
    description = 'Move unseen through dense terrain, sharpening both agility and battlefield awareness.'
WHERE id = 'train_archer_stealth';

UPDATE public.content_missions SET
    name = 'Wilds Endurance',
    description = 'Survive days in the wild relying on nothing but instinct and resourcefulness.'
WHERE id = 'train_archer_wilderness';

UPDATE public.content_missions SET
    name = 'Hawk''s Eye Trial',
    description = 'An exhaustive regimen of trick shots and reaction drills. Only the elite marksmen survive.'
WHERE id = 'train_archer_precision';
