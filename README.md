## Terraform with Database Reliability

This project covers AWS infrastructure design using Terraform and practical database backup, restore, and query optimization with PostgreSQL.

## Project Structure

```
devops-assessment/
  infra/
    modules/
      network/        # VPC, subnets, security groups
      ecs/            # ECS cluster, task definition, ALB, service
      rds/            # RDS PostgreSQL instance
    envs/
      dev/            # Dev environment config
      prod/           # Prod environment config
  db/
    migrations/       # SQL schema files
    seeds/            # Seed data
  scripts/
    backup.sh         # Database backup script
    restore.sh        # Database restore script
  backups/            # Backup files (gitignored)
  .github/
    workflows/
      terraform.yml   # GitHub Actions workflow
  docker-compose.yml  # Local PostgreSQL setup
```

## Prerequisites

- Docker and Docker Compose
- Terraform >= 1.5.0
- Git

---

## Part 1 and 2: Terraform Infrastructure

### Architecture

```
Internet --> ALB --> ECS/Fargate --> RDS (private)
```

The Terraform code creates the following resources:

- VPC with 2 public subnets and 2 private subnets
- Internet Gateway and NAT Gateways
- ALB security group (allows HTTP/HTTPS from the internet)
- ECS security group (allows traffic only from the ALB)
- RDS security group (allows PostgreSQL traffic only from ECS) -- RDS is private and not accessible from the internet
- ECS Fargate cluster, task definition, and service running Nginx
- RDS PostgreSQL instance in private subnets

### Environment Differences

| Setting               | Dev              | Prod              |
|-----------------------|------------------|--------------------|
| ECS CPU               | 256              | 512               |
| ECS Memory            | 512 MB           | 1024 MB           |
| ECS Task Count        | 1                | 2                 |
| RDS Instance Class    | db.t3.micro      | db.t3.medium      |
| RDS Storage           | 20 GB            | 50 GB             |
| RDS Multi-AZ          | false            | true              |
| Backup Retention      | 3 days           | 14 days           |
| Deletion Protection   | false            | true              |

### Validate Terraform Locally

Since there is no actual AWS account connected, the S3 backend will not work. To validate locally, create override files that switch to a local backend:

```bash
# Create backend override for dev
cat > infra/envs/dev/backend_override.tf << 'EOF'
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF

# Create backend override for prod
cat > infra/envs/prod/backend_override.tf << 'EOF'
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF
```

Then run these commands for each environment:

```bash
# Dev environment
cd infra/envs/dev
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -refresh=false -input=false

# Prod environment
cd ../prod
terraform init
terraform fmt -check -recursive
terraform validate
terraform plan -refresh=false -input=false
```

**Dev validation output:**

<img width="812" height="411" alt="image" src="https://github.com/user-attachments/assets/24fe1cca-ee72-4e28-9cc1-33b4e8911e6e" />

<img width="676" height="145" alt="image" src="https://github.com/user-attachments/assets/71919dc6-8d1f-416d-b748-df768e807bf7" />

<img width="1298" height="565" alt="image" src="https://github.com/user-attachments/assets/00c0693b-5299-488f-a932-67e4f27e2dd2" />


<img width="1398" height="257" alt="image" src="https://github.com/user-attachments/assets/9279f624-be60-4d86-b308-7d20b6e4fa44" />




**Prod validation output:**


<img width="957" height="380" alt="image" src="https://github.com/user-attachments/assets/e4dab2fc-b0f8-4f7d-b8bf-08639c5d4419" />

<img width="718" height="166" alt="image" src="https://github.com/user-attachments/assets/44ae924a-29fa-4c1b-bb5d-21908d4cf3fe" />

<img width="1520" height="559" alt="image" src="https://github.com/user-attachments/assets/59ed83ee-8cf4-4b90-81a8-f61339905939" />

<img width="1611" height="722" alt="image" src="https://github.com/user-attachments/assets/792560a1-91ac-4d93-bbf5-53b0dd12102a" />




---

## Part 3: GitHub Actions Workflow

The file `.github/workflows/terraform.yml` runs on every pull request that changes files under `infra/`. It runs for both dev and prod environments and does the following:

1. `terraform fmt -check -recursive` -- checks formatting
2. `terraform init -backend=false` -- initializes modules and providers
3. `terraform validate` -- validates the configuration
4. `terraform plan` -- generates the execution plan

The plan output is posted as a comment on the pull request so reviewers can see what changes Terraform would make.

---

## Part 4: Local Database Setup

### Start the Database

```bash
docker compose up -d
```

This starts a PostgreSQL 15 container and automatically runs:

1. `db/migrations/001_create_tables.sql` -- creates the `hotel_bookings` and `booking_events` tables
2. `db/migrations/002_create_indexes.sql` -- creates indexes for query optimization
3. `db/seeds/001_seed_data.sql` -- inserts 120 bookings and associated events

### Verify Tables Exist

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "\dt"
```

Expected output:

```
 Schema |      Name      | Type  |  Owner
--------+----------------+-------+---------
 public | booking_events | table | dbadmin
 public | hotel_bookings | table | dbadmin
