#!/usr/bin/env python3
"""
Tarot Reading Engine
Full 78-card Rider-Waite deck with multiple spread types,
reversals, card interactions, and Jungian archetype mapping.
"""

import json
import random
import sys
import argparse
from datetime import datetime


# ---------------------------------------------------------------------------
# Full 78-Card Rider-Waite Deck
# ---------------------------------------------------------------------------

MAJOR_ARCANA = [
    {
        "name": "The Fool", "number": 0, "type": "major",
        "upright": "New beginnings, innocence, spontaneity, free spirit, leap of faith",
        "reversed": "Recklessness, naivety, foolishness, risk-taking without thought, stagnation",
        "keywords": ["beginning", "innocence", "adventure", "potential"],
        "element": "Air", "planet": "Uranus",
        "numerology": 0, "numerology_meaning": "Infinite potential, the void before creation",
        "archetype": "The Innocent",
        "jungian": "The beginning of individuation; the ego before it encounters the shadow",
        "yes_no": "Yes",
    },
    {
        "name": "The Magician", "number": 1, "type": "major",
        "upright": "Willpower, manifestation, resourcefulness, skill, concentration",
        "reversed": "Manipulation, trickery, untapped potential, wasted talent, deception",
        "keywords": ["manifestation", "willpower", "creation", "mastery"],
        "element": "Air", "planet": "Mercury",
        "numerology": 1, "numerology_meaning": "Unity, beginnings, individuality",
        "archetype": "The Magician",
        "jungian": "The conscious ego wielding the four functions (thinking, feeling, sensing, intuiting)",
        "yes_no": "Yes",
    },
    {
        "name": "The High Priestess", "number": 2, "type": "major",
        "upright": "Intuition, sacred knowledge, divine feminine, the subconscious mind, mystery",
        "reversed": "Secrets kept, withdrawal, silence, repressed intuition, surface knowledge",
        "keywords": ["intuition", "mystery", "inner voice", "unconscious"],
        "element": "Water", "planet": "Moon",
        "numerology": 2, "numerology_meaning": "Duality, balance, receptivity",
        "archetype": "The Anima",
        "jungian": "The anima/animus — the unconscious feminine wisdom within",
        "yes_no": "Neutral",
    },
    {
        "name": "The Empress", "number": 3, "type": "major",
        "upright": "Fertility, beauty, nature, abundance, nurturing, sensuality",
        "reversed": "Creative block, dependence, emptiness, smothering, neglect of self",
        "keywords": ["abundance", "nurturing", "fertility", "nature"],
        "element": "Earth", "planet": "Venus",
        "numerology": 3, "numerology_meaning": "Creation, expression, growth",
        "archetype": "The Great Mother",
        "jungian": "The nurturing mother archetype; embodiment of creative life force",
        "yes_no": "Yes",
    },
    {
        "name": "The Emperor", "number": 4, "type": "major",
        "upright": "Authority, structure, control, fatherhood, stability, discipline",
        "reversed": "Tyranny, rigidity, coldness, excessive control, lack of discipline",
        "keywords": ["authority", "structure", "stability", "control"],
        "element": "Fire", "planet": "Aries",
        "numerology": 4, "numerology_meaning": "Stability, order, foundation",
        "archetype": "The Father",
        "jungian": "The animus; the ordering principle of consciousness",
        "yes_no": "Yes",
    },
    {
        "name": "The Hierophant", "number": 5, "type": "major",
        "upright": "Tradition, conformity, morality, ethics, spiritual wisdom, education",
        "reversed": "Rebellion, subversiveness, new approaches, personal beliefs, freedom",
        "keywords": ["tradition", "teaching", "belief", "conformity"],
        "element": "Earth", "planet": "Taurus",
        "numerology": 5, "numerology_meaning": "Change, freedom, adventure",
        "archetype": "The Sage",
        "jungian": "The Wise Old Man; collective wisdom and institutional knowledge",
        "yes_no": "Neutral",
    },
    {
        "name": "The Lovers", "number": 6, "type": "major",
        "upright": "Love, harmony, relationships, values alignment, choices, union",
        "reversed": "Disharmony, imbalance, misalignment, indecision, temptation",
        "keywords": ["love", "union", "choice", "values"],
        "element": "Air", "planet": "Gemini",
        "numerology": 6, "numerology_meaning": "Harmony, responsibility, love",
        "archetype": "The Lover",
        "jungian": "Integration of opposites; the sacred marriage of anima and animus",
        "yes_no": "Yes",
    },
    {
        "name": "The Chariot", "number": 7, "type": "major",
        "upright": "Control, willpower, victory, assertion, determination, triumph",
        "reversed": "Aggression, lack of control, lack of direction, opposition, defeat",
        "keywords": ["victory", "willpower", "determination", "triumph"],
        "element": "Water", "planet": "Cancer",
        "numerology": 7, "numerology_meaning": "Reflection, spirituality, analysis",
        "archetype": "The Warrior",
        "jungian": "The ego triumphing through integration of opposing forces",
        "yes_no": "Yes",
    },
    {
        "name": "Strength", "number": 8, "type": "major",
        "upright": "Inner strength, bravery, compassion, patience, self-control, soft power",
        "reversed": "Weakness, self-doubt, raw emotion, insecurity, lack of confidence",
        "keywords": ["courage", "patience", "compassion", "inner power"],
        "element": "Fire", "planet": "Leo",
        "numerology": 8, "numerology_meaning": "Power, mastery, material success",
        "archetype": "The Hero",
        "jungian": "Taming the shadow through love rather than force",
        "yes_no": "Yes",
    },
    {
        "name": "The Hermit", "number": 9, "type": "major",
        "upright": "Soul searching, introspection, inner guidance, solitude, contemplation",
        "reversed": "Isolation, loneliness, withdrawal, anti-social, rejection of guidance",
        "keywords": ["introspection", "solitude", "wisdom", "guidance"],
        "element": "Earth", "planet": "Virgo",
        "numerology": 9, "numerology_meaning": "Completion, wisdom, humanitarianism",
        "archetype": "The Hermit",
        "jungian": "Withdrawal for individuation; the inner journey away from the collective",
        "yes_no": "No",
    },
    {
        "name": "Wheel of Fortune", "number": 10, "type": "major",
        "upright": "Good luck, karma, life cycles, destiny, turning point, change",
        "reversed": "Bad luck, resistance to change, breaking cycles, unwelcome change",
        "keywords": ["destiny", "cycles", "fortune", "turning point"],
        "element": "Fire", "planet": "Jupiter",
        "numerology": 1, "numerology_meaning": "New cycle beginning (1+0=1)",
        "archetype": "The Wheel",
        "jungian": "The Self rotating through phases of individuation; fate vs free will",
        "yes_no": "Yes",
    },
    {
        "name": "Justice", "number": 11, "type": "major",
        "upright": "Justice, fairness, truth, cause and effect, law, accountability",
        "reversed": "Unfairness, dishonesty, lack of accountability, avoidance of truth",
        "keywords": ["truth", "fairness", "law", "accountability"],
        "element": "Air", "planet": "Libra",
        "numerology": 2, "numerology_meaning": "Balance, judgment, duality (1+1=2)",
        "archetype": "The Judge",
        "jungian": "The balancing function of the psyche; integrating moral consciousness",
        "yes_no": "Neutral",
    },
    {
        "name": "The Hanged Man", "number": 12, "type": "major",
        "upright": "Surrender, letting go, new perspective, pause, sacrifice, release",
        "reversed": "Stalling, needless sacrifice, fear of sacrifice, indecision, resistance",
        "keywords": ["surrender", "perspective", "sacrifice", "pause"],
        "element": "Water", "planet": "Neptune",
        "numerology": 3, "numerology_meaning": "Creative surrender, gestation (1+2=3)",
        "archetype": "The Martyr",
        "jungian": "Ego death; suspension of the dominant attitude to access the unconscious",
        "yes_no": "Neutral",
    },
    {
        "name": "Death", "number": 13, "type": "major",
        "upright": "Endings, change, transformation, transition, release, inevitable",
        "reversed": "Resistance to change, stagnation, decay, fear of endings, inability to move on",
        "keywords": ["transformation", "ending", "transition", "release"],
        "element": "Water", "planet": "Scorpio",
        "numerology": 4, "numerology_meaning": "Restructuring through destruction (1+3=4)",
        "archetype": "The Transformer",
        "jungian": "Psychic death and rebirth; the dissolution of outdated ego structures",
        "yes_no": "No",
    },
    {
        "name": "Temperance", "number": 14, "type": "major",
        "upright": "Balance, moderation, patience, purpose, healing, integration",
        "reversed": "Imbalance, excess, lack of patience, discord, misalignment",
        "keywords": ["balance", "moderation", "patience", "healing"],
        "element": "Fire", "planet": "Sagittarius",
        "numerology": 5, "numerology_meaning": "Dynamic balance, adaptation (1+4=5)",
        "archetype": "The Alchemist",
        "jungian": "The transcendent function; blending opposites into a new synthesis",
        "yes_no": "Yes",
    },
    {
        "name": "The Devil", "number": 15, "type": "major",
        "upright": "Shadow self, attachment, addiction, restriction, materialism, bondage",
        "reversed": "Releasing limiting beliefs, exploring dark thoughts, detachment, freedom",
        "keywords": ["shadow", "bondage", "materialism", "temptation"],
        "element": "Earth", "planet": "Capricorn",
        "numerology": 6, "numerology_meaning": "Choices in bondage vs freedom (1+5=6)",
        "archetype": "The Shadow",
        "jungian": "Direct encounter with the shadow; projected evil and repressed desires",
        "yes_no": "No",
    },
    {
        "name": "The Tower", "number": 16, "type": "major",
        "upright": "Sudden change, upheaval, chaos, revelation, awakening, destruction",
        "reversed": "Fear of change, averting disaster, delaying the inevitable, resistance",
        "keywords": ["upheaval", "destruction", "revelation", "awakening"],
        "element": "Fire", "planet": "Mars",
        "numerology": 7, "numerology_meaning": "Spiritual crisis, forced introspection (1+6=7)",
        "archetype": "The Destroyer",
        "jungian": "Shattering of the persona; ego collapse that precedes transformation",
        "yes_no": "No",
    },
    {
        "name": "The Star", "number": 17, "type": "major",
        "upright": "Hope, faith, purpose, renewal, spirituality, inspiration, serenity",
        "reversed": "Lack of faith, despair, disconnection, insecurity, discouragement",
        "keywords": ["hope", "renewal", "inspiration", "faith"],
        "element": "Air", "planet": "Aquarius",
        "numerology": 8, "numerology_meaning": "Cosmic order restored, spiritual abundance (1+7=8)",
        "archetype": "The Star Child",
        "jungian": "Reconnection with the Self after the Tower's destruction; renewed wholeness",
        "yes_no": "Yes",
    },
    {
        "name": "The Moon", "number": 18, "type": "major",
        "upright": "Illusion, fear, anxiety, subconscious, intuition, confusion, deception",
        "reversed": "Release of fear, repressed emotion, inner confusion, clarity emerging",
        "keywords": ["illusion", "fear", "intuition", "subconscious"],
        "element": "Water", "planet": "Pisces",
        "numerology": 9, "numerology_meaning": "Completion of unconscious journey (1+8=9)",
        "archetype": "The Shapeshifter",
        "jungian": "The deep unconscious; navigation through illusion toward authentic self",
        "yes_no": "No",
    },
    {
        "name": "The Sun", "number": 19, "type": "major",
        "upright": "Positivity, fun, warmth, success, vitality, joy, confidence",
        "reversed": "Inner child, feeling down, overly optimistic, temporary depression",
        "keywords": ["joy", "success", "vitality", "warmth"],
        "element": "Fire", "planet": "Sun",
        "numerology": 1, "numerology_meaning": "New dawn, conscious illumination (1+9=10=1)",
        "archetype": "The Divine Child",
        "jungian": "Conscious illumination; the ego aligned with the Self in radiant wholeness",
        "yes_no": "Yes",
    },
    {
        "name": "Judgement", "number": 20, "type": "major",
        "upright": "Judgement, rebirth, inner calling, absolution, reflection, reckoning",
        "reversed": "Self-doubt, refusal of self-examination, ignoring the call, lack of reflection",
        "keywords": ["rebirth", "calling", "reckoning", "absolution"],
        "element": "Fire", "planet": "Pluto",
        "numerology": 2, "numerology_meaning": "Higher judgment, cosmic balance (2+0=2)",
        "archetype": "The Redeemer",
        "jungian": "The call to individuation; answering the summons of the Self",
        "yes_no": "Yes",
    },
    {
        "name": "The World", "number": 21, "type": "major",
        "upright": "Completion, integration, accomplishment, travel, wholeness, fulfillment",
        "reversed": "Incompletion, shortcuts, delays, emptiness despite achievement",
        "keywords": ["completion", "wholeness", "accomplishment", "integration"],
        "element": "Earth", "planet": "Saturn",
        "numerology": 3, "numerology_meaning": "Cosmic creation complete, trinity achieved (2+1=3)",
        "archetype": "The Self",
        "jungian": "Full individuation; the mandala of the integrated psyche",
        "yes_no": "Yes",
    },
]

