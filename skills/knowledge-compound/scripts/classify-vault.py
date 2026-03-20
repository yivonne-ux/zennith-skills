#!/usr/bin/env python3
"""
classify-vault.py — Classify existing vault.db rows into L0/L1/L2 memory tiers.

Sets namespace, path, and l0_abstract for all rows based on source_type rules.
"""

import sqlite3
import os
import sys

DB = os.path.expanduser("~/.openclaw/workspace/vault/vault.db")

def classify_row(row):
    """Returns (namespace, path) for a vault row."""
    rid, source_type, source_ref, brand, category, agent, entry_type, text = row

    source_type = source_type or ""
    brand = brand or ""
    agent = agent or ""
    entry_type = entry_type or ""
    category = category or ""

    # Rule 1: memory/shared-facts with agent → agent namespace
    if source_type in ("memory", "shared-facts") and agent:
        safe_agent = agent.split(",")[0].strip()  # take first agent if comma-separated
        et = entry_type if entry_type else "general"
        return ("agent", "agent/{}/memory/{}".format(safe_agent, et))

    # Rule 2: brand-dna → resources/brands
    if source_type == "brand-dna":
        b = brand if brand else "unknown"
        return ("resources", "resources/brands/{}".format(b))

    # Rule 3: seeds/image-seeds → resources/seeds
    if source_type in ("seeds", "image-seeds"):
        b = brand if brand else "general"
        return ("resources", "resources/seeds/{}".format(b))

    # Rule 4: patterns → agent/system/patterns
    if source_type in ("patterns", "pattern"):
        cat = category if category else "general"
        return ("agent", "agent/system/patterns/{}".format(cat))

    # Rule 5: room-exec/room-feedback → agent/system/rooms
    if source_type in ("room-exec", "room-feedback"):
        return ("agent", "agent/system/rooms/{}".format(source_type))

    # Rule 6: knowledge → agent/system/knowledge
    if source_type == "knowledge":
        return ("agent", "agent/system/knowledge")

    # Rule 7: biz-opportunity → resources/biz-opportunities
    if source_type == "biz-opportunity":
        return ("resources", "resources/biz-opportunities")

    # Rule 8: youtube → resources/youtube
    if source_type == "youtube":
        return ("resources", "resources/youtube")

    # Default
    return ("resources", "resources/{}".format(source_type if source_type else "other"))


def make_l0(text):
    """Create L0 abstract: first sentence or first 200 chars, whichever is shorter."""
    if not text:
        return ""
    # Take first sentence
    for sep in [". ", ".\n", "\n"]:
        idx = text.find(sep)
        if idx > 0 and idx < 300:
            return text[:idx + 1].strip()
    # Fallback: first 200 chars
    if len(text) > 200:
        return text[:197].strip() + "..."
    return text.strip()


def main():
    conn = sqlite3.connect(DB)
    cur = conn.cursor()

    # Fetch all rows
    cur.execute("""
        SELECT id, source_type, source_ref, brand, category, agent, entry_type, text
        FROM vault
    """)
    rows = cur.fetchall()
    print("Classifying {} rows...".format(len(rows)))

    # Batch update
    updates = []
    for row in rows:
        rid = row[0]
        text = row[7] or ""
        ns, path = classify_row(row)
        l0 = make_l0(text)
        updates.append((ns, path, l0, rid))

    cur.executemany("""
        UPDATE vault SET namespace=?, path=?, l0_abstract=? WHERE id=?
    """, updates)

    conn.commit()

    # Stats
    cur.execute("SELECT namespace, COUNT(*) FROM vault GROUP BY namespace ORDER BY COUNT(*) DESC")
    print("\nNamespace distribution:")
    for ns, count in cur.fetchall():
        print("  {}: {}".format(ns, count))

    cur.execute("SELECT substr(path, 1, instr(path||'/', '/')-1) as top, COUNT(*) FROM vault GROUP BY top ORDER BY COUNT(*) DESC")
    print("\nTop-level path distribution:")
    for top, count in cur.fetchall():
        print("  {}: {}".format(top, count))

    # Verify count
    cur.execute("SELECT COUNT(*) FROM vault")
    final = cur.fetchone()[0]
    print("\nFinal row count: {} (expected 2840)".format(final))
    if final != 2840:
        print("WARNING: Row count mismatch!")

    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
