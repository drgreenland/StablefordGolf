#!/usr/bin/env python3
"""
StablefordGolf — Seed simulator UserDefaults for App Store screenshots.

Produces realistic data: 4 players, 1 course, 3 rounds (1 in-progress, 2 completed).

UDID and container path must be filled in before running:
  1. xcrun simctl list devices | grep "iPhone 17 Pro Max"  → fill UDID
  2. xcrun simctl launch UDID com.davidgreenland.StablefordGolf ; sleep 3
  3. xcrun simctl get_app_container UDID com.davidgreenland.StablefordGolf data  → fill CONTAINER
  4. xcrun simctl terminate UDID com.davidgreenland.StablefordGolf
  5. python3 seed_data.py
  6. xcrun simctl launch UDID com.davidgreenland.StablefordGolf ; sleep 4
"""

import binascii
import json
import plistlib
import subprocess
import uuid
from datetime import datetime, timezone
from pathlib import Path

# ── Configuration ──────────────────────────────────────────────────────────────
BUNDLE_ID = "com.davidgreenland.StablefordGolf"
UDID      = "44A312B1-4028-4C9E-90F7-4A8B67536F97"
CONTAINER = Path("/Users/m4/Library/Developer/CoreSimulator/Devices/44A312B1-4028-4C9E-90F7-4A8B67536F97/data/Containers/Data/Application/0489C14B-1E5D-4ACA-AEB4-8ED77B753D4A")

PLIST_PATH = CONTAINER / "Library/Preferences" / f"{BUNDLE_ID}.plist"

# ── Helpers ────────────────────────────────────────────────────────────────────
def uid() -> str:
    return str(uuid.uuid4()).upper()

def swift_date(dt: datetime) -> float:
    """Seconds since Swift reference date 2001-01-01 UTC (NOT Unix epoch)."""
    return (dt - datetime(2001, 1, 1, tzinfo=timezone.utc)).total_seconds()

def stableford_points(strokes: int, par: int, hcp_strokes: int) -> int:
    """Stableford points: max(0, 2 - (net - par)). strokes=0 means pick-up."""
    if strokes == 0:
        return 0
    return max(0, 2 - ((strokes - hcp_strokes) - par))

def hcp_strokes_for_hole(player_hcp: float, opponent_hcp: float, hole_si: int) -> int:
    """Handicap strokes allocated on a hole (same 3-pass algorithm as StablefordGolf.Round)."""
    diff = int(round(player_hcp - opponent_hcp))
    if diff <= 0:
        return 0
    s = 0
    if hole_si <= min(diff, 18):       s += 1
    if diff > 18 and hole_si <= min(diff - 18, 18): s += 1
    if diff > 36 and hole_si <= (diff - 36):        s += 1
    return s

# ── Player IDs ────────────────────────────────────────────────────────────────
P1 = uid()  # Dave Green   hdcp 14
P2 = uid()  # Tom Walsh    hdcp 8
P3 = uid()  # Sam Murphy   hdcp 22
P4 = uid()  # Mike Evans   hdcp 5

players = [
    {"id": P1, "name": "Dave Green",  "handicap": 14.0},
    {"id": P2, "name": "Tom Walsh",   "handicap": 8.0},
    {"id": P3, "name": "Sam Murphy",  "handicap": 22.0},
    {"id": P4, "name": "Mike Evans",  "handicap": 5.0},
]

# ── Course: Bali National Golf Club ──────────────────────────────────────────
# TeeColor: StablefordGolf model has courseRating + slopeRating (not in MatchPlayGolf)
COURSE_ID = uid()
TEE_ID    = uid()

tee_blue = {"id": TEE_ID, "name": "Blue", "courseRating": 72.0, "slopeRating": 113}

# (number, par, strokeIndex, distance_m)
HOLE_SPECS = [
    (1,  4,  3, 380), (2,  3, 17, 155), (3,  4,  9, 360), (4,  5,  7, 510),
    (5,  4,  1, 395), (6,  3, 15, 170), (7,  4, 11, 375), (8,  5,  5, 520),
    (9,  4, 13, 345), (10, 4,  6, 390), (11, 3, 16, 160), (12, 4,  8, 365),
    (13, 5,  4, 505), (14, 4, 10, 355), (15, 4,  2, 400), (16, 3, 18, 145),
    (17, 4, 12, 380), (18, 5, 14, 525),
]

