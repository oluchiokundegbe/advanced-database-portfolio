# Portfolio 4 — NoSQL and Advanced Data Models

**Case study:** ParcelPark | **DBMS:** MongoDB 8.0 on **MongoDB Atlas** (free M0 cluster) | **Tool:** MongoDB Compass + its built-in `mongosh` shell
**NoSQL model type:** Document store, plus a geospatial index and a graph traversal

## Aim
To remodel ParcelPark for a document database, implement it, and judge where the document model suits ParcelPark better or worse than the relational design from Portfolios 1–3.

## Files

| File | Purpose |
|---|---|
| `generate_data.py` | Generates the dataset as MongoDB Extended JSON (repeatable: fixed random seed) |
| `data/parks.json` | 20 parks with GeoJSON locations |
| `data/routes.json` | 42 road links between parks (the edges of a graph) |
| `data/parcels.json` | 5,000 parcel documents |
| `queries.js` | Queries N1–N8, pasted one block at a time into `mongosh` |
| `screenshots/` | Evidence |

**How it was run:**
1. Create a free M0 cluster on MongoDB Atlas.
2. Connect with MongoDB Compass.
3. Create the database `parcelpark` with the collections `parks`, `routes` and `parcels`.
4. Import each JSON file (*Add Data → Import JSON*).
5. Run `queries.js` block by block in the `mongosh` panel.

---

## 1. From tables to documents

The relational design spread one parcel across **six tables**: `parcel`, `customer`, `park`, `transport_company`, `payment` and `tracking_event`. The document design stores **everything a customer needs to see about one parcel in one document**:

```json
{
  "tracking_code": "PP26000001",
  "status": "collected",
  "created_at": ISODate("2026-08-28T11:13:00Z"),
  "company":     { "company_id": 16, "name": "Carrier 16 Transport Ltd" },
  "sender":      { "customer_id": 1313, "name": "Customer 1313", "phone": "07000001313" },
  "receiver":    { "name": "Receiver 1", "phone": "07100000001" },
  "origin":      { "park_id": 20, "name": "Ilorin Post Office Park", "city": "Ilorin" },
  "destination": { "park_id": 16, "name": "Uyo Main Park", "city": "Uyo" },
  "item":        { "description": "Phone", "weight_kg": 37.35, "fragile": true, "serial_no": "SN70970988" },
  "fee": 8000,
  "payments": [ { "amount": 8000, "method": "transfer", "status": "successful", "at": ISODate("…") } ],
  "tracking": [ { "status": "registered", "park": "Ilorin Post Office Park", "at": ISODate("…") },
                { "status": "in_transit", "at": ISODate("…") }, … ]
}
```

| Relational (Portfolio 1) | Document model | Decision and reason |
|---|---|---|
| `tracking_event` table | **Embedded** array `tracking` | Always read together with the parcel. **Bounded**: a parcel has at most ~8 events |
| `payment` table | **Embedded** array `payments` | Few per parcel, and always shown with the parcel |
| `customer` (sender) | **Embedded** snapshot `sender` (+ `customer_id`) | The name and phone at the time of sending is exactly what the receipt needs |
| `park` | **Extended reference**: `park_id` + name + city copied in | Avoids a lookup for display. The full park document (with location) lives in `parks` |
| `park` (location, network) | Separate collections `parks` and `routes` | Shared, independently queried data stays **referenced** |
| Different parcel types | Flexible `item` sub-document | A laptop has a serial number, drugs have a NAFDAC number and cold-chain flag, food has a best-before date |

**Rule of thumb applied:** embed what is read together and bounded in size; reference what is shared, large or updated independently.

## 2. Queries and results

| # | Query | What it demonstrates | Result |
|---|---|---|---|
| N1 | Track a parcel by code | One read returns the parcel **and** its full history, with no joins | 1 document, 6 tracking events |
| N2 | Laptop vs Drugs vs Food parcels | **Flexible schema**: different attributes per document | Three different `item` shapes |
| N3 | Parcels by sender phone, before and after indexing | Indexes in MongoDB (as in Portfolio 2) | Before: **COLLSCAN**, 5000 docs examined. After: **IXSCAN**, 3 docs examined |
| N4 | October revenue per origin park | **Aggregation pipeline** (`$match → $unwind → $group → $sort`) | 20 parks with revenue |
| N5 | Cancel a parcel | **Single-document atomicity**: `$set` + `$push` in one operation | Status and history updated together |
| N6 | Parks within 20 km of a customer in Yaba | **Geospatial** `2dsphere` index + `$geoNear` | 3 Lagos parks, nearest first |
| N7 | Parks reachable from Jibowu with ≤ 2 transfers | **Graph traversal** with `$graphLookup` | Parks grouped by number of transfers |
| N8 | Insert an invalid parcel | **Schema validation** with `$jsonSchema` | Rejected: *Document failed validation* |

## 3. Why the document model suits ParcelPark's tracking side

- **It matches the main read pattern.** "Where is my parcel?" is by far the most frequent request. In PostgreSQL, the full answer needed joins across five tables (Portfolio 2, Q1 + Q2). Here it is **one indexed read of one document** (N1).
- **Atomic updates without multi-table transactions.** In Portfolio 3, registering or updating a parcel needed `BEGIN … COMMIT` across several tables. Here, changing the status and appending the tracking event happen in **one document**, and MongoDB guarantees single-document writes are atomic (N5).
- **Flexible attributes.** New parcel categories, such as cold-chain medicine, can carry new fields immediately. A relational design would need extra columns (mostly NULL) or an extra attribute table.
- **Built-in location and graph features.** "Nearest park" (N6) and "which parks can I reach" (N7) come directly from the database.
- **Flexible, but not lawless.** `$jsonSchema` validation (N8) still enforces the key rules, much like the CHECK constraints from Portfolio 1.

## 4. Where it is weaker (trade-offs)

- **Duplication.** Park and company names are copied into every parcel. If a park is renamed, thousands of documents must be updated, a problem the normalised design avoids. This is acceptable here because names rarely change.
- **Cross-entity rules are harder.** The vehicle-capacity rule from Portfolio 3 spans many parcels. MongoDB *does* support multi-document ACID transactions, but they are costlier and less natural than in PostgreSQL.
- **Reporting.** Aggregations work (N4), but complex ad-hoc reports joining many entities are more natural in SQL.

## 5. Conclusion: polyglot persistence
No single model wins everywhere. A realistic ParcelPark architecture would use **both**:
- **PostgreSQL** for payments, trip loading and capacity, where strict integrity and concurrency control matter (Portfolios 1–3).
- **MongoDB** for the customer-facing tracking service and the park/route network, where fast single-document reads, flexible attributes and geo/graph queries matter.

A **key-value store** such as Redis could further cache the most recent tracking lookups (`tracking_code → status`) for very high read volumes.
