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

## Github Actions Workflow Status and PR

PR link - https://github.com/iampankajaswal/DevOps-Task-Tripare.ai/pull/3

<img width="926" height="869" alt="image" src="https://github.com/user-attachments/assets/958507e7-7a33-4920-a9dc-dfa57c8b58aa" />


<img width="870" height="262" alt="image" src="https://github.com/user-attachments/assets/e8284f69-e773-4b76-b4cb-398ff46b2667" />


<img width="1142" height="265" alt="image" src="https://github.com/user-attachments/assets/3b30d2bd-fa63-4e2b-98b9-c14b42101903" />



## Part 4: Local Database Setup

### Start the Database

```bash
docker compose up -d
```

<img width="1141" height="133" alt="image" src="https://github.com/user-attachments/assets/7e547fb8-b44e-4d3d-b503-401df8c052a2" />


This starts a PostgreSQL 15 container and automatically runs:

1. `db/migrations/001_create_tables.sql` -- creates the `hotel_bookings` and `booking_events` tables
2. `db/migrations/002_create_indexes.sql` -- creates indexes for query optimization
3. `db/seeds/001_seed_data.sql` -- inserts 120 bookings and associated events

### Verify Tables Exist

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "\dt"
```

output:

<img width="1075" height="216" alt="image" src="https://github.com/user-attachments/assets/a95c1db4-eaf6-46b0-92bf-68eaae035286" />


### Schema

**hotel_bookings:**

<img width="1280" height="491" alt="image" src="https://github.com/user-attachments/assets/b464a0ee-59d4-46dc-b057-eb816cbd7a28" />



**booking_events:**

<img width="1254" height="415" alt="image" src="https://github.com/user-attachments/assets/5463e751-72a6-41cf-a934-7389346833d2" />


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

output:

<img width="1138" height="257" alt="image" src="https://github.com/user-attachments/assets/6747bb83-bb6d-484c-8b11-e184a0dceeb9" />

Check data distribution:

```bash
# By city
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c \
  "SELECT city, COUNT(*) FROM hotel_bookings GROUP BY city ORDER BY COUNT(*) DESC;"

# By status
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c \
  "SELECT status, COUNT(*) FROM hotel_bookings GROUP BY status ORDER BY COUNT(*) DESC;"
```

# Output by city

<img width="1848" height="319" alt="image" src="https://github.com/user-attachments/assets/5de07e04-29e1-4fd9-8b45-b412eb1b2aef" />


# Output by status

<img width="1840" height="267" alt="image" src="https://github.com/user-attachments/assets/3b934f6a-791d-4326-b54b-882611ec75e8" />




### Query Optimization

The target query to optimize:

```sql
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;
```

<img width="1464" height="820" alt="image" src="https://github.com/user-attachments/assets/44ce2c98-aa10-4ad5-9f37-2a7577c283cb" />




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

<img width="1411" height="590" alt="image" src="https://github.com/user-attachments/assets/72c13946-d52c-4caf-a2af-24ef2a8f23eb" />


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

<img width="817" height="244" alt="image" src="https://github.com/user-attachments/assets/3257a5b3-dafe-4f97-b9c9-793c775906e6" />


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

<img width="725" height="1002" alt="image" src="https://github.com/user-attachments/assets/ddd232cf-022d-4512-8845-0dad60271ed9" />


### How to Verify the Restore Worked

After running the restore script, check the following:

1. **Row counts should match the original data:**

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "
SELECT 'hotel_bookings' AS table_name, COUNT(*) AS row_count FROM hotel_bookings
UNION ALL
SELECT 'booking_events', COUNT(*) FROM booking_events;"
```

Output

<img width="1328" height="263" alt="image" src="https://github.com/user-attachments/assets/70710309-80bc-44f2-85c2-aa97950a6fc5" />



2. **Indexes should exist:**

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "\di"
```

Output

<img width="1263" height="261" alt="image" src="https://github.com/user-attachments/assets/067a41ee-2398-4b34-8f39-de923088acf0" />


3. **Run the target query to confirm data is intact:**

```bash
docker exec hotel_bookings_db psql -U dbadmin -d hotel_bookings -c "
SELECT org_id, status, COUNT(*), SUM(amount)
FROM hotel_bookings
WHERE city = 'delhi'
  AND created_at >= NOW() - INTERVAL '30 days'
GROUP BY org_id, status;"
```


Output

<img width="1187" height="422" alt="image" src="https://github.com/user-attachments/assets/84d126dc-a0f6-43b7-8c65-620e45a9057b" />


---

## Quick Start (All Steps)

```bash
# 1. Clone the repo
git clone https://github.com/iampankajaswal/DevOps-Task-Tripare.ai.git
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
