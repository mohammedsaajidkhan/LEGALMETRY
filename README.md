# LEGALMETRY - AI-Assisted Compliance Scanner for Legal Metrology (Packaged Commodities) Rules, 2011

## Overview
Automated legal metrology compliance verification system designed for field inspectors and regulatory officers.

## 7-Hour Parallel Build Plan Tracks & Ownership
| Track | Owner | Scope & Key Responsibilities |
|---|---|---|
| **Track 1: Data / Infra** | Person 1 | `infra/`, `backend/auth/`, `backend/db/`, `frontend/lib/auth/` |
| **Track 2: Capture / CV** | Person 2 | `backend/capture_ingest/`, `frontend/lib/capture/`, `category/`, `ocr_local/` |
| **Track 3: Core Pipeline** | Person 3 | `backend/core_pipeline/`, `backend/main.py` (FastAPI entrypoint) |
| **Track 4: Rules / Workflow**| Person 4 | `backend/rules_workflow/` (Rule 6 declarations, Table I/II, notices) |
| **Track 5: UI / Reports** | Person 5 | `frontend/lib/` (Flutter app entrypoint, theme, results, dashboard, reports) |

## Quick Start
```bash
docker-compose up -d
```