# StablefordGolf TeeDistance = {"teeId": UUID, "distance": Int}
# NOT an embedded tee object (differs from MatchPlayGolf)
holes = [
    {
        "id": uid(),
        "number": num,
        "par": par,
        "strokeIndex": si,
        "teeDistances": [{"teeId": TEE_ID, "distance": dist}],
    }
    for num, par, si, dist in HOLE_SPECS
]

course = {
    "id": COURSE_ID,
    "name": "Bali National Golf Club",
    "holes": holes,
    "availableTees": [tee_blue],
}

# Build lookup for scoring
si_by_hole = {num: si for num, _, si, _ in HOLE_SPECS}
par_by_hole = {num: par for num, par, _, _ in HOLE_SPECS}

# ── Round helpers ──────────────────────────────────────────────────────────────
def make_hole_points(hole_num: int, player_strokes: dict[str, int], player_hcps: dict[str, float], opponent_hcps: dict[str, float]) -> dict:
    """
    player_strokes: {player_id: strokes} — 0 = pick up
    player_hcps: {player_id: handicap}
    opponent_hcps: {player_id: lowest opponent handicap for that player}
    """
    si  = si_by_hole[hole_num]
    par = par_by_hole[hole_num]
    pts = {}
    raw = {}
    for pid, strokes in player_strokes.items():
        hcp_s = hcp_strokes_for_hole(player_hcps[pid], opponent_hcps[pid], si)
        pts[pid] = stableford_points(strokes, par, hcp_s)
        raw[pid] = strokes
    return {
        "id": uid(),
        "holeNumber": hole_num,
        "playerPoints":  pts,   # [String: Int] — UUID string keys, no encoding bug
        "playerStrokes": raw,   # [String: Int]
    }

# ── Round 1: In-progress singles — Dave (team 0) vs Tom (team 1), through H9 ─
# diff Dave-Tom = 14-8 = 6 → Dave gets strokes on SI 1-6
# SI 1=H5, 2=H15, 3=H1, 4=H13, 5=H8, 6=H10
R1_ID = uid()

r1_strokes = [
    (1,  {P1: 5, P2: 4}),   # H1 SI3: Dave hcp
    (2,  {P1: 4, P2: 3}),   # H2 SI17: no hcp
    (3,  {P1: 4, P2: 5}),   # H3 SI9:  no hcp
    (4,  {P1: 6, P2: 5}),   # H4 SI7:  no hcp
    (5,  {P1: 5, P2: 3}),   # H5 SI1:  Dave hcp; Tom birdies
    (6,  {P1: 3, P2: 4}),   # H6 SI15: no hcp; Dave birdies
    (7,  {P1: 5, P2: 4}),   # H7 SI11: no hcp
    (8,  {P1: 6, P2: 5}),   # H8 SI5:  Dave hcp
    (9,  {P1: 4, P2: 5}),   # H9 SI13: no hcp
]

r1_hps = {P1: 14.0, P2: 8.0}
r1_opp = {P1: 8.0, P2: 14.0}  # each player's lowest opponent handicap

r1_hole_points = [make_hole_points(h, s, r1_hps, r1_opp) for h, s in r1_strokes]

# Verify totals
r1_dave = sum(hp["playerPoints"][P1] for hp in r1_hole_points)
r1_tom  = sum(hp["playerPoints"][P2] for hp in r1_hole_points)
print(f"Round 1 after H9: Dave {r1_dave} pts, Tom {r1_tom} pts")

round1 = {
    "id": R1_ID,
    "date": swift_date(datetime(2026, 9, 4, 8, 0, tzinfo=timezone.utc)),
    "course": course,
    "tee": tee_blue,
    "players": [P1, P2],
    "teams": [0, 1],
    "isTeamPlay": False,
    "currentHole": 10,
    "status": "inProgress",
    "holePoints": r1_hole_points,
    "playerDisplayNames": ["Dave Green", "Tom Walsh"],
}

