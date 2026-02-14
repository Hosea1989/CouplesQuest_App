-- =============================================================
-- QuestBond Migration 005b — Achievement & Quest Content Tables
-- Run this AFTER 005_content_tables.sql in the Supabase SQL Editor.
--
-- Adds server-driven achievement definitions and daily quest
-- template definitions so new achievements/quests can be added
-- without an app update.
-- =============================================================


-- -----------------------------------------------------------
-- ACHIEVEMENT DEFINITIONS (server-driven, expandable)
-- Replaces static AchievementDefinitions.swift data
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_achievements (
    id                  TEXT PRIMARY KEY,       -- e.g. "ach_first_task"
    name                TEXT NOT NULL,
    description         TEXT NOT NULL DEFAULT '',
    category            TEXT NOT NULL CHECK (category IN (
        'tasks', 'combat', 'social', 'collection', 'wellness',
        'economy', 'exploration', 'milestones', 'prestige'
    )),
    icon                TEXT NOT NULL DEFAULT 'star.fill',
    tracking_type       TEXT NOT NULL CHECK (tracking_type IN ('count', 'streak', 'boolean')),
    target_value        INT NOT NULL DEFAULT 1,
    reward_type         TEXT NOT NULL DEFAULT 'gold' CHECK (reward_type IN (
        'gold', 'gems', 'title', 'equipment', 'consumable'
    )),
    reward_value        INT NOT NULL DEFAULT 0,
    reward_item_id      TEXT,                   -- FK to content_equipment or content_consumables
    is_hidden           BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order          INT NOT NULL DEFAULT 0,
    active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_achievements_category ON public.content_achievements(category);
CREATE INDEX IF NOT EXISTS idx_content_achievements_active ON public.content_achievements(active) WHERE active = TRUE;

ALTER TABLE public.content_achievements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content achievements"
    ON public.content_achievements FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_achievements
    AFTER INSERT OR UPDATE OR DELETE ON public.content_achievements
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- DAILY QUEST DEFINITIONS (server-driven quest templates)
-- Replaces DailyQuestPool.availableTemplates() hardcoded data
--
-- Quest types:
--   completeTasks, completeCategory, startTraining,
--   clearDungeonRooms, earnExp, earnGold, maintainStreak,
--   forgeItem, useConsumable, completeArenaWave,
--   checkMood, completeDuty, partyTaskSync, attemptCardContent
-- -----------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.content_quests (
    id                  TEXT PRIMARY KEY,       -- e.g. "quest_complete_3_tasks_low"
    quest_type          TEXT NOT NULL CHECK (quest_type IN (
        'completeTasks', 'completeCategory', 'startTraining',
        'clearDungeonRooms', 'earnExp', 'earnGold', 'maintainStreak',
        'forgeItem', 'useConsumable', 'completeArenaWave',
        'checkMood', 'completeDuty', 'partyTaskSync', 'attemptCardContent'
    )),
    title               TEXT NOT NULL,
    description         TEXT NOT NULL DEFAULT '',
    target_value        INT NOT NULL DEFAULT 1,
    target_category     TEXT,                   -- for completeCategory quests: "physical", "mental", etc.
    min_level           INT NOT NULL DEFAULT 1,
    max_level           INT,                    -- null = no cap
    weight              DOUBLE PRECISION NOT NULL DEFAULT 1.0, -- selection weight
    reward_gold         INT NOT NULL DEFAULT 0,
    reward_exp          INT NOT NULL DEFAULT 0,
    reward_gems         INT NOT NULL DEFAULT 0,
    is_bonus            BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order          INT NOT NULL DEFAULT 0,
    active              BOOLEAN NOT NULL DEFAULT TRUE,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_content_quests_type ON public.content_quests(quest_type);
CREATE INDEX IF NOT EXISTS idx_content_quests_active ON public.content_quests(active) WHERE active = TRUE;

ALTER TABLE public.content_quests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read content quests"
    ON public.content_quests FOR SELECT
    USING (TRUE);

CREATE TRIGGER bump_version_on_quests
    AFTER INSERT OR UPDATE OR DELETE ON public.content_quests
    FOR EACH STATEMENT EXECUTE FUNCTION public.bump_content_version();


-- -----------------------------------------------------------
-- SEED: Achievement definitions (~40 achievements)
-- Categories: tasks, combat, social, collection, wellness,
--             economy, exploration, milestones, prestige
-- -----------------------------------------------------------
INSERT INTO public.content_achievements (id, name, description, category, icon, tracking_type, target_value, reward_type, reward_value, is_hidden, sort_order) VALUES
    -- Tasks
    ('ach_first_task',          'First Step',           'Complete your first task',                         'tasks',       'checkmark.circle.fill',    'count',   1,    'gold',  50,   FALSE, 1),
    ('ach_task_10',             'Getting Started',      'Complete 10 tasks',                                'tasks',       'flame.fill',               'count',   10,   'gold',  100,  FALSE, 2),
    ('ach_task_50',             'Productive',           'Complete 50 tasks',                                'tasks',       'bolt.fill',                'count',   50,   'gold',  250,  FALSE, 3),
    ('ach_task_100',            'Task Master',          'Complete 100 tasks',                               'tasks',       'star.fill',                'count',   100,  'gold',  500,  FALSE, 4),
    ('ach_task_500',            'Legendary Achiever',   'Complete 500 tasks',                               'tasks',       'crown.fill',               'count',   500,  'gems',  10,   FALSE, 5),
    ('ach_task_1000',           'Unstoppable',          'Complete 1,000 tasks',                             'tasks',       'trophy.fill',              'count',   1000, 'gems',  25,   FALSE, 6),
    ('ach_streak_7',            'Week Warrior',         'Maintain a 7-day streak',                          'tasks',       'flame.fill',               'streak',  7,    'gold',  150,  FALSE, 7),
    ('ach_streak_30',           'Iron Will',            'Maintain a 30-day streak',                         'tasks',       'shield.fill',              'streak',  30,   'gold',  500,  FALSE, 8),
    ('ach_streak_100',          'Unbreakable',          'Maintain a 100-day streak',                        'tasks',       'diamond.fill',             'streak',  100,  'gems',  15,   FALSE, 9),
    ('ach_all_categories',      'Well-Rounded',         'Complete a task in every category',                'tasks',       'circle.grid.3x3.fill',    'count',   6,    'gold',  200,  FALSE, 10),
    ('ach_routine_master',      'Routine Master',       'Complete a routine bundle 10 times',               'tasks',       'repeat',                   'count',   10,   'gold',  300,  FALSE, 11),

    -- Combat / Adventures
    ('ach_first_dungeon',       'Dungeon Crawler',      'Complete your first dungeon',                      'combat',      'shield.lefthalf.filled',   'count',   1,    'gold',  100,  FALSE, 20),
    ('ach_dungeon_10',          'Veteran Explorer',     'Complete 10 dungeons',                             'combat',      'map.fill',                 'count',   10,   'gold',  300,  FALSE, 21),
    ('ach_dungeon_50',          'Dungeon Master',       'Complete 50 dungeons',                             'combat',      'building.columns.fill',    'count',   50,   'gems',  10,   FALSE, 22),
    ('ach_arena_wave_10',       'Arena Fighter',        'Reach wave 10 in the Arena',                       'combat',      'figure.fencing',           'count',   10,   'gold',  200,  FALSE, 23),
    ('ach_arena_wave_25',       'Arena Champion',       'Reach wave 25 in the Arena',                       'combat',      'medal.fill',               'count',   25,   'gems',  10,   FALSE, 24),
    ('ach_raid_boss_first',     'Boss Slayer',          'Defeat your first Raid Boss',                      'combat',      'bolt.shield.fill',         'count',   1,    'gold',  300,  FALSE, 25),
    ('ach_raid_boss_10',        'Raid Veteran',         'Defeat 10 Raid Bosses',                            'combat',      'shield.checkered',         'count',   10,   'gems',  15,   FALSE, 26),
    ('ach_mission_25',          'AFK Specialist',       'Complete 25 AFK missions',                         'combat',      'clock.fill',               'count',   25,   'gold',  250,  FALSE, 27),

    -- Social / Party
    ('ach_first_party',         'Party Formed',         'Join or create a party',                           'social',      'person.2.fill',            'boolean', 1,    'gold',  100,  FALSE, 30),
    ('ach_party_streak_7',      'Team Spirit',          'Maintain a 7-day party streak',                    'social',      'heart.fill',               'streak',  7,    'gold',  200,  FALSE, 31),
    ('ach_party_streak_30',     'Ironbound',            'Maintain a 30-day party streak',                   'social',      'link',                     'streak',  30,   'gems',  10,   FALSE, 32),
    ('ach_assign_task_10',      'Task Delegator',       'Assign 10 tasks to party members',                 'social',      'arrow.up.forward',         'count',   10,   'gold',  150,  FALSE, 33),
    ('ach_party_goal',          'Shared Victory',       'Complete a shared party goal',                     'social',      'flag.fill',                'count',   1,    'gold',  300,  FALSE, 34),

    -- Collection
    ('ach_cards_10',            'Card Novice',          'Collect 10 monster cards',                          'collection',  'rectangle.stack.fill',     'count',   10,   'gold',  150,  FALSE, 40),
    ('ach_cards_25',            'Card Collector',       'Collect 25 monster cards',                          'collection',  'rectangle.stack.fill',     'count',   25,   'gold',  300,  FALSE, 41),
    ('ach_cards_50',            'Bestiary Scholar',     'Collect 50 monster cards',                          'collection',  'book.fill',                'count',   50,   'gems',  10,   FALSE, 42),
    ('ach_equip_epic',          'Epic Find',            'Acquire an Epic rarity item',                      'collection',  'sparkles',                 'count',   1,    'gold',  200,  FALSE, 43),
    ('ach_equip_legendary',     'Legendary Discovery',  'Acquire a Legendary rarity item',                  'collection',  'star.circle.fill',         'count',   1,    'gems',  5,    TRUE,  44),
    ('ach_gear_set',            'Set Collector',        'Complete a gear set',                               'collection',  'square.grid.2x2.fill',     'count',   1,    'gold',  300,  FALSE, 45),

    -- Wellness
    ('ach_mood_7',              'Self-Aware',           'Log your mood for 7 consecutive days',             'wellness',    'heart.text.square.fill',   'streak',  7,    'gold',  100,  FALSE, 50),
    ('ach_mood_30',             'Emotionally Attuned',  'Log your mood for 30 consecutive days',            'wellness',    'brain.head.profile',       'streak',  30,   'gold',  300,  FALSE, 51),
    ('ach_meditation_7',        'Inner Peace',          'Meditate for 7 consecutive days',                  'wellness',    'leaf.fill',                'streak',  7,    'gold',  150,  FALSE, 52),
    ('ach_meditation_30',       'Zen Master',           'Meditate for 30 consecutive days',                 'wellness',    'moon.fill',                'streak',  30,   'gems',  10,   FALSE, 53),

    -- Economy
    ('ach_gold_1000',           'Money Bags',           'Accumulate 1,000 gold',                            'economy',     'dollarsign.circle.fill',   'count',   1000, 'gold',  100,  FALSE, 60),
    ('ach_gold_10000',          'Wealthy',              'Accumulate 10,000 gold',                           'economy',     'banknote.fill',            'count',   10000,'gold',  500,  FALSE, 61),
    ('ach_forge_10',            'Apprentice Smith',     'Forge 10 items',                                   'economy',     'hammer.fill',              'count',   10,   'gold',  200,  FALSE, 62),
    ('ach_enhance_plus5',       'Master Enhancer',      'Enhance an item to +5',                            'economy',     'arrow.up.circle.fill',     'count',   1,    'gold',  300,  FALSE, 63),

    -- Milestones
    ('ach_level_10',            'Rising Star',          'Reach level 10',                                   'milestones',  'arrow.up.right',           'count',   10,   'gold',  200,  FALSE, 70),
    ('ach_level_25',            'Seasoned Adventurer',  'Reach level 25',                                   'milestones',  'person.fill.checkmark',    'count',   25,   'gold',  400,  FALSE, 71),
    ('ach_level_50',            'Elite',                'Reach level 50',                                   'milestones',  'medal.fill',               'count',   50,   'gems',  15,   FALSE, 72),
    ('ach_level_100',           'Centurion',            'Reach level 100',                                  'milestones',  'crown.fill',               'count',   100,  'gems',  30,   FALSE, 73),
    ('ach_goal_setter',         'Goal Setter',          'Create your first goal',                           'milestones',  'target',                   'count',   1,    'gold',  50,   FALSE, 74),
    ('ach_goal_crusher',        'Goal Crusher',         'Complete 5 goals',                                 'milestones',  'checkmark.seal.fill',      'count',   5,    'gold',  300,  FALSE, 75),

    -- Prestige
    ('ach_rebirth_1',           'Reborn',               'Complete your first Rebirth',                      'prestige',    'arrow.counterclockwise',   'count',   1,    'gems',  20,   FALSE, 80),
    ('ach_rebirth_3',           'Eternal',              'Complete 3 Rebirths',                              'prestige',    'infinity',                 'count',   3,    'gems',  50,   FALSE, 81)
ON CONFLICT (id) DO NOTHING;


-- -----------------------------------------------------------
-- SEED: Daily quest definitions
-- Existing types + 7 new types from GAME_DESIGN.md §27
-- Level-scaled reward multiplier: rewardBase * max(1, level / 10)
-- Applied client-side; base values stored here.
-- -----------------------------------------------------------
INSERT INTO public.content_quests (id, quest_type, title, description, target_value, target_category, min_level, max_level, weight, reward_gold, reward_exp, reward_gems, is_bonus, sort_order) VALUES
    -- === Existing quest types ===

    -- completeTasks
    ('quest_complete_2_tasks',      'completeTasks',    'Complete 2 Tasks',             'Finish any 2 tasks today',                 2,  NULL, 1,    NULL, 1.0,   30,  40,  0, FALSE, 1),
    ('quest_complete_3_tasks',      'completeTasks',    'Complete 3 Tasks',             'Finish any 3 tasks today',                 3,  NULL, 1,    NULL, 1.2,   50,  60,  0, FALSE, 2),
    ('quest_complete_5_tasks',      'completeTasks',    'Complete 5 Tasks',             'Finish 5 tasks in a single day',           5,  NULL, 5,    NULL, 0.8,   80,  100, 0, FALSE, 3),

    -- completeCategory
    ('quest_cat_physical_2',        'completeCategory', 'Physical Training',            'Complete 2 Physical tasks',                2,  'physical',   1, NULL, 1.0,   40,  50,  0, FALSE, 10),
    ('quest_cat_mental_2',          'completeCategory', 'Mental Exercise',              'Complete 2 Mental tasks',                  2,  'mental',     1, NULL, 1.0,   40,  50,  0, FALSE, 11),
    ('quest_cat_creative_2',        'completeCategory', 'Creative Spirit',              'Complete 2 Creative tasks',                2,  'creative',   1, NULL, 1.0,   40,  50,  0, FALSE, 12),
    ('quest_cat_social_2',          'completeCategory', 'Social Butterfly',             'Complete 2 Social tasks',                  2,  'social',     1, NULL, 0.8,   40,  50,  0, FALSE, 13),
    ('quest_cat_household_2',       'completeCategory', 'Home Keeper',                  'Complete 2 Household tasks',               2,  'household',  1, NULL, 0.8,   40,  50,  0, FALSE, 14),
    ('quest_cat_wellness_2',        'completeCategory', 'Wellness Focus',               'Complete 2 Wellness tasks',                2,  'wellness',   1, NULL, 0.8,   40,  50,  0, FALSE, 15),

    -- startTraining
    ('quest_start_training',        'startTraining',    'Send Forth',                   'Start a training mission',                 1,  NULL, 1,    NULL, 1.0,   30,  35,  0, FALSE, 20),

    -- clearDungeonRooms
    ('quest_clear_3_rooms',         'clearDungeonRooms','Dungeon Delver',               'Clear 3 dungeon rooms',                    3,  NULL, 3,    NULL, 1.0,   50,  60,  0, FALSE, 30),
    ('quest_clear_5_rooms',         'clearDungeonRooms','Deep Explorer',                'Clear 5 dungeon rooms',                    5,  NULL, 5,    NULL, 0.8,   80,  100, 0, FALSE, 31),

    -- earnExp
    ('quest_earn_200_exp',          'earnExp',          'EXP Grinder',                  'Earn 200 EXP today',                       200, NULL, 1,   NULL, 1.0,   40,  50,  0, FALSE, 40),
    ('quest_earn_500_exp',          'earnExp',          'EXP Hunter',                   'Earn 500 EXP today',                       500, NULL, 5,   NULL, 0.8,   70,  80,  0, FALSE, 41),

    -- earnGold
    ('quest_earn_100_gold',         'earnGold',         'Gold Collector',               'Earn 100 Gold today',                      100, NULL, 1,   NULL, 1.0,   40,  50,  0, FALSE, 50),
    ('quest_earn_300_gold',         'earnGold',         'Treasure Hunter',              'Earn 300 Gold today',                      300, NULL, 5,   NULL, 0.8,   60,  70,  0, FALSE, 51),

    -- maintainStreak
    ('quest_maintain_streak',       'maintainStreak',   'Keep It Going',                'Maintain your daily streak',               1,  NULL, 1,    NULL, 1.0,   25,  30,  0, FALSE, 60),

    -- === New quest types (7 from GAME_DESIGN.md §27) ===

    -- forgeItem
    ('quest_forge_item',            'forgeItem',        'Forge Ahead',                  'Forge or enhance 1 item',                  1,  NULL, 5,    NULL, 0.9,   50,  60,  0, FALSE, 70),

    -- useConsumable
    ('quest_use_consumable',        'useConsumable',    'Potion Drinker',               'Use a consumable item',                    1,  NULL, 3,    NULL, 0.9,   30,  35,  0, FALSE, 71),

    -- completeArenaWave
    ('quest_arena_wave_3',          'completeArenaWave','Arena Warm-Up',                'Reach wave 3 in the Arena',                3,  NULL, 5,    NULL, 0.8,   50,  60,  0, FALSE, 72),
    ('quest_arena_wave_5',          'completeArenaWave','Arena Challenge',              'Reach wave 5 in the Arena',                5,  NULL, 10,   NULL, 0.6,   80,  100, 0, FALSE, 73),

    -- checkMood
    ('quest_check_mood',            'checkMood',        'How Are You?',                 'Log your mood today',                      1,  NULL, 1,    NULL, 1.0,   25,  30,  0, FALSE, 74),

    -- completeDuty
    ('quest_complete_duty',         'completeDuty',     'Duty Bound',                   'Complete a duty board task',               1,  NULL, 1,    NULL, 1.0,   35,  40,  0, FALSE, 75),
    ('quest_complete_2_duties',     'completeDuty',     'Board Sweeper',                'Complete 2 duty board tasks',              2,  NULL, 3,    NULL, 0.7,   60,  70,  0, FALSE, 76),

    -- partyTaskSync
    ('quest_party_sync',            'partyTaskSync',    'In Sync',                      'Complete a task within 1 hour of a party member', 1, NULL, 1, NULL, 0.6, 50, 60, 0, FALSE, 77),

    -- attemptCardContent
    ('quest_attempt_card',          'attemptCardContent','Card Hunter',                  'Attempt content that can drop a card',     1,  NULL, 5,    NULL, 0.8,   40,  50,  0, FALSE, 78),

    -- === Bonus quests (is_bonus = true, shown as 4th quest) ===
    ('quest_bonus_all_3',           'completeTasks',    'Daily Champion',               'Complete all 3 daily quests',              3,  NULL, 1,    NULL, 1.0,   80,  100, 1, TRUE, 90),
    ('quest_bonus_5_tasks',         'completeTasks',    'Overachiever',                 'Complete 5 tasks after finishing all quests', 5, NULL, 5,  NULL, 0.8,  100,  120, 1, TRUE, 91)
ON CONFLICT (id) DO NOTHING;


-- =============================================================
-- DONE
-- Verify: SELECT count(*) FROM content_achievements;
--         SELECT count(*) FROM content_quests;
-- =============================================================
