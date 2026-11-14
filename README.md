# Advanced Database Systems Portfolio — ParcelPark

**Student:** Oluchi Augustina Okundegbe | **Student ID:** 301856639 | **Repository:** https://github.com/oluchiokundegbe/advanced-database-portfolio

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
| `portfolio-1-database-design/` | ER diagram, relational schema, constraints, normalisation | Complete |
| `portfolio-2-query-optimisation/` | SQL queries, execution plans, indexing, materialized view | Complete |
| `portfolio-3-transactions-concurrency/` | Commit, rollback, savepoints, isolation levels, locking, SERIALIZABLE, deadlock | Complete |
| `portfolio-4-nosql/` | MongoDB document model, indexing, aggregation, geospatial and graph queries, validation | Complete |
| `portfolio-5-distributed-cloud/` | MongoDB Atlas deployment, replication, write concerns, sharding design | Complete |

Each folder has its own README explaining how the work was implemented and tested, the scripts in run order, and a `screenshots/` folder with the evidence.

## Tools

PostgreSQL 17 with pgAdmin 4 (Portfolios 1-3); MongoDB 8.0 on MongoDB Atlas (AWS, Paris) with MongoDB Compass (Portfolios 4-5); VS Code and Git.
