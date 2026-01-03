# 401k Visualizer – Implementation TODO (Ordered by Dependency)

This checklist is ordered **top-to-bottom in strict dependency order**. You should be able to execute it sequentially without major refactors. Each section unlocks the next.

---

## 0) Repo + Standards (Foundation)

- [x] Create monorepo structure
  - `/backend` (Sinatra API)
  - `/frontend` (React)
  - `/shared` (optional: schemas/types)
  - `/docs` (architecture + decisions)
- [x] Decide conventions
  - API: JSON
  - Naming: snake_case (backend), camelCase (frontend)
  - Dates: ISO-8601, paycheck date treated as local date
- [x] Add root `Makefile`
  - `make setup` – install backend + frontend deps
  - `make dev` – run backend + frontend
  - `make test` – all tests
  - `make lint` – rubocop + eslint
  - `make db-reset`
  - `make db-migrate`
- [x] CI setup (GitHub Actions)
  - Run `make lint`
  - Run `make test`
- [x] Security + quality baseline
  - Backend: `rubocop`, `bundler-audit`, `brakeman`
  - Frontend: `eslint`, `npm audit`
  - `/docs/security.md` checklist

---

## 1) IRS Year Configuration System (Hard Dependency for Everything)

- [x] Define `irs_data/<year>.env` contract
  - `EMPLOYEE_DEFERRAL_LIMIT`
  - `TOTAL_401K_LIMIT`
  - HSA limits (if supported)
- [x] Implement supported-year discovery
  - Backend scans `irs_data/*.env`
  - API: `GET /config/tax-years`
- [x] Implement tax-year config loader
  - API: `GET /config/tax-year/:year`
- [x] Validation
  - Fail startup if required keys missing
  - Clear error messages

---

## 2) Domain Model + Persistence (Backend Core)

- [x] Database schema (Sequel migrations)
  - `households`
    - name, tax_year, filing_status, state, status, timestamps
  - `spouses`
    - household_id, name
  - `jobs`
    - spouse_id
    - employer_name
    - first_paycheck_date
    - pay_frequency
    - base_salary
    - bonus_amount
    - bonus_date
    - plan flags (pretax, roth, aftertax, mega_backdoor_allowed)
    - match_percent
    - match_cap_percent
    - true_up
    - starting_ytd buckets
  - `contribution_settings`
    - job_id
    - pretax_pct
    - roth_pct
    - aftertax_pct
- [x] DB constraints
  - Foreign keys
  - NOT NULL where applicable
  - Percent range checks
- [x] Dev seeds / fixtures
  - 2 spouses
  - Multiple overlapping jobs
  - Bonus + match examples

---

## 3) REST API (Frontend Depends on This)

- [x] API versioning
  - `/api/v1/...`
- [x] CRUD endpoints
  - Households
  - Spouses (nested)
  - Jobs (nested)
  - Contribution settings
- [x] Request validation
  - Required fields
  - Percent ranges
  - Date validity
- [x] Workflow resume support
  - Household `status`
  - API returns next required step
- [x] Hardening
  - CORS restricted
  - `Rack::Protection`
  - Request size limits
  - Safe JSON parsing

---

## 4) Paycheck Schedule Generator (Calc Engine Prerequisite)

- [ ] Implement paycheck date generator
  - Inputs: first_paycheck_date, pay_frequency, tax_year
  - Frequencies:
    - weekly
    - biweekly
    - semi-monthly (explicit rule: document it)
    - monthly
- [ ] Bonus handling
  - Bonus creates extra row if date in year
  - Merge if same date as paycheck
- [ ] Unit tests
  - Leap years
  - Late-year start
  - Same-day collisions

---

## 5) Contribution + Match Math (Core Engine)

- [ ] Define calculation data structures
  - Paycheck row
  - YTD trackers (per job, per spouse)
- [ ] Gross pay per paycheck
- [ ] Employee contribution calculation
  - Per bucket from slider %
  - Enforce employee deferral limit across jobs (per spouse)
- [ ] Employer match calculation
  - Match %
  - Salary cap %
  - True-up handling
- [ ] After-tax enforcement
  - `(TOTAL_401K_LIMIT - EMPLOYEE_DEFERRAL_LIMIT)`
  - Per spouse **per employer**
- [ ] Starting YTD offsets
  - Reduce remaining contribution room

---

## 6) Grouping + Aggregation

- [ ] Same-day paycheck grouping
  - Group rows by date
  - Sum all buckets
- [ ] Household totals
  - Per spouse totals
  - Combined totals
- [ ] Calculation API
  - `GET /households/:id/results`
  - Deterministic recompute from saved state

---

## 7) Validation & Warnings

- [ ] IRS over-contribution detection
  - Identify bucket + date
- [ ] Employer match loss detection
  - Missed match windows
  - Early cap exhaustion
- [ ] Warning schema
  - `severity: error | warning | info`
  - Metadata for UI placement

---

## 8) Frontend App Skeleton

- [ ] React project setup
- [ ] Routing
  - Home
  - Household flow
  - Results
- [ ] API client
  - Central error handling
- [ ] Home page
  - List households
  - Resume workflow

---

## 9) UI Flow + Real-Time Results

- [ ] Step 1: Household setup
  - Tax year from backend
- [ ] Step 2: Spouses
- [ ] Step 3: Jobs
- [ ] Step 4: Contribution sliders
- [ ] Auto-scroll step progression
- [ ] Debounced save + instant recalculation
- [ ] Charts + timeline tables
- [ ] Warning UI
  - Red background on errors
  - Banner for match loss risk

**Rule of thumb:**  
If something feels unclear, it belongs in `calculation_rules.md` before code is written.
