// =====================================================================
// ParcelPark | Portfolio 5: Distributed and cloud database exercise
// Runs on the MongoDB Atlas cluster from Portfolio 4 (3-server replica set).
// Paste ONE numbered block at a time into the MONGOSH shell in Compass.
// =====================================================================

// ---------- D0  select the database ----------------------------------
use parcelpark


// ---------- D1  Who is in the replica set? ---------------------------
// Atlas runs ParcelPark on THREE servers. One PRIMARY takes all writes;
// two SECONDARIES keep live copies of the data.
const h = db.hello();
({ replicaSet: h.setName,
   primary: h.primary,
   allServers: h.hosts,
   numberOfServers: h.hosts.length,
   connectedTo: h.me,
   isWritablePrimary: h.isWritablePrimary })


// ---------- D2  The data really is on the other servers --------------
// Read the same parcel from the PRIMARY and from a SECONDARY.
// Different servers, same data = replication.
const p = db.parcels.find({ tracking_code: "PP26000001" }).readPref("primary").explain("executionStats");
const s = db.parcels.find({ tracking_code: "PP26000001" }).readPref("secondary").explain("executionStats");
({ answeredByPrimary: p.serverInfo.host + ":" + p.serverInfo.port,
   answeredBySecondary: s.serverInfo.host + ":" + s.serverInfo.port,
   differentServers: (p.serverInfo.host + p.serverInfo.port) !== (s.serverInfo.host + s.serverInfo.port),
   foundOnPrimary: p.executionStats.nReturned,
   foundOnSecondary: s.executionStats.nReturned })


// ---------- D3  Replication in action --------------------------------
// Write a new tracking event on the primary, then read it back from a secondary.
// (If the second command returns nothing, wait a second and run it again:
//  that tiny delay is "replication lag", and seeing it is a good result too.)
db.replication_test.insertOne(
  { tracking_code: "PP26999999", status: "registered", park: "Jibowu Motor Park", at: new Date() },
  { writeConcern: { w: "majority" } }
)

db.replication_test.find({ tracking_code: "PP26999999" }).readPref("secondary")


// ---------- D4  Consistency vs speed: write concerns -----------------
// w:0        = fire and forget (no confirmation at all)
// w:1        = primary confirms
// w:majority = primary + at least one secondary confirm (survives a server crash)
// Each line inserts 20 test documents and reports the average time per write.
function avgWriteMs(wc) {
  const start = Date.now();
  for (let i = 0; i < 20; i++) {
    db.write_concern_test.insertOne({ i: i, wc: JSON.stringify(wc), at: new Date() }, { writeConcern: wc });
  }
  return Math.round((Date.now() - start) / 20) + " ms per write";
}
({ "w:0 (no confirmation)":       avgWriteMs({ w: 0 }),
   "w:1 (primary only)":          avgWriteMs({ w: 1 }),
   "w:majority (2 of 3 servers)": avgWriteMs({ w: "majority" }) })


// ---------- D5  Is the cluster sharded? -----------------------------
// The free M0 tier is a replica set, NOT a sharded cluster.
// This command is expected to report that sharding is not available.
sh.status()


// ---------- D6  Choosing a shard key: compare candidate fields ------
// A good shard key has HIGH cardinality (many distinct values)
// and spreads writes evenly.
({ tracking_code: db.parcels.distinct("tracking_code").length,
   sender_phone:  db.parcels.distinct("sender.phone").length,
   company:       db.parcels.distinct("company.name").length,
   origin_city:   db.parcels.distinct("origin.city").length,
   status:        db.parcels.distinct("status").length })


// ---------- D7  If we sharded by geopolitical zone: how even? -------
db.parcels.aggregate([
  { $addFields: { zone: { $switch: { branches: [
      { case: { $in: ["$origin.city", ["Lagos", "Ibadan"]] },                      then: "South-West" },
      { case: { $in: ["$origin.city", ["Onitsha", "Enugu", "Owerri", "Aba"]] },    then: "South-East" },
      { case: { $in: ["$origin.city", ["Port Harcourt", "Benin City", "Uyo",
                                        "Calabar", "Warri", "Asaba"]] },           then: "South-South" },
      { case: { $in: ["$origin.city", ["Abuja", "Ilorin"]] },                      then: "North-Central" },
      { case: { $in: ["$origin.city", ["Kano", "Kaduna"]] },                       then: "North-West" } ],
      default: "Other" } } } },
  { $group: { _id: "$zone", parcels: { $sum: 1 } } },
  { $project: { _id: 0, zone: "$_id", parcels: 1,
                percent: { $round: [{ $multiply: [{ $divide: ["$parcels", 5000] }, 100] }, 1] } } },
  { $sort: { parcels: -1 } }
])


// ---------- D8  Tidy up the test collections ------------------------
db.replication_test.drop()
db.write_concern_test.drop()
