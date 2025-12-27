# 401kViz

This project implements a prototype for the 2026 Household Retirement & Tax Optimization Visualizer described in the PRD.

## Structure
- `backend/` Ruby domain layer with calculators, 2026 limits, and RSpec tests.
- `frontend/` React (Vite) UI that keeps sliders and paycheck data in sync on each interaction.

## Quickstart

### Frontend
```
cd frontend
npm install
npm run dev
```

### Backend
```
cd backend
bundle install
bundle exec rspec
```
