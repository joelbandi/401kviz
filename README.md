# 401k Visualizer

A web-based planning tool for married households with multiple variable W-2 jobs to **visualize, simulate, and optimize** retirement and tax-advantaged savings strategies.

## Features

- **401(k) Planning**: Support for pre-tax, Roth, and after-tax 401(k) contributions
- **Paycheck-Level Calculation**: Detailed breakdown of every paycheck throughout the year
- **Interactive Visualization**: Timeline view of contributions, milestones and totals
- **Multi-Job Support**: Handle multiple concurrent or sequential jobs per spouse
- **Household Management**: View, edit, and manage multiple household scenarios (for comparing different plans/handling different years)
- **Full CRUD API**: Complete REST API for creating, reading, updating, and deleting households, spouses, jobs, and contribution numbers.

## Technology Stack

- **Backend**: Ruby with Sinatra web framework (RESTful API)
- **Database**: SQLite with Sequel ORM
- **Frontend**: React with MUI framework & charts component (https://mui.com/)

## Tool Chains

- Ruby 3.4 or higher
- NodeJS v22.14.0

## App workflow

This is going to be a multi step flow where each step form when completed, the UI scrolls down and the next step is created. Any workflows abandoned can be resumed from the home page which lists all the households.

### Step 1: Create new Household and household Setup

- Name of household
- Select your tax year (default: upcoming year 2026). ONLY list values that we have env file for. (read more below)
- Tax filing status (defaults to married filing jointly)
- state of residency (defaults to california)

### Step 2: Add Spouses

- Add both spouses with their names
- Each spouse can have multiple jobs

### Step 3: Add Jobs

For each job, enter:

- Employer name
- First paycheck date
- Pay frequency (weekly, biweekly, semi-monthly, monthly)
- Base salary
- Bonus amount and payout date (optional)

**Retirement Plan Details:**

- Check which 401(k) types are available (pre-tax, Roth, after-tax)
- Indicate if mega backdoor Roth is allowed
- Enter employer match details:
  - Match percentage (e.g., 50 for 50% match)
  - Match salary cap (e.g., 6 for matching up to 6% of salary)
  - Whether there's an annual true-up
  - Current amount in each bucket already contributed.

### Step 4: Set Contributions

- Use sliders to adjust contribution percentages for each job
- Set different percentages for pre-tax, Roth, and after-tax contributions
- The results should auto update when sliders are changed at all

## Results

### Paycheck Calculation Engine

Calculates for every paycheck:

- paycheck date
- Gross pay
- Employee contributions (401(k) by bucket (pre tax, roth, after tax 401k))
- Employer contributions (pre tax match)
- YTD Employee contributions
- YTD Employer contributions
- Total pre tax contributions across jobs
- Total after tax contributions across jobs
- Total Roth contributions across jobs

If two paychecks fall on the same day THEN rows must be grouped by paycheck date and also totals pre, post and roth contributions.

### Contribution Limits (2026)

- pre tax 401(k) employee deferral: $24,500
- Total 401k contribution: $72,000
- the pre tax deferral limits are across all jobs per person
- the non pre tax limit (72000 - 24500) is per person per employer.

All of these variables must be in a separate file called irs_data/2026.env. In case i need to change values later i just need to edit this file ONLY. I can also simply add new env files like 2027 to start supporting 2027 year planning.

### Validation & Warnings

The system warns you about:

- IRS over-contribution risks
- Employer match loss risks

The whole background page turns red to warn over contribution. Add a big warning banner on top of the slider if match loss risk
