"""
ParcelPark | Portfolio 4: generates the MongoDB dataset as JSON files.
Produces data/parks.json, data/routes.json, data/parcels.json
(MongoDB Extended JSON, ready for MongoDB Compass "Import JSON").
Run:  python generate_data.py
"""
import json, random
from datetime import datetime, timedelta, timezone

random.seed(8103)

# ---------- parks: same 20 parks as the PostgreSQL database -------------
# location = GeoJSON Point [longitude, latitude] (approximate)
PARKS = [
    (1,  "Jibowu Motor Park",       "Lagos",         "Lagos",       3.3792, 6.5156),
    (2,  "Mile 1 Motor Park",       "Port Harcourt", "Rivers",      7.0134, 4.7900),
    (3,  "Utako Motor Park",        "Abuja",         "FCT",         7.4398, 9.0640),
    (4,  "Ring Road Park",          "Benin City",    "Edo",         5.6145, 6.3350),
    (5,  "Upper Iweka Park",        "Onitsha",       "Anambra",     6.7850, 6.1450),
    (6,  "Ojota New Garage",        "Lagos",         "Lagos",       3.3830, 6.5833),
    (7,  "Iyana Ipaja Park",        "Lagos",         "Lagos",       3.2667, 6.6100),
    (8,  "Waterlines Park",         "Port Harcourt", "Rivers",      7.0217, 4.8122),
    (9,  "Jabi Motor Park",         "Abuja",         "FCT",         7.4235, 9.0700),
    (10, "Iwo Road Park",           "Ibadan",        "Oyo",         3.9470, 7.4040),
    (11, "Holy Ghost Park",         "Enugu",         "Enugu",       7.4950, 6.4400),
    (12, "Owerri Main Park",        "Owerri",        "Imo",         7.0352, 5.4836),
    (13, "Ariaria Park",            "Aba",           "Abia",        7.3600, 5.1150),
    (14, "Kano Line",               "Kano",          "Kano",        8.5200, 12.0000),
    (15, "Kawo Motor Park",         "Kaduna",        "Kaduna",      7.4500, 10.5600),
    (16, "Uyo Main Park",           "Uyo",           "Akwa Ibom",   7.9300, 5.0400),
    (17, "Calabar Highway Park",    "Calabar",       "Cross River", 8.3300, 4.9500),
    (18, "Warri Main Park",         "Warri",         "Delta",       5.7500, 5.5200),
    (19, "Asaba Park",              "Asaba",         "Delta",       6.7300, 6.2000),
    (20, "Ilorin Post Office Park", "Ilorin",        "Kwara",       4.5500, 8.4900),
]
parks = [{"_id": pid, "name": n, "city": c, "state": s,
          "location": {"type": "Point", "coordinates": [lng, lat]}}
         for pid, n, c, s, lng, lat in PARKS]
park = {p["_id"]: p for p in parks}

# ---------- road network between parks (for the graph query) -----------
ROADS = [(1, 6, 10), (1, 7, 15), (6, 10, 125), (7, 10, 120), (1, 4, 320),
         (10, 20, 160), (20, 3, 500), (3, 9, 8), (3, 15, 190), (15, 14, 230),
         (4, 18, 100), (4, 19, 135), (19, 5, 10), (5, 11, 105), (5, 12, 110),
         (11, 3, 470), (12, 13, 65), (13, 2, 65), (2, 8, 5), (2, 16, 120),
         (16, 17, 75)]
routes = []
for a, b, km in ROADS:              # roads work both ways: store both directions
    for x, y in ((a, b), (b, a)):
        routes.append({"from": park[x]["name"], "to": park[y]["name"],
                       "distance_km": km, "est_hours": round(km / 60, 1)})

COMPANIES = [(i, n) for i, n in enumerate(
    ["Swift Lines Ltd", "Delta Express Co", "Eastern Movers"] +
    [f"Carrier {i:02d} Transport Ltd" for i in range(4, 21)], start=1)]