# Minor Arcana suits
SUITS = {
    "Wands": {"element": "Fire", "domain": "passion, creativity, ambition, energy",
              "jungian_function": "Intuition"},
    "Cups": {"element": "Water", "domain": "emotions, relationships, feelings, intuition",
             "jungian_function": "Feeling"},
    "Swords": {"element": "Air", "domain": "intellect, conflict, truth, communication",
               "jungian_function": "Thinking"},
    "Pentacles": {"element": "Earth", "domain": "material, career, money, health, body",
                  "jungian_function": "Sensation"},
}

COURT_RANKS = {
    "Page": {"archetype": "The Student", "maturity": "youth/learning",
             "jungian": "Initial awareness of the suit's function"},
    "Knight": {"archetype": "The Seeker", "maturity": "young adult/action",
               "jungian": "Active pursuit and sometimes excess of the suit's quality"},
    "Queen": {"archetype": "The Nurturer", "maturity": "mature/receptive",
              "jungian": "Internalized mastery of the suit's quality; inner authority"},
    "King": {"archetype": "The Authority", "maturity": "elder/directive",
             "jungian": "Externalized mastery; commanding expression of the suit's quality"},
}

# Pip card meanings (Ace through 10) — universal across suits, specified per suit
PIP_MEANINGS = {
    "Wands": {
        1:  ("Inspiration, new venture, creative spark, potential",
             "Delays, lack of motivation, creative block, hesitation"),
        2:  ("Planning, future progress, decisions, discovery, leaving comfort",
             "Fear of change, indecision, bad planning, playing it safe"),
        3:  ("Expansion, foresight, overseas, enterprise, growth",
             "Obstacles, delays, frustration, lack of foresight, unrealistic goals"),
        4:  ("Celebration, harmony, homecoming, prosperity, reunion",
             "Transition, personal celebration, lack of harmony, incomplete"),
        5:  ("Conflict, disagreement, competition, tension, diversity",
             "Avoiding conflict, resolution, diversity of thought, compromise"),
        6:  ("Victory, success, public recognition, progress, self-confidence",
             "Excess pride, fall from grace, lack of recognition, egotism"),
        7:  ("Challenge, competition, perseverance, defending position",
             "Overwhelmed, giving up, exhaustion, admitting defeat, burnout"),
        8:  ("Rapid action, movement, quick decisions, air travel, momentum",
             "Delays, frustration, holding off, slow progress, scattered energy"),
        9:  ("Resilience, grit, last stand, persistence, boundaries",
             "Paranoia, defensiveness, stubbornness, overwhelm, rigidity"),
        10: ("Burden, responsibility, hard work, stress, obligation, duty",
             "Inability to delegate, overstressed, breakdown, carrying too much"),
    },
    "Cups": {
        1:  ("New love, compassion, creativity, emotional beginning, intuition",
             "Emptiness, emotional loss, blocked creativity, repressed feelings"),
        2:  ("Unified love, partnership, mutual attraction, connection, balance",
             "Self-love needed, break-up, disharmony, imbalance in relationship"),
        3:  ("Celebration, friendship, community, creativity, collaboration",
             "Overindulgence, gossip, isolation, excess, superficial socializing"),
        4:  ("Meditation, contemplation, apathy, reevaluation, withdrawal",
             "Retreat, burnout, motivation returning, new perspective emerging"),
        5:  ("Regret, failure, disappointment, pessimism, grief, loss",
             "Acceptance, moving on, finding peace, forgiveness, recovery"),
        6:  ("Revisiting the past, childhood memories, innocence, nostalgia, joy",
             "Stuck in the past, unrealistic memories, naivety, inability to grow"),
        7:  ("Fantasy, illusion, wishful thinking, choices, imagination, temptation",
             "Alignment, personal values, overwhelmed by choices, clarity needed"),
        8:  ("Disappointment, abandonment, withdrawal, escapism, searching for truth",
             "Avoidance, fear of moving on, stagnation, fear of the unknown"),
        9:  ("Contentment, satisfaction, gratitude, wish come true, emotional stability",
             "Inner happiness lacking, dissatisfaction, greed, materialism over spirit"),
        10: ("Divine love, blissful relationships, harmony, alignment, family happiness",
             "Broken family, dysfunction, divorce, misalignment of values"),
    },
    "Swords": {
        1:  ("Breakthrough, clarity, sharp mind, new idea, truth, mental force",
             "Confusion, chaos, lack of clarity, brutal honesty, intellectual tyranny"),
        2:  ("Indecision, choices, stalemate, avoidance, truce, blocked emotions",
             "Information overload, lesser of evils, indecision resolved, facing truth"),
        3:  ("Heartbreak, emotional pain, sorrow, grief, separation, betrayal",
             "Recovery, forgiveness, moving on, releasing pain, optimism returning"),
        4:  ("Rest, recovery, contemplation, passive, recuperation, solitude",
             "Exhaustion, burnout, restlessness, stagnation, isolation becoming harmful"),
        5:  ("Conflict, disagreements, competition, defeat, winning at all costs",
             "Reconciliation, making amends, past resentment, desire for peace"),
        6:  ("Transition, change, moving on, rite of passage, letting go, travel",
             "Unfinished business, resistance to change, stuckness, delayed transition"),
        7:  ("Deception, trickery, tactics, strategy, scheming, resourcefulness",
             "Coming clean, rethinking approach, conscience, confession, honesty"),
        8:  ("Restriction, imprisonment, victim mentality, self-limiting, trapped",
             "Self-acceptance, new perspective, freedom, releasing self-imposed limits"),
        9:  ("Anxiety, worry, fear, depression, nightmares, overthinking, despair",
             "Inner turmoil ending, hope, reaching out, recovery, dawn after dark night"),
        10: ("Painful endings, deep wounds, betrayal, loss, crisis, rock bottom",
             "Recovery, regeneration, resisting end, learning from pain, resilience"),
    },
    "Pentacles": {
        1:  ("New financial opportunity, prosperity, manifestation, abundance, solid start",
             "Lost opportunity, lack of planning, financial caution, missed chance"),
        2:  ("Multiple priorities, time management, adaptability, balance, juggling",
             "Over-committed, disorganized, reprioritization needed, financial stress"),
        3:  ("Teamwork, collaboration, learning, implementation, craftsmanship, skill",
             "Lack of teamwork, disregard for skills, poor quality, misaligned effort"),
        4:  ("Security, conservation, control, stability, possessiveness, savings",
             "Greediness, materialism, self-protection, hoarding, stinginess"),
        5:  ("Financial loss, poverty, lack mindset, isolation, worry, insecurity",
             "Recovery from loss, spiritual poverty, turning point, re-evaluation"),
        6:  ("Giving, receiving, sharing wealth, generosity, charity, gratitude",
             "Strings attached, debt, selfishness, one-sided charity, power imbalance"),
        7:  ("Long-term view, sustainable results, perseverance, patience, investment",
             "Lack of long-term vision, impatience, limited reward, frustration"),
        8:  ("Apprenticeship, repetitive tasks, mastery, skill development, dedication",
             "Self-development lacking, perfectionism, misdirected activity, boredom"),
        9:  ("Abundance, luxury, self-sufficiency, financial independence, discipline",
             "Over-investment in work, superficial success, hustling, financial setbacks"),
        10: ("Wealth, financial security, family, long-term success, legacy, establishment",
             "Financial failure, loneliness despite wealth, family disputes, loss of legacy"),
    },
}