# ── Round 2: Completed singles — Tom (team 0) vs Mike (team 1), 18 holes ─────
# diff Tom-Mike = 8-5 = 3 → Tom strokes on SI 1,2,3 = H5,H15,H1
R2_ID = uid()

r2_strokes = [
    (1,  {P2: 4, P4: 4}),   # H1 SI3: Tom hcp → Tom net 3 (birdie=3pts), Mike par=2
    (2,  {P2: 3, P4: 2}),   # H2 SI17: Tom par=2, Mike birdie=3
    (3,  {P2: 5, P4: 4}),   # H3 SI9: Tom bogey=1, Mike par=2
    (4,  {P2: 5, P4: 5}),   # H4 SI7: both par=2
    (5,  {P2: 4, P4: 3}),   # H5 SI1: Tom hcp→net3 birdie=3, Mike birdie=3
    (6,  {P2: 4, P4: 3}),   # H6 SI15: Tom bogey=1, Mike par=2... par 3 so Mike birdies
    (7,  {P2: 4, P4: 5}),   # H7 SI11: Tom par=2, Mike bogey=1
    (8,  {P2: 5, P4: 6}),   # H8 SI5: Tom par=2, Mike bogey=1
    (9,  {P2: 4, P4: 4}),   # H9 SI13: both par=2
    (10, {P2: 4, P4: 3}),   # H10 SI6: Tom par=2, Mike birdie=3
    (11, {P2: 3, P4: 3}),   # H11 SI16: both par=2
    (12, {P2: 4, P4: 5}),   # H12 SI8: Tom par=2, Mike bogey=1
    (13, {P2: 5, P4: 5}),   # H13 SI4: both par=2
    (14, {P2: 5, P4: 4}),   # H14 SI10: Tom bogey=1, Mike par=2
    (15, {P2: 5, P4: 4}),   # H15 SI2: Tom hcp→net4 par=2, Mike par=2
    (16, {P2: 2, P4: 4}),   # H16 SI18: Tom birdie=3, Mike bogey=1 (par 3)
    (17, {P2: 4, P4: 4}),   # H17 SI12: both par=2
    (18, {P2: 5, P4: 5}),   # H18 SI14: both par=2
]

r2_hps = {P2: 8.0, P4: 5.0}
r2_opp = {P2: 5.0, P4: 8.0}

r2_hole_points = [make_hole_points(h, s, r2_hps, r2_opp) for h, s in r2_strokes]

r2_tom  = sum(hp["playerPoints"][P2] for hp in r2_hole_points)
r2_mike = sum(hp["playerPoints"][P4] for hp in r2_hole_points)
print(f"Round 2 (18 holes): Tom {r2_tom} pts, Mike {r2_mike} pts")

round2 = {
    "id": R2_ID,
    "date": swift_date(datetime(2026, 9, 1, 14, 30, tzinfo=timezone.utc)),
    "course": course,
    "tee": tee_blue,
    "players": [P2, P4],
    "teams": [0, 1],
    "isTeamPlay": False,
    "currentHole": 18,
    "status": "completed",
    "holePoints": r2_hole_points,
    "playerDisplayNames": ["Tom Walsh", "Mike Evans"],
}

# ── Round 3: Completed team — Dave+Sam (team 0) vs Tom+Mike (team 1), 18 holes ─
# players=[P1,P2,P3,P4], teams=[0,1,0,1]
# team 0: Dave(14), Sam(22); team 1: Tom(8), Mike(5)
# Better ball = max(player points on team per hole)
R3_ID = uid()

# For each player, lowest opponent handicap:
# Dave team0: opponents Tom(8),Mike(5) → lowest = 5 → diff = 14-5 = 9
# Sam team0: opponents Tom(8),Mike(5) → lowest = 5 → diff = 22-5 = 17
# Tom team1: opponents Dave(14),Sam(22) → lowest = 14 → diff = 8-14 = -6 (no strokes)
# Mike team1: opponents Dave(14),Sam(22) → lowest = 14 → diff = 5-14 = -9 (no strokes)
r3_hps = {P1: 14.0, P2: 8.0, P3: 22.0, P4: 5.0}
r3_opp = {P1: 5.0, P2: 14.0, P3: 5.0, P4: 14.0}