```

### Schema

**hotel_bookings:**

| Column         | Type           | Notes                  |
|----------------|----------------|------------------------|
| id             | UUID           | Primary key, auto-generated |
| org_id         | UUID           | Organization identifier |
| hotel_id       | VARCHAR(100)   | Hotel identifier        |
| city           | VARCHAR(100)   | City name               |
| checkin_date   | DATE           | Check-in date           |
| checkout_date  | DATE           | Check-out date          |
| amount         | NUMERIC(12,2)  | Booking amount          |
| status         | VARCHAR(50)    | Booking status          |
| created_at     | TIMESTAMP      | Record creation time    |

**booking_events:**

| Column      | Type           | Notes                         |
|-------------|----------------|-------------------------------|
| id          | BIGSERIAL      | Primary key, auto-increment   |
| booking_id  | UUID           | Foreign key to hotel_bookings |
| event_type  | VARCHAR(100)   | Type of event                 |
| payload     | JSONB          | Event details as JSON         |
| created_at  | TIMESTAMP      | Event creation time           |

---

## Part 5: Seed Data and Indexing

### Seed Data Summary

The seed script creates 120 hotel bookings spread across:

- **8 cities:** delhi, mumbai, bangalore, chennai, kolkata, hyderabad, pune, jaipur
- **5 organizations:** different UUID-based org_ids
- **5 statuses:** confirmed, cancelled, pending, checked_in, checked_out
- **10 hotels:** HTL001 through HTL010
- **Booking events:** roughly 60% of bookings have a `booking_created` event, 30% have `payment_received`, and 20% have `booking_modified`

### Verify Seed Data

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "
SELECT 'hotel_bookings' AS table_name, COUNT(*) AS row_count FROM hotel_bookings
UNION ALL
SELECT 'booking_events', COUNT(*) FROM booking_events;"
```

Expected output:

```
   table_name   | row_count
----------------+-----------
 hotel_bookings |       120
 booking_events |       139
```

Check data distribution:

```bash
# By city
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c \
  "SELECT city, COUNT(*) FROM hotel_bookings GROUP BY city ORDER BY COUNT(*) DESC;"

# By status
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c \
  "SELECT status, COUNT(*) FROM hotel_bookings GROUP BY status ORDER BY COUNT(*) DESC;"
```

### Query Optimization

The target query to optimize:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

**Index created:**

```sql
CREATE INDEX idx_hotel_bookings_city_created_at
    ON hotel_bookings (city, created_at)
    INCLUDE (org_id, status, amount);
```

**Why this index:**

1. The WHERE clause filters on `city` and `created_at`, so these are the leading columns in the index. PostgreSQL can quickly find rows matching `city = 'delhi'` and then scan forward through the `created_at` range.
2. The INCLUDE clause adds `org_id`, `status`, and `amount` to the index. These columns are needed for the GROUP BY and SUM, but are not used for filtering. By including them, PostgreSQL can answer the entire query from the index alone (an "index-only scan") without reading the actual table rows. This is called a covering index.
3. For a table with millions of rows, this index avoids a full table scan and eliminates the need for heap lookups, which gives a significant performance improvement.

**Verify the index is used:**

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "
SET enable_seqscan = OFF;
EXPLAIN ANALYZE
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;"
```

Output shows `Bitmap Index Scan on idx_hotel_bookings_city_created_at`, confirming the index is used.

Note: With only 120 rows, PostgreSQL's query planner may prefer a sequential scan since it is faster for small tables. The `SET enable_seqscan = OFF` forces the planner to use the index so you can verify it works. On a production table with thousands or millions of rows, the planner will use the index automatically.

---

## Part 6: Backup and Restore

### Create a Backup

```bash
./scripts/backup.sh
```

This creates a timestamped SQL dump in the `backups/` directory.

Output:

```
Starting database backup...
Database: hotel_bookings
Container: hotel_bookings_db
Backup file: /path/to/backups/backup_20261113_201855.sql
Backup completed successfully.
File: /path/to/backups/backup_20261113_201855.sql
Size: 44K
```

### Restore from Backup

```bash
./scripts/restore.sh
```

The script will:
1. Find the most recent backup file automatically (or you can pass a specific file as an argument)
2. Show a warning and wait 5 seconds before proceeding
3. Drop and recreate the database
4. Restore all data from the backup
5. Show row counts to verify the restore worked

You can also restore a specific backup:

```bash
./scripts/restore.sh backups/backup_20261113_201855.sql
```

Output:

```
Starting database restore...
Backup file: backups/backup_20261113_201855.sql
Database: hotel_bookings
Container: hotel_bookings_db

WARNING: This will drop and recreate the database.
Press Ctrl+C within 5 seconds to cancel...
Dropping existing database...
Restoring from backup...
...
Restore completed. Verifying...

=== Row counts ===
   table_name   | row_count
----------------+-----------
 hotel_bookings |       120
 booking_events |       139

Restore verified successfully.
```

### How to Verify the Restore Worked

After running the restore script, check the following:

1. **Row counts should match the original data:**

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "
SELECT 'hotel_bookings' AS table_name, COUNT(*) AS row_count FROM hotel_bookings
UNION ALL
SELECT 'booking_events', COUNT(*) FROM booking_events;"
```

2. **Indexes should exist:**

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "\di"
```

3. **Run the target query to confirm data is intact:**

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;"
```

If all three checks return results, the restore was successful.

---

## Quick Start (All Steps)

```bash
# 1. Clone the repo
git clone <repo-url>
cd devops-assessment

# 2. Start the database
docker compose up -d

# 3. Wait a few seconds for init scripts to run, then verify
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "\dt"

# 4. Check seed data
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "
SELECT 'hotel_bookings' AS table_name, COUNT(*) FROM hotel_bookings
UNION ALL
SELECT 'booking_events', COUNT(*) FROM booking_events;"

# 5. Run backup
./scripts/backup.sh

# 6. Run restore
./scripts/restore.sh

# 7. Validate Terraform (see Part 1 section above for backend override setup)
cd infra/envs/dev
terraform init
terraform validate
terraform plan -refresh=false -input=false
```

---

## Cleanup

```bash
docker compose down -v
```

This stops the PostgreSQL container and removes the data volume.