COURT_MEANINGS = {
    "Wands": {
        "Page":   ("Exploration, excitement, free spirit, creative spark, new message",
                    "Newly found passion fading, hasty decisions, lack of direction"),
        "Knight": ("Energy, passion, adventure, impulsiveness, inspired action",
                    "Haste, scattered energy, delays, frustration, recklessness"),
        "Queen":  ("Courage, determination, joy, vibrancy, warmth, confidence",
                    "Jealousy, insecurity, selfishness, demanding, temperamental"),
        "King":   ("Natural leader, vision, entrepreneur, honour, bold decisions",
                    "Impulsive, overbearing, tyrannical, vain, unrealistic expectations"),
    },
    "Cups": {
        "Page":   ("Creative opportunity, intuitive message, curiosity, emotional opening",
                    "Emotional immaturity, insecurity, broken dreams, creative block"),
        "Knight": ("Romance, charm, imagination, beauty, following the heart",
                    "Unrealistic, jealousy, moodiness, emotional manipulation"),
        "Queen":  ("Compassion, calm, comfort, emotional security, intuitive healer",
                    "Co-dependency, inner feelings lost, martyrdom, smothering"),
        "King":   ("Emotionally balanced, diplomatic, generous, wisdom of the heart",
                    "Manipulation, emotional volatility, moodiness, coldness"),
    },
    "Swords": {
        "Page":   ("New ideas, curiosity, thirst for knowledge, mental agility, truth-seeking",
                    "Scattered thinking, deception, hurtful words, all talk no action"),
        "Knight": ("Ambitious, action-oriented, driven, fast-thinking, assertive",
                    "Impulsive, no direction, disregard for consequences, aggressive"),
        "Queen":  ("Clear thinking, independent, unbiased judgement, direct communication",
                    "Cold-hearted, bitter, cruel, pessimistic, overly critical"),
        "King":   ("Intellectual power, authority, truth, analytical, ethical leadership",
                    "Quiet power misused, manipulative, tyrannical, cold, ruthless"),
    },
    "Pentacles": {
        "Page":   ("Manifestation, financial opportunity, skill development, new venture",
                    "Lack of progress, procrastination, learn from failure, unfocused"),
        "Knight": ("Hard work, responsibility, routine, conservatism, methodical progress",
                    "Stubbornness, laziness, boredom, feeling stuck, complacency"),
        "Queen":  ("Nurturing, practical, providing financially, working parent, security",
                    "Self-centeredness, jealousy, smothering, work-home imbalance"),
        "King":   ("Wealth, business, leadership, security, discipline, abundance",
                    "Financially inept, obsessed with wealth, stubborn, materialistic"),
    },
}