r3_strokes = [
    (1,  {P1: 5, P2: 4, P3: 7, P4: 4}),
    (2,  {P1: 4, P2: 5, P3: 6, P4: 5}),
    (3,  {P1: 4, P2: 5, P3: 7, P4: 4}),
    (4,  {P1: 5, P2: 5, P3: 6, P4: 5}),
    (5,  {P1: 4, P2: 3, P3: 5, P4: 4}),   # Sam birdies (net-wise): Sam has 1 stroke on SI1; net=5-1=4=par
    (6,  {P1: 3, P2: 4, P3: 5, P4: 3}),
    (7,  {P1: 4, P2: 4, P3: 6, P4: 5}),
    (8,  {P1: 5, P2: 5, P3: 6, P4: 5}),
    (9,  {P1: 4, P2: 4, P3: 5, P4: 4}),
    (10, {P1: 4, P2: 4, P3: 6, P4: 3}),   # Mike birdies: net 3 = birdie = 3 pts
    (11, {P1: 3, P2: 3, P3: 4, P4: 3}),
    (12, {P1: 4, P2: 4, P3: 5, P4: 5}),
    (13, {P1: 5, P2: 5, P3: 6, P4: 5}),
    (14, {P1: 4, P2: 5, P3: 5, P4: 4}),
    (15, {P1: 4, P2: 4, P3: 5, P4: 4}),
    (16, {P1: 3, P2: 4, P3: 4, P4: 4}),
    (17, {P1: 4, P2: 4, P3: 6, P4: 4}),
    (18, {P1: 5, P2: 5, P3: 7, P4: 5}),
]

r3_hole_points = [make_hole_points(h, s, r3_hps, r3_opp) for h, s in r3_strokes]

# Better-ball team totals
def team_total(hole_points, team_ids):
    return sum(
        max((hp["playerPoints"].get(pid, 0) for pid in team_ids), default=0)
        for hp in hole_points
    )

t0_total = team_total(r3_hole_points, [P1, P3])
t1_total = team_total(r3_hole_points, [P2, P4])
print(f"Round 3 (team better ball): Team 1 (Dave+Sam) {t0_total} pts, Team 2 (Tom+Mike) {t1_total} pts")

round3 = {
    "id": R3_ID,
    "date": swift_date(datetime(2026, 8, 28, 10, 0, tzinfo=timezone.utc)),
    "course": course,
    "tee": tee_blue,
    "players": [P1, P2, P3, P4],
    "teams": [0, 1, 0, 1],
    "isTeamPlay": True,
    "currentHole": 18,
    "status": "completed",
    "holePoints": r3_hole_points,
    "playerDisplayNames": ["Dave Green", "Tom Walsh", "Sam Murphy", "Mike Evans"],
}

rounds = [round1, round2, round3]

# ── Write + flush ─────────────────────────────────────────────────────────────
players_json = json.dumps(players,  separators=(",", ":")).encode()
courses_json = json.dumps([course], separators=(",", ":")).encode()
rounds_json  = json.dumps(rounds,   separators=(",", ":")).encode()

plist_data = {
    "sg_players": players_json,
    "sg_courses": courses_json,
    "sg_rounds":  rounds_json,
}

PLIST_PATH.parent.mkdir(parents=True, exist_ok=True)
with open(PLIST_PATH, "wb") as f:
    plistlib.dump(plist_data, f, fmt=plistlib.FMT_BINARY)
print(f"\nPlist written: {PLIST_PATH}")

# Flush via simctl spawn — direct plist write alone is unreliable (cfprefsd caches)
for key, data in [("sg_players", players_json), ("sg_courses", courses_json), ("sg_rounds", rounds_json)]:
    hex_str = binascii.hexlify(data).decode()
    result = subprocess.run(
        ["xcrun", "simctl", "spawn", UDID, "defaults", "write", BUNDLE_ID, key, "-data", hex_str],
        capture_output=True, text=True,
    )
    if result.returncode != 0:
        print(f"WARNING: defaults write failed for {key}: {result.stderr.strip()}")
    else:
        print(f"Flushed: {key}")

print(f"\nSeeded: {len(players)} players, 1 course, {len(rounds)} rounds")
print("Now run: xcrun simctl launch", UDID, BUNDLE_ID, "&& sleep 4")
