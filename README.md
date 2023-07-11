# BigQuery Operations

This repository contains a few useful queries for BigQuery FinOps and operations.

at the moment this includes:

- storage management
- reservations management

This is a dbt project. For each topic you find the documentation in the respective model folder.

## Getting Started

Prerequisite: Python 3.9 or later

Prepare your development environment with:

```bash
python3 -m venv venv
source venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
export DBT_PROFILES_DIR="."
export DBT_BIGQUERY_PROJECT="your-gcp-project-id"
export DBT_BIGQUERY_DATASET="your-bigquery-dataset"
```