def build_full_deck():
    """Build the complete 78-card deck."""
    deck = []

    # Major Arcana
    for card in MAJOR_ARCANA:
        deck.append(card)

    # Minor Arcana: Pips (Ace-10) + Court (Page, Knight, Queen, King)
    for suit, suit_info in SUITS.items():
        # Pips
        for num in range(1, 11):
            name = f"Ace of {suit}" if num == 1 else f"{num} of {suit}"
            up, rev = PIP_MEANINGS[suit][num]
            deck.append({
                "name": name, "number": num, "type": "minor", "suit": suit,
                "upright": up, "reversed": rev,
                "keywords": [w.strip() for w in up.split(",")[:3]],
                "element": suit_info["element"],
                "numerology": num,
                "numerology_meaning": f"{''.join(str(num))} energy in {suit_info['domain'].split(',')[0]}",
                "archetype": f"The {['', 'Seed', 'Balance', 'Growth', 'Foundation', 'Challenge', 'Harmony', 'Reflection', 'Mastery', 'Wisdom', 'Completion'][num]}",
                "jungian": f"{suit_info['jungian_function']} function at stage {num}",
                "yes_no": "Yes" if num in [1, 3, 6, 9, 10] else "No" if num in [5, 7, 8] else "Neutral",
            })
        # Court cards
        for rank, rank_info in COURT_RANKS.items():
            up, rev = COURT_MEANINGS[suit][rank]
            deck.append({
                "name": f"{rank} of {suit}", "number": {"Page": 11, "Knight": 12, "Queen": 13, "King": 14}[rank],
                "type": "court", "suit": suit, "rank": rank,
                "upright": up, "reversed": rev,
                "keywords": [w.strip() for w in up.split(",")[:3]],
                "element": suit_info["element"],
                "numerology": {"Page": 11, "Knight": 12, "Queen": 13, "King": 14}[rank],
                "numerology_meaning": f"{rank_info['maturity']} expression of {suit_info['element']}",
                "archetype": rank_info["archetype"],
                "jungian": rank_info["jungian"],
                "yes_no": "Neutral",
            })

    return deck


