#!/usr/bin/env python3
"""Post a single Mirra social post to IG by index (0-41)."""
import os, sys, json, time, fal_client
import urllib.request, urllib.parse
from pathlib import Path

os.environ["FAL_KEY"] = "[REDACTED — see .env]"

PAGE_TOKEN = "[REDACTED — see .env]"
IG_USER_ID = "17841467066982906"
FB_PAGE_ID = "318283048041590"
OUT = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/06_exports/social/42-posts")
LOG = Path("/Users/yi-vonnehooi/Desktop/_WORK/mirra/06_exports/social/42-posts/.post-log.json")

CAPTIONS = {
    0: "the feminine urge hits different on mondays.\n\n#mirra #girllife #feminineenergy #mondaymood",
    1: "good thanks. definitely good thanks.\n\n#mirra #relatable #mondayenergy",
    2: "i will not stress about things i cannot control. everything will unfold in its timing.\n\n#mirra #selfcare #letgo #timing #peace",
    3: "two very different energy levels. same girl.\n\n#mirra #textingmemes #bestie #corporate",
    4: "the only truth we all agree on.\n\n#mirra #weekendvibes #saturdayonly #relatable",
    5: "same tbh.\n\n#mirra #partyanimal #sleepytime #introvert",
    6: "the vision and the execution are both valid.\n\n#mirra #delulu #solulu #girllife",
    7: "me carrying everything at once and pretending it's fine.\n\n#mirra #juggling #adultlife #labeled #relatable",
    8: "for the girl who needed this today.\n\n#mirra #rightpeople #selflove #reminder",
    9: "the three personalities of every corporate girl.\n\n#mirra #corporategirl #lunchbreak #officehumor",
    10: "priorities.\n\n#mirra #empirebuilding #naptime #girlboss",
    11: "she is all of this. and she is you.\n\n#mirra #affirmation #sheiseverything",
    12: "there's nothing to compete with.\n\n#mirra #confidence #unbothered #energy",
    13: "write this to yourself and mean it.\n\n#mirra #futureself #growth #letterstomyself",
    14: "the only 2026 plan that matters.\n\n#mirra #2026energy #manifest #peace",
    15: "be your own hype girl.\n\n#mirra #selflove #mirrormoment #peptalk",
    16: "comfort is universal. save this.\n\n#mirra #comfortfood #worldfood #plantbased",
    17: "your sign to just start.\n\n#mirra #motivation #startnow",
    18: "lunch is ready. you coming?\n\n#mirra #ratemylunch #plantbased #bentobox #lunchtime",
    19: "treating myself is an investment okay.\n\n#mirra #treatyourself #bankaccount #girlmath",
    20: "my toxic trait is saying to myself 'it's only $20' 1700 times a week.\n\n#mirra #toxictrait #girlmath #relatable",
    21: "close some tabs bestie.\n\n#mirra #toomanytabs #overwhelm #relatable",
    22: "more of this energy.\n\n#mirra #morefries #lessbs #attitude",
    23: "that's the whole mood.\n\n#mirra #unbothered #moisturized #flourishing",
    24: "tomorrow is also a day.\n\n#mirra #motivation #cantgetup #relatable",
    25: "this is how i eat. every single day.\n\n#mirra #plantbased #bentobox #mealprep #eatingwell",
    26: "you're telling me these are the same calories.\n\n#mirra #volumeeating #eatmore #caloriecomparison #plantbased",
    27: "the gap between expectations and reality is just a messy bun and a hoodie.\n\n#mirra #expectationsvsreality #hotgirlwalk #morningreality",
    28: "every morning. every single morning.\n\n#mirra #morningroutine #labeled #relatable",
    29: "仪式感。\n\n#mirra #仪式感 #自爱 #吃得好",
    30: "the thrill is free.\n\n#mirra #onlineshopping #addtocart #toxictrait",
    31: "save this for when you need it.\n\n#mirra #reminder #rest #selflove",
    32: "她吃饱了就走。\n\n#mirra #独立女性 #不解释 #自信",
    33: "hot girls don't stand in the kitchen wondering what to cook.\n\n#mirra #hotgirlsorderin #plantbased #bentobox",
    34: "my love language is someone else cooking for me. that's it. that's the whole thing.\n\n#mirra #lovelanguage #foodismylove #cooking",
    35: "2026年愿望清单：别人煮饭给我吃。\n\n#mirra #愿望清单 #2026 #manifest",
    36: "100% natural. nothing processed. now you know.\n\n#mirra #whatsinside #plantbased #natural #konjac",
    37: "every single meal. while still chewing.\n\n#mirra #catmeme #thinkingaboutfood #relatable",
    38: "two moods. no in between.\n\n#mirra #twomoods #constantpanic #itiswhatitis",
    39: "no words needed. you know.\n\n#mirra #morningroutine #silentcomic #maincharacter",
    40: "当老板说我们是一家人。\n\n#mirra #职场 #corporatehumor #toxicjob",
    41: "plot twist.\n\n#mirra #plottwist #selflove #loveyourself",
    42: "this is what's inside. bbq mushroom pita wraps, chickpea salad, fresh fruit. 100% natural.\n\n#mirra #whatsinside #plantbased #bento #lunchbox #natural",
    43: "zero carb konjac noodles + classic curry with chickpeas. this is what eating well actually looks like.\n\n#mirra #whatsinside #plantbased #konjac #zerocarb #bento",
    44: "golden eryngii mushroom + fragrant turmeric rice. every compartment earned its spot.\n\n#mirra #whatsinside #plantbased #bento #turmericrice #mushroom",
    45: "lemon mushroom + cauliflower beetroot rice + beancurd. colors you can taste.\n\n#mirra #whatsinside #plantbased #bento #beetrootrice #natural",
    46: "teriyaki mushroom burrito bowl. quinoa rice, chickpea salsa, broccoli, black beans. the whole thing.\n\n#mirra #whatsinside #plantbased #burritobowl #teriyaki #bento",
}