# ---------- parcels: ONE document holds everything about a parcel -------
def item_for(kind):
    """Different kinds of parcel carry different attributes (flexible schema)."""
    base = {"description": kind,
            "weight_kg": round(random.uniform(0.5, 40), 2),
            "declared_value": random.randint(5, 300) * 1000}
    if kind in ("Laptop", "Phone"):
        base.update(fragile=True, serial_no=f"SN{random.randint(10**7, 10**8 - 1)}",
                    insured=random.random() < 0.5)
    elif kind == "Food items":
        base.update(perishable=True,
                    best_before=(datetime(2026, 12, 31) - timedelta(days=random.randint(0, 200))).strftime("%Y-%m-%d"))
    elif kind == "Drugs":
        base.update(requires_cold_chain=random.random() < 0.6,
                    nafdac_no=f"A4-{random.randint(1000, 9999)}")
    elif kind == "Clothes":
        base.update(pieces=random.randint(1, 12))
    elif kind == "Spare parts":
        base.update(vehicle_model=random.choice(["Toyota Corolla", "Honda Accord", "Lexus RX", "Peugeot 406"]))
    return base

CHAIN = {
    "registered": ["registered"],
    "paid":       ["registered", "paid"],
    "in_transit": ["registered", "paid", "loaded", "in_transit"],
    "arrived":    ["registered", "paid", "loaded", "in_transit", "arrived"],
    "collected":  ["registered", "paid", "loaded", "in_transit", "arrived", "collected"],
    "cancelled":  ["registered", "cancelled"],
}
def status_pick():
    r = random.random()
    return ("collected" if r < .70 else "in_transit" if r < .80 else "arrived" if r < .88
            else "paid" if r < .94 else "registered" if r < .97 else "cancelled")

def d(dt):  # Extended JSON date
    return {"$date": dt.strftime("%Y-%m-%dT%H:%M:%S.000Z")}

KINDS = ["Documents", "Clothes", "Food items", "Phone", "Laptop", "Spare parts", "Cosmetics", "Drugs"]
parcels = []
start = datetime(2026, 1, 1, tzinfo=timezone.utc)
for i in range(1, 5001):
    o = random.randint(1, 20)
    dst = random.choice([p for p in range(1, 21) if p != o])
    comp_id, comp = random.choice(COMPANIES)
    status = status_pick()
    created = start + timedelta(minutes=random.randint(0, 315 * 24 * 60))
    fee = random.choice([2500, 3500, 5000, 6000, 8000])
    cust = random.randint(1, 1500)          # repeat customers
    tracking = []
    for step, st in enumerate(CHAIN[status]):
        p = None if st == "in_transit" else (park[o] if step < 3 else park[dst])
        ev = {"status": st, "at": d(created + timedelta(hours=4 * step))}
        if p:
            ev["park"] = p["name"]
        tracking.append(ev)
    payments = []
    if status not in ("registered", "cancelled"):
        if random.random() < 0.05:
            payments.append({"amount": fee, "method": "card", "status": "failed",
                             "at": d(created + timedelta(minutes=2))})
        payments.append({"amount": fee, "method": random.choice(["cash", "transfer", "card", "ussd"]),
                         "status": "successful", "at": d(created + timedelta(minutes=5))})
    parcels.append({
        "tracking_code": f"PP26{i:06d}",
        "status": status,
        "created_at": d(created),
        "company": {"company_id": comp_id, "name": comp},
        "sender": {"customer_id": cust, "name": f"Customer {cust}", "phone": f"070{cust:08d}"},
        "receiver": {"name": f"Receiver {i}", "phone": f"071{i:08d}"},
        "origin": {"park_id": o, "name": park[o]["name"], "city": park[o]["city"]},
        "destination": {"park_id": dst, "name": park[dst]["name"], "city": park[dst]["city"]},
        "item": item_for(random.choice(KINDS)),
        "fee": fee,
        "payments": payments,
        "tracking": tracking,
    })

for name, docs in (("parks", parks), ("routes", routes), ("parcels", parcels)):
    with open(f"data/{name}.json", "w") as f:
        json.dump(docs, f, indent=1 if name != "parcels" else None)
    print(f"data/{name}.json: {len(docs)} documents")