# ---------------------------------------------------------------------------
# Spread definitions
# ---------------------------------------------------------------------------

SPREADS = {
    "3-card": {
        "name": "Three Card Spread",
        "card_count": 3,
        "positions": [
            {"position": 1, "name": "Past", "description": "What has led to this moment"},
            {"position": 2, "name": "Present", "description": "Current situation and energy"},
            {"position": 3, "name": "Future", "description": "Where things are heading"},
        ],
    },
    "celtic-cross": {
        "name": "Celtic Cross",
        "card_count": 10,
        "positions": [
            {"position": 1, "name": "Present", "description": "The current situation"},
            {"position": 2, "name": "Challenge", "description": "The immediate obstacle or crossing energy"},
            {"position": 3, "name": "Foundation", "description": "The basis of the situation, subconscious influence"},
            {"position": 4, "name": "Recent Past", "description": "Events recently passed, fading influence"},
            {"position": 5, "name": "Crown", "description": "Best possible outcome, conscious goal"},
            {"position": 6, "name": "Near Future", "description": "What is approaching in the near term"},
            {"position": 7, "name": "Self", "description": "Your attitude and approach to the situation"},
            {"position": 8, "name": "Environment", "description": "External influences, other people's energy"},
            {"position": 9, "name": "Hopes and Fears", "description": "Your deepest hopes or fears about the outcome"},
            {"position": 10, "name": "Outcome", "description": "The likely outcome if current energies continue"},
        ],
    },
    "relationship": {
        "name": "Relationship Spread",
        "card_count": 7,
        "positions": [
            {"position": 1, "name": "You", "description": "Your energy in the relationship"},
            {"position": 2, "name": "Partner", "description": "Your partner's energy"},
            {"position": 3, "name": "Connection", "description": "What unites you"},
            {"position": 4, "name": "Challenge", "description": "What divides or challenges you"},
            {"position": 5, "name": "Strength", "description": "The relationship's greatest strength"},
            {"position": 6, "name": "Action", "description": "What action is needed"},
            {"position": 7, "name": "Potential", "description": "The relationship's highest potential"},
        ],
    },
    "career": {
        "name": "Career Spread",
        "card_count": 5,
        "positions": [
            {"position": 1, "name": "Current Position", "description": "Where you stand professionally"},
            {"position": 2, "name": "Aspiration", "description": "What you truly want career-wise"},
            {"position": 3, "name": "Hidden Influence", "description": "Unseen factors affecting your career"},
            {"position": 4, "name": "Obstacle", "description": "What stands in your way"},
            {"position": 5, "name": "Advice", "description": "Guidance for your next career move"},
        ],
    },
}