def post_ig(index):
    files = sorted(OUT.glob("*.png"))
    if index >= len(files):
        print(f"ERROR: index {index} out of range ({len(files)} files)")
        return False

    f = files[index]
    caption = CAPTIONS.get(index)
    if not caption:
        print(f"ERROR: No caption found for index {index} ({f.name}). Add caption to CAPTIONS dict before posting.")
        return False

    print(f"[{index:02d}] Posting: {f.name}")

    # Upload
    url = fal_client.upload_file(str(f))
    print(f"  Uploaded: {url[:50]}...")

    # Create container
    params = urllib.parse.urlencode({
        "image_url": url,
        "caption": caption,
        "access_token": PAGE_TOKEN,
    }).encode()
    req = urllib.request.Request(
        f"https://graph.facebook.com/v21.0/{IG_USER_ID}/media",
        data=params, method="POST"
    )
    resp = json.loads(urllib.request.urlopen(req, timeout=30).read())
    container_id = resp.get("id")
    if not container_id:
        print(f"  FAILED: {resp}")
        return False
    print(f"  Container: {container_id}")

    time.sleep(5)

    # Publish
    pub_params = urllib.parse.urlencode({
        "creation_id": container_id,
        "access_token": PAGE_TOKEN,
    }).encode()
    pub_req = urllib.request.Request(
        f"https://graph.facebook.com/v21.0/{IG_USER_ID}/media_publish",
        data=pub_params, method="POST"
    )
    pub_resp = json.loads(urllib.request.urlopen(pub_req, timeout=30).read())
    media_id = pub_resp.get("id")
    if not media_id:
        print(f"  PUBLISH FAILED: {pub_resp}")
        return False

    print(f"  IG POSTED: {media_id}")

    # Post to FB
    fb_id = None
    try:
        fb_params = urllib.parse.urlencode({
            "url": url,
            "message": caption,
            "access_token": PAGE_TOKEN,
        }).encode()
        fb_req = urllib.request.Request(
            f"https://graph.facebook.com/v21.0/{FB_PAGE_ID}/photos",
            data=fb_params, method="POST"
        )
        fb_resp = json.loads(urllib.request.urlopen(fb_req, timeout=30).read())
        fb_id = fb_resp.get("id") or fb_resp.get("post_id")
        if fb_id:
            print(f"  FB POSTED: {fb_id}")
        else:
            print(f"  FB FAILED: {fb_resp}")
    except Exception as e:
        print(f"  FB ERROR: {e}")

    # Log
    log_data = []
    if LOG.exists():
        log_data = json.loads(LOG.read_text())
    log_data.append({
        "index": index,
        "file": f.name,
        "ig_id": media_id,
        "fb_id": fb_id,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
    })
    LOG.write_text(json.dumps(log_data, indent=2))
    return True

