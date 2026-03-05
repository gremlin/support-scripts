# Gremlin RDS Latency Test Lab

This guide documents how to reproduce the test environment used to validate **Gremlin latency and network fault experiments against Aurora PostgreSQL (RDS)**.

The environment consists of:

- **EC2 instance** running RHEL 9
- **Aurora PostgreSQL cluster**
- **Docker container** running a Python FastAPI application
- Test scripts to generate continuous database queries

This environment allows testing:

- Network latency injection
- Network blackhole scenarios
- Application behavior when database connectivity degrades

---

# Architecture

Client/Test Script
↓
FastAPI Application (Docker Container on EC2)
↓
Aurora PostgreSQL (RDS)

The API queries Aurora and returns **timing metrics** that clearly show the impact of network faults.

---

# Prerequisites

- AWS account
- Access to AWS Console
- Docker or Podman installed on EC2
- Basic knowledge of SSH

---

# Step 1 — Deploy EC2 Instance

Create an EC2 instance with the following configuration.


| Setting        | Value                          |
| -------------- | ------------------------------ |
| AMI            | RHEL 9                         |
| Instance Type  | t3.micro                       |
| Network        | Default VPC (same VPC as RDS)  |
| Security Group | Allow outbound internet access |

Connect to the instance via SSH:

```bash
ssh ec2-user@<ec2-public-ip>
```

---

# Step 2 — Deploy Aurora PostgreSQL

In the AWS Console:

```
RDS → Create Database
```

Select:


| Setting       | Value             |
| ------------- | ----------------- |
| Engine        | Aurora PostgreSQL |
| Configuration | Easy Create       |
| Workload Type | Dev/Test          |

Configure the database credentials.


| Setting            | Description                 |
| ------------------ | --------------------------- |
| Cluster Identifier | Name for the Aurora cluster |
| Master Username    | Database administrator      |
| Master Password    | Self-managed password       |

---

# Step 3 — Configure Networking

Allow the EC2 instance to access the database.

Open the **RDS Security Group** and add an inbound rule:


| Type       | Port | Source             |
| ---------- | ---- | ------------------ |
| PostgreSQL | 5432 | EC2 Security Group |

This allows:

EC2 → Aurora PostgreSQL

---

# Step 4 — Clone Repository

SSH into the EC2 instance and clone the repository.

```bash
git clone <repository-url>
cd gremlin-rds-lab
```

---

# Step 5 — Build Container 

Version 1.1 has been published to https://hub.docker.com/repository/docker/gremlin/gremlin-rds-lab
`docker pull gremlin/gremlin-rds-lab:1.1`

Using Podman:

```bash
podman build -t gremlin-rds-lab .
```

Using Docker:

```bash
docker build -t gremlin-rds-lab .
```

---

# Step 6 — Run Container

Run the container and pass the database connection parameters.

```bash
podman run -p 8080:8080   -e DB_HOST=<aurora-endpoint>   -e DB_PORT=5432   -e DB_NAME=gremlin_rds_test   -e DB_USER=<username>   -e DB_PASSWORD=<password>   -e SEED_ON_START=1   gremlin-rds-lab
```

Example:

```bash
podman run -p 8080:8080   -e DB_HOST=mycluster.cluster-abc123.us-east-1.rds.amazonaws.com   -e DB_USER=postgres   -e DB_PASSWORD=password123   -e DB_NAME=gremlin_rds_test   -e SEED_ON_START=1   gremlin-rds-lab
```

---

# Step 7 — Database Initialization

When the container starts it automatically runs:

```
seed_rds.sh
```

This script:

- Creates the database tables
- Inserts test records

Tables created:

- fruit
- vegetables

Each table contains **25 records**.

---

# Step 8 — API Endpoints

The application exposes two endpoints.


| Endpoint    | Description               |
| ----------- | ------------------------- |
| /fruits     | Returns fruit records     |
| /vegetables | Returns vegetable records |

Example request:

```bash
curl http://localhost:8080/fruits
```

Example response:

```json
{
  "timings_ms": {
    "server_handler_time_ms": 80.1,
    "server_processing_time_ms": 80.0,
    "db_query_execution_time_ms": 74.1
  }
}
```

The **db_query_execution_time_ms** value is useful for observing injected latency.

---

# Step 9 — Run Continuous Query Test

The repository includes a script to continuously query the API.

```bash
./db_test_query.sh
```

Default behavior:

- Calls `/fruits` endpoint
- Runs every **3 seconds**
- Logs latency metrics

Example output:

```
----- Wed Mar 5 18:02:00 -----
{
  "server_handler_time_ms": 80.1,
  "server_processing_time_ms": 80.0,
  "db_query_execution_time_ms": 74.1
}
```

---

# Step 10 — Query Vegetables Endpoint

```bash
ENDPOINT=/vegetables ./db_test_query.sh
```

---

# Step 11 — Connect to Database

The repository includes a helper script to connect directly to Aurora.

Set the required variables:

```bash
export DB_HOST=<aurora-endpoint>
export DB_USER=<username>
export DB_NAME=gremlin_rds_test
export PGPASSWORD=<password>
```

Run:

```bash
./connect_to_rds.sh
```

---

# Environment Variables


| Variable      | Required | Description              |
| ------------- | -------- | ------------------------ |
| DB_HOST       | Yes      | Aurora cluster endpoint  |
| DB_PORT       | No       | Default 5432             |
| DB_NAME       | Yes      | Database name            |
| DB_USER       | Yes      | Database username        |
| DB_PASSWORD   | Yes      | Database password        |
| SEED_ON_START | No       | Run database seed script |

---

# Example Gremlin Tests

This environment can be used to test Gremlin fault scenarios.

### Inject Latency

Inject network latency between the application container and the database.

Expected behavior:

```
db_query_execution_time_ms increases
```

Example:

```
db_query_execution_time_ms ≈ 2000 ms
```

---

### Blackhole Network

Simulate network loss between application and database.

Expected behavior:

- API timeouts
- Connection failures

---

# Cleanup

Stop the container:

```bash
podman stop <container-id>
```

Delete infrastructure:

- Terminate EC2 instance
- Delete Aurora cluster

---

# Repository Structure

```
gremlin-rds-lab
│
├── app.py
├── Dockerfile
├── requirements.txt
│
├── seed_rds.sh
├── db_test_query.sh
├── connect_to_rds.sh
│
└── start.sh
```

---

# Summary

This environment provides a lightweight way to test **database network resilience scenarios** using:

- Aurora PostgreSQL
- Dockerized Python API
- Continuous query load generation

It is particularly useful for validating **Gremlin network fault experiments** and demonstrating application behavior under degraded database connectivity.