# ---------------------------------------------------------------------------
# Card combination interactions
# ---------------------------------------------------------------------------

COMBO_PATTERNS = [
    {
        "cards": ["The Tower", "Death"],
        "theme": "Cataclysmic Transformation",
        "meaning": "A profound, unavoidable upheaval that completely restructures reality. The old self must die for radical rebirth. This is not gentle change — it is a psychic earthquake.",
    },
    {
        "cards": ["The Lovers", "The Devil"],
        "theme": "Toxic Attachment",
        "meaning": "A relationship or desire that appears as love but contains elements of bondage, obsession, or codependency. The shadow side of desire is exposed.",
    },
    {
        "cards": ["The Moon", "The High Priestess"],
        "theme": "Deep Unconscious Activation",
        "meaning": "The psyche is speaking loudly through dreams, intuition, and synchronicities. Trust the irrational. The rational mind cannot access what needs to be known.",
    },
    {
        "cards": ["The Sun", "The World"],
        "theme": "Complete Fulfillment",
        "meaning": "Absolute alignment between inner joy and outer achievement. A rare moment of total coherence. Celebrate and integrate this peak experience.",
    },
    {
        "cards": ["The Emperor", "The Empress"],
        "theme": "Sacred Union of Opposites",
        "meaning": "Balance between masculine structure and feminine nurture. Whether in a relationship or within oneself, the archetypal parents are in harmony.",
    },
    {
        "cards": ["The Hermit", "The Star"],
        "theme": "Illuminated Solitude",
        "meaning": "Withdrawal leads to profound spiritual insight. The isolation is purposeful — it is in the silence that the star appears. Trust the quiet path.",
    },
    {
        "cards": ["Wheel of Fortune", "The Chariot"],
        "theme": "Destiny in Motion",
        "meaning": "Fate is accelerating. The universe is moving you toward a predetermined destination. Your willpower and the cosmic current are aligned — ride the wave.",
    },
    {
        "cards": ["The Magician", "The Fool"],
        "theme": "Infinite Creative Potential",
        "meaning": "All tools are available and the spirit is free. This is the most powerful manifestation combination — pure potential meeting conscious will. Begin now.",
    },
    {
        "cards": ["Judgement", "The Tower"],
        "theme": "Karmic Reckoning",
        "meaning": "Past actions return with force. Structures built on false foundations collapse as truth demands acknowledgment. Accountability is unavoidable.",
    },
    {
        "cards": ["Strength", "The Devil"],
        "theme": "Shadow Integration",
        "meaning": "The courage to face one's darkest impulses with compassion rather than suppression. True strength comes from embracing, not denying, the shadow.",
    },
]


