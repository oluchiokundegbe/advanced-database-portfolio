# Portfolio 3 — Transactions and Concurrency

**Case study:** ParcelPark | **DBMS:** PostgreSQL 17 | **Tool:** pgAdmin 4 (two Query Tool windows = two park agents)

## Aim
To show how transactions keep ParcelPark's data correct, both when one operation spans several tables and when several agents work on the same data at the same time.

## The business scenario
At Jibowu Motor Park, a small car (**DEMO-CAR-01, 50 kg capacity**) is about to leave for Mile 1, Port Harcourt. Two agents each have a **30 kg** parcel to load. **Only one parcel can fit.** If both agents check the free space at the same moment, both see 50 kg free, both load, and the car leaves overloaded. This is a real safety and business risk, and the kind of problem concurrency control exists to prevent.

## Files and run order

| File | Demo | Windows |
|---|---|---|
| `00_setup.sql` | Creates the demo car, trip, two 30 kg parcels and the helper view `demo_trip_load` | 1 |
| `01_commit.sql` | **COMMIT**: atomic parcel registration across 3 tables | 1 |
| `02_rollback_savepoint.sql` | **ROLLBACK**, automatic abort on error, and **SAVEPOINT** | 1 |
| `03a/03b_isolation_*.sql` | **Isolation levels**: dirty read, non-repeatable read, READ COMMITTED vs REPEATABLE READ | 2 |
| `04a/04b_overbooking_problem_*.sql` | **The concurrency problem**: lost capacity check, so the car is overloaded | 2 |
| `05a/05b_fix_locking_*.sql` | **Fix 1**: pessimistic locking with `SELECT … FOR UPDATE` | 2 |
| `06a/06b_fix_serializable_*.sql` | **Fix 2**: optimistic control with `SERIALIZABLE` isolation | 2 |
| `07a/07b_deadlock_*.sql` | **Bonus**: deadlock detection | 2 |

For two-window demos, open two Query Tool tabs on `parcelpark` (each tab is a separate database session) and run the numbered steps in order, switching windows as instructed. pgAdmin's *Auto rollback on error* option was switched off so that error behaviour inside transactions could be observed directly.

---

## Demo 1 — COMMIT (Atomicity)
Registering a parcel writes to **three tables**: `parcel`, `tracking_event` (two events) and `payment`, and also updates `parcel.current_status`. Wrapping all of it in `BEGIN … COMMIT` makes it **one indivisible unit**. This is how the deliberate denormalisation from Portfolio 1 (`parcel.current_status`) is kept consistent with the `tracking_event` history.

*Observation:* both tracking events have the **same timestamp**. In PostgreSQL, `now()` returns the start time of the **transaction**, not of each statement, so every row written by one transaction is consistently stamped with the same moment.

## Demo 2 — ROLLBACK and SAVEPOINT
- **Manual ROLLBACK:** an agent marks a parcel *cancelled*. The change is visible inside the transaction, but after `ROLLBACK` the parcel is back to *paid*, as if nothing happened.
- **Error = automatic abort:** a parcel registration fails at the payment step (duplicate reference). PostgreSQL puts the transaction into an *aborted* state, so even `SELECT 1` is refused, and after `ROLLBACK` **neither the parcel nor its tracking event exists** (count = 0). No half-registered parcels are possible.
- **SAVEPOINT:** loading work is kept while only a failed extra charge is undone, using `ROLLBACK TO SAVEPOINT`. This is useful when one optional step fails but the main work should survive.

## Demo 3 — Isolation levels

| Step | READ COMMITTED (default) | REPEATABLE READ |
|---|---|---|
| B changes the status but has **not committed** | A still sees the old value. **No dirty read** | — |
| B **commits** | A sees the new value in the **same** transaction. **Non-repeatable read** | A **still sees its snapshot**. Repeatable |

PostgreSQL never allows dirty reads, even at `READ UNCOMMITTED`, because of its **MVCC** design: each transaction reads from a consistent snapshot of committed row versions, and readers never block writers.

## Demo 4 — The concurrency problem
Both agents run `SELECT * FROM demo_trip_load` and see **free_kg = 50**. Each loads a 30 kg parcel and commits. Result: **loaded_kg = 60, free_kg = −10**. The car is overloaded.

Nothing errored. Each transaction was individually valid, but their **interleaving** broke a business rule that spans several rows (total weight ≤ capacity). This anomaly is called **write skew**. READ COMMITTED does not prevent it, and neither do the table constraints, because no single row is invalid.

## Demo 5 — Fix 1: pessimistic locking (`SELECT … FOR UPDATE`)
Each agent first **locks the trip row**. When Agent B tries to lock the same trip, B's query **waits** (visible as a spinning query in pgAdmin) until A commits. B then checks again, sees **free_kg = 20**, and correctly does not load. Final state: **30 kg loaded, 20 kg free**. ✅
- *Pros:* simple, and correct by design. No work is wasted.
- *Cons:* agents wait for each other, and holding locks too long hurts throughput and risks deadlocks (see Demo 7).

## Demo 6 — Fix 2: optimistic control (`SERIALIZABLE`)
No locks are taken, and both agents load freely. When B commits, PostgreSQL's **Serializable Snapshot Isolation (SSI)** detects that the two transactions read and wrote overlapping data in a way no serial order could produce, and rejects B with:
> `ERROR: could not serialize access due to read/write dependencies among transactions`

B rolls back, re-checks (free_kg = 20) and does not load. ✅
- *Pros:* no waiting, and it protects **every** rule automatically, not just the ones we remembered to lock.
- *Cons:* the application **must retry** failed transactions, and there is more overhead under heavy contention.

**Choice for ParcelPark:** contention is low (a few agents per vehicle), so either approach works. `FOR UPDATE` is the clearer choice for the loading operation because the conflict point (the trip) is obvious, while `SERIALIZABLE` suits complex financial operations where the rules are harder to enumerate.

## Demo 7 (bonus) — Deadlock
Agent A updates parcel 1 then parcel 2. Agent B updates parcel 2 then parcel 1. Each waits for a lock the other holds. PostgreSQL's deadlock detector (it checks after `deadlock_timeout`, 1 second by default) **cancels one transaction** with `ERROR: deadlock detected`, so the other can finish. *Prevention:* always lock rows in a consistent order, e.g. by tracking code.

## Evidence
Screenshots in `screenshots/` show each step's output, including the overloaded car (Demo 4), the waiting query and its release (Demo 5), the serialization failure (Demo 6) and the deadlock error (Demo 7).