def post_file(filepath, caption, index):
    """Post any file with any caption — for batch 2+ posts."""
    f = Path(filepath)
    if not f.exists():
        print(f"ERROR: File not found: {f}")
        return False

    print(f"[{index}] Posting: {f.name}")

    url = fal_client.upload_file(str(f))
    print(f"  Uploaded: {url[:50]}...")

    params = urllib.parse.urlencode({
        "image_url": url,
        "caption": caption,
        "access_token": PAGE_TOKEN,
    }).encode()
    req = urllib.request.Request(
        f"https://graph.facebook.com/v21.0/{IG_USER_ID}/media",
        data=params, method="POST"
    )
    resp = json.loads(urllib.request.urlopen(req, timeout=30).read())
    container_id = resp.get("id")
    if not container_id:
        print(f"  FAILED: {resp}")
        return False
    print(f"  Container: {container_id}")

    time.sleep(5)

    pub_params = urllib.parse.urlencode({
        "creation_id": container_id,
        "access_token": PAGE_TOKEN,
    }).encode()
    pub_req = urllib.request.Request(
        f"https://graph.facebook.com/v21.0/{IG_USER_ID}/media_publish",
        data=pub_params, method="POST"
    )
    pub_resp = json.loads(urllib.request.urlopen(pub_req, timeout=30).read())
    media_id = pub_resp.get("id")
    if not media_id:
        print(f"  PUBLISH FAILED: {pub_resp}")
        return False
    print(f"  IG POSTED: {media_id}")

    fb_id = None
    try:
        fb_params = urllib.parse.urlencode({
            "url": url,
            "message": caption,
            "access_token": PAGE_TOKEN,
        }).encode()
        fb_req = urllib.request.Request(
            f"https://graph.facebook.com/v21.0/{FB_PAGE_ID}/photos",
            data=fb_params, method="POST"
        )
        fb_resp = json.loads(urllib.request.urlopen(fb_req, timeout=30).read())
        fb_id = fb_resp.get("id") or fb_resp.get("post_id")
        if fb_id:
            print(f"  FB POSTED: {fb_id}")
    except Exception as e:
        print(f"  FB ERROR: {e}")

    log_data = []
    if LOG.exists():
        log_data = json.loads(LOG.read_text())
    log_data.append({
        "index": index,
        "file": f.name,
        "ig_id": media_id,
        "fb_id": fb_id,
        "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
    })
    LOG.write_text(json.dumps(log_data, indent=2))
    return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 post_single.py <index>")
        print("       python3 post_single.py <index> --file <path> --caption <text>")
        sys.exit(1)

    idx = int(sys.argv[1])

    if "--file" in sys.argv:
        file_idx = sys.argv.index("--file") + 1
        caption_idx = sys.argv.index("--caption") + 1
        filepath = sys.argv[file_idx]
        caption = sys.argv[caption_idx]
        ok = post_file(filepath, caption, idx)
    else:
        ok = post_ig(idx)

    sys.exit(0 if ok else 1)