def find_card_combos(drawn_cards):
    """Find any meaningful combinations among drawn cards."""
    card_names = set()
    for c in drawn_cards:
        card_names.add(c["card"]["name"])

    combos = []
    for pattern in COMBO_PATTERNS:
        if all(name in card_names for name in pattern["cards"]):
            combos.append(pattern)

    return combos


# ---------------------------------------------------------------------------
# Drawing engine
# ---------------------------------------------------------------------------

def draw_cards(spread_name, seed=None, question=""):
    """Draw cards for a spread with optional seed for reproducibility."""
    if seed is not None:
        random.seed(seed)
    else:
        random.seed()

    deck = build_full_deck()
    spread = SPREADS.get(spread_name)
    if not spread:
        raise ValueError(f"Unknown spread: {spread_name}. Available: {list(SPREADS.keys())}")

    # Shuffle
    random.shuffle(deck)

    drawn = []
    for i, pos in enumerate(spread["positions"]):
        card = deck[i]
        is_reversed = random.random() < 0.35  # ~35% reversal rate

        drawn.append({
            "position": pos,
            "card": card,
            "reversed": is_reversed,
            "active_meaning": card["reversed"] if is_reversed else card["upright"],
            "orientation": "Reversed" if is_reversed else "Upright",
        })

    return drawn, spread


# ---------------------------------------------------------------------------
# Elemental analysis
# ---------------------------------------------------------------------------

