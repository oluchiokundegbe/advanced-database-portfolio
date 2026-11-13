// =====================================================================
// ParcelPark | Portfolio 4: NoSQL (MongoDB document model)
// Paste ONE numbered block at a time into the MONGOSH shell in Compass
// (bottom of the Compass window), press Enter, and screenshot the result.
// =====================================================================

// ---------- N0  select the database --------------------------------
use parcelpark


// ---------- N1  "Where is my parcel?" -------------------------------
// ONE read returns the parcel, sender, receiver, parks, payments and
// the full tracking history. In PostgreSQL this needed joins across
// parcel, park, staff, payment and tracking_event (Portfolio 2, Q1+Q2).
db.parcels.findOne({ tracking_code: "PP26000001" })


// ---------- N2  Flexible schema -------------------------------------
// Different kinds of parcel store different attributes in "item".
// No ALTER TABLE, no NULL-filled columns.
db.parcels.find({ "item.description": "Laptop" }, { _id: 0, tracking_code: 1, item: 1 }).limit(1)
db.parcels.find({ "item.description": "Drugs" },  { _id: 0, tracking_code: 1, item: 1 }).limit(1)
db.parcels.find({ "item.description": "Food items" }, { _id: 0, tracking_code: 1, item: 1 }).limit(1)


// ---------- N3a  Find a customer's parcels BEFORE indexing ----------
const before = db.parcels.find({ "sender.phone": "07000001313" }).explain("executionStats");
({ plan: JSON.stringify(before.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN (index)" : "COLLSCAN (reads every document)",
   docsExamined: before.executionStats.totalDocsExamined,
   returned: before.executionStats.nReturned,
   timeMs: before.executionStats.executionTimeMillis })


// ---------- N3b  Create indexes --------------------------------------
db.parcels.createIndex({ tracking_code: 1 }, { unique: true })
db.parcels.createIndex({ "sender.phone": 1 })
db.parcels.getIndexes()


// ---------- N3c  The same query AFTER indexing -----------------------
const after = db.parcels.find({ "sender.phone": "07000001313" }).explain("executionStats");
({ plan: JSON.stringify(after.queryPlanner.winningPlan).includes("IXSCAN") ? "IXSCAN (index)" : "COLLSCAN (reads every document)",
   docsExamined: after.executionStats.totalDocsExamined,
   returned: after.executionStats.nReturned,
   timeMs: after.executionStats.executionTimeMillis })


// ---------- N4  Aggregation: October 2026 revenue per origin park ----
// The same management report as Portfolio 2, Q4.
db.parcels.aggregate([
  { $match: { created_at: { $gte: ISODate("2026-10-01"), $lt: ISODate("2026-11-01") } } },
  { $unwind: "$payments" },
  { $match: { "payments.status": "successful" } },
  { $group: { _id: "$origin.name", parcels: { $sum: 1 }, revenue: { $sum: "$payments.amount" } } },
  { $sort: { revenue: -1 } }
])


// ---------- N5  Atomic update of ONE document ------------------------
// Update the status AND append a tracking event in a single operation.
// A single-document write is always atomic in MongoDB, so this needs no
// multi-statement transaction (compare Portfolio 3, Demo 1).
db.parcels.findOne({ tracking_code: "PP26000002" }, { _id: 0, status: 1, tracking: { $slice: -1 } })

// Run this updateOne ONCE (running it twice adds a second event)
db.parcels.updateOne(
  { tracking_code: "PP26000002" },
  { $set:  { status: "cancelled" },
    $push: { tracking: { status: "cancelled", at: new Date(), park: "Jibowu Motor Park", note: "Sender cancelled" } } }
)

db.parcels.findOne({ tracking_code: "PP26000002" }, { _id: 0, status: 1, tracking: { $slice: -2 } })


// ---------- N6  Geospatial: nearest parks to a customer --------------
// A customer in Yaba, Lagos (longitude 3.3770, latitude 6.5095) asks:
// "Which parks are within 20 km of me?"
db.parks.createIndex({ location: "2dsphere" })

db.parks.aggregate([
  { $geoNear: { near: { type: "Point", coordinates: [3.3770, 6.5095] },
                distanceField: "distance_m", maxDistance: 20000, spherical: true } },
  { $project: { _id: 0, name: 1, city: 1, distance_km: { $round: [{ $divide: ["$distance_m", 1000] }, 1] } } }
])


// ---------- N7  Graph traversal: which parks can Jibowu reach? -------
// Roads between parks form a graph. $graphLookup follows the edges:
// depth 0 = direct road, depth 1 = one transfer, depth 2 = two transfers.
db.parks.aggregate([
  { $match: { name: "Jibowu Motor Park" } },
  { $graphLookup: { from: "routes", startWith: "$name", connectFromField: "to",
                    connectToField: "from", as: "reachable", maxDepth: 2, depthField: "transfers" } },
  { $unwind: "$reachable" },
  { $group: { _id: "$reachable.to", transfers: { $min: "$reachable.transfers" } } },
  { $match: { _id: { $ne: "Jibowu Motor Park" } } },
  { $sort: { transfers: 1, _id: 1 } }
])


// ---------- N8  Schema validation: flexible, but not lawless ---------
// Enforce the rules that matter, like the CHECK constraints in Portfolio 1.
db.runCommand({
  collMod: "parcels",
  validator: { $jsonSchema: {
    bsonType: "object",
    required: ["tracking_code", "status", "origin", "destination", "item"],
    properties: {
      tracking_code: { bsonType: "string", pattern: "^PP[0-9]{8}$" },
      status: { enum: ["registered", "paid", "loaded", "in_transit", "arrived", "collected", "returned", "cancelled"] },
      item: { bsonType: "object", required: ["weight_kg"],
              properties: { weight_kg: { bsonType: ["double", "int"], minimum: 0.1 } } }
  } } },
  validationLevel: "strict"
})

// This insert breaks THREE rules (bad code, unknown status, negative weight) -> rejected
db.parcels.insertOne({
  tracking_code: "BAD-123", status: "lost",
  origin: { name: "Jibowu Motor Park" }, destination: { name: "Mile 1 Motor Park" },
  item: { description: "Test", weight_kg: -5 }
})
