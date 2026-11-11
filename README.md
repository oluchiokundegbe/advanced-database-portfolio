# Advanced Database Systems Portfolio — ParcelPark

MIT 8103 Advanced Database Systems | Miva Open University | 2026/2027 First Semester

## Selected Case Study

**ParcelPark** is a parcel-tracking platform for Nigerian inter-city motor parks, such as Jibowu (Lagos), Mile 1 (Port Harcourt) and Utako (Abuja). Senders drop parcels at a park. Transport companies registered on the platform carry them on scheduled trips, sometimes over several legs. Receivers collect them at the destination park.

- **Nature of the system:** a multi-company logistics platform (many transport companies, many parks)
- **Users of the database:** senders, receivers, park agents, drivers, transport company admins, platform admins
- **Major data stored:** parks, transport companies, vehicles, drivers, staff, customers, parcels, trips, parcel legs, tracking events, payments
- **Key operations:** register a parcel and issue a tracking code, take payment, assign a parcel to a trip, update status at each checkpoint, track by code, confirm pickup, and report on delays and revenue per park

## Portfolio Structure

| Folder | Activity | Status |
|---|---|---|
| `portfolio-1-database-design/` | ER diagram, relational schema, constraints, normalisation | In progress |
| `portfolio-2-query-optimisation/` | SQL queries, execution plans, indexing | Not started |
| `portfolio-3-transactions-concurrency/` | Commit, rollback, isolation, concurrency control | Not started |
| `portfolio-4-nosql/` | NoSQL model of ParcelPark | Not started |
| `portfolio-5-distributed-cloud/` | Replication, sharding, cloud deployment | Not started |

## Tools

PostgreSQL 17 (relational), MongoDB (NoSQL, Portfolio 4), and a cloud PostgreSQL provider (Portfolio 5).