def analyze_elements(drawn_cards):
    """Analyze elemental distribution in the spread."""
    elements = {"Fire": 0, "Water": 0, "Air": 0, "Earth": 0}
    for d in drawn_cards:
        elem = d["card"].get("element", "")
        if elem in elements:
            elements[elem] += 1

    total = sum(elements.values())
    dominant = max(elements, key=elements.get) if total > 0 else "None"
    lacking = [k for k, v in elements.items() if v == 0]

    return {
        "distribution": elements,
        "dominant": dominant,
        "lacking": lacking,
        "interpretation": {
            "Fire": "Action, passion, and will are strongly emphasized",
            "Water": "Emotions, intuition, and relationships dominate",
            "Air": "Intellectual concerns and communication are central",
            "Earth": "Practical, material, and physical matters are foregrounded",
        }.get(dominant, "Mixed elemental energy"),
    }


def analyze_numerology(drawn_cards):
    """Analyze numerological patterns in the spread."""
    numbers = [d["card"].get("numerology", 0) for d in drawn_cards]
    from collections import Counter
    freq = Counter(numbers)
    repeated = {k: v for k, v in freq.items() if v > 1}

    # Sum and reduce
    total = sum(numbers)
    while total > 9 and total != 11 and total != 22:
        total = sum(int(d) for d in str(total))

    return {
        "card_numbers": numbers,
        "repeated_numbers": repeated,
        "sum_reduced": total,
        "sum_meaning": {
            1: "Independence, new beginnings, leadership",
            2: "Partnership, balance, diplomacy",
            3: "Creativity, expression, growth",
            4: "Stability, structure, hard work",
            5: "Change, freedom, adventure",
            6: "Harmony, responsibility, love",
            7: "Spirituality, analysis, inner wisdom",
            8: "Power, abundance, achievement",
            9: "Completion, wisdom, humanitarian",
            11: "Master number: spiritual insight, illumination",
            22: "Master number: master builder, large-scale vision",
        }.get(total, "Complex numerological energy"),
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Tarot Reading Engine")
    parser.add_argument("--spread", default="3-card",
                        help="Spread type: 3-card, celtic-cross, relationship, career")
    parser.add_argument("--question", default="", help="The querent's question")
    parser.add_argument("--seed", type=int, default=None, help="Random seed for reproducibility")
    parser.add_argument("--name", default="Querent", help="Name of the querent")

    args = parser.parse_args()

    drawn_cards, spread = draw_cards(args.spread, args.seed, args.question)
    combos = find_card_combos(drawn_cards)
    elements = analyze_elements(drawn_cards)
    numerology = analyze_numerology(drawn_cards)

    # Count major vs minor
    major_count = sum(1 for d in drawn_cards if d["card"]["type"] == "major")
    minor_count = len(drawn_cards) - major_count

    # Upright vs reversed ratio
    reversed_count = sum(1 for d in drawn_cards if d["reversed"])
    upright_count = len(drawn_cards) - reversed_count

    # Overall energy
    if reversed_count > upright_count:
        overall_energy = "Predominantly reversed — internal work, blocks, or shadow themes dominate"
    elif major_count > minor_count:
        overall_energy = "Major Arcana dominant — powerful archetypal forces at play, fated/karmic energy"
    else:
        overall_energy = "Minor Arcana dominant — practical, day-to-day matters, personal agency emphasized"

    result = {
        "system": "Tarot (Rider-Waite)",
        "querent": args.name,
        "question": args.question,
        "spread": {
            "type": args.spread,
            "name": spread["name"],
            "card_count": spread["card_count"],
        },
        "seed": args.seed,
        "timestamp": datetime.now().isoformat(),
        "cards": [],
        "card_combinations": combos,
        "elemental_analysis": elements,
        "numerological_analysis": numerology,
        "statistics": {
            "major_arcana_count": major_count,
            "minor_arcana_count": minor_count,
            "upright_count": upright_count,
            "reversed_count": reversed_count,
            "reversal_rate": round(reversed_count / len(drawn_cards) * 100, 1),
        },
        "overall_energy": overall_energy,
    }

    for d in drawn_cards:
        card_output = {
            "position_number": d["position"]["position"],
            "position_name": d["position"]["name"],
            "position_description": d["position"]["description"],
            "card_name": d["card"]["name"],
            "orientation": d["orientation"],
            "active_meaning": d["active_meaning"],
            "keywords": d["card"].get("keywords", []),
            "element": d["card"].get("element", ""),
            "archetype": d["card"].get("archetype", ""),
            "jungian_interpretation": d["card"].get("jungian", ""),
            "numerology": d["card"].get("numerology", 0),
        }
        if d["card"].get("suit"):
            card_output["suit"] = d["card"]["suit"]
        result["cards"].append(card_output)

    print(json.dumps(result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
