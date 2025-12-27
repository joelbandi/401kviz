import React, { useMemo, useState } from 'react'

const LIMITS = {
  employee401k: 23000,
  hsaFamily: 8300,
  annualAdditions: 66000,
}

const jobTemplate = {
  name: 'Primary Job',
  grossPerPaycheck: 4000,
  frequency: 'biweekly',
  matchRate: 0.5,
  matchCapPct: 6,
  hsaEmployer: 50,
  allows: { traditional: true, roth: true, afterTax: true },
}

const frequencies = {
  weekly: 52,
  biweekly: 26,
  semimonthly: 24,
  monthly: 12,
}

function buildSchedule(firstDate, frequency) {
  const count = frequencies[frequency]
  const base = new Date(firstDate)
  return Array.from({ length: count }, (_, i) => {
    const d = new Date(base)
    const increment =
      frequency === 'weekly'
        ? 7
        : frequency === 'biweekly'
          ? 14
          : frequency === 'semimonthly'
            ? 15
            : 30
    d.setDate(base.getDate() + i * increment)
    return d
  }).filter((d) => d.getFullYear() === 2026)
}

function formatCurrency(amount) {
  return amount.toLocaleString('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 })
}

function estimateTaxes(taxable, paychecksPerYear) {
  const annual = taxable * paychecksPerYear
  const standardDeduction = 30700
  const bracket = [
    [23200, 0.1],
    [94300, 0.12],
    [201050, 0.22],
    [383900, 0.24],
  ]

  let remaining = Math.max(annual - standardDeduction, 0)
  let tax = 0
  let last = 0
  for (const [limit, rate] of bracket) {
    const span = Math.min(Math.max(limit - last, 0), remaining)
    tax += span * rate
    remaining -= span
    last = limit
  }
  if (remaining > 0) tax += remaining * 0.32
  return tax / paychecksPerYear
}

function App() {
  const [hsaPct, setHsaPct] = useState(5)
  const [traditionalPct, setTraditionalPct] = useState(10)
  const [rothPct, setRothPct] = useState(5)
  const [afterTaxPct, setAfterTaxPct] = useState(0)

  const job = jobTemplate
  const paychecksPerYear = frequencies[job.frequency]

  const schedule = useMemo(() => buildSchedule('2026-01-05', job.frequency), [job.frequency])

  const ledger = useMemo(() => {
    let ytd401k = 0
    let ytdHsa = 0
    let ytdMatch = 0
    return schedule.map((date) => {
      const gross = job.grossPerPaycheck
      const employeeTraditional = (traditionalPct / 100) * gross
      const employeeRoth = (rothPct / 100) * gross
      const employeeAfterTax = (afterTaxPct / 100) * gross
      const employeeHsa = (hsaPct / 100) * gross
      const matchable = Math.min((job.matchCapPct / 100) * gross, employeeTraditional + employeeRoth)
      const employerMatch = matchable * job.matchRate
      const taxable = gross - employeeTraditional - employeeHsa
      const federalTax = estimateTaxes(taxable, paychecksPerYear)
      const stateTax = estimateTaxes(taxable, paychecksPerYear) * 0.5
      const net =
        gross - employeeTraditional - employeeRoth - employeeAfterTax - employeeHsa - employerMatch * 0 + federalTax * -1 + stateTax * -1

      ytd401k += employeeTraditional + employeeRoth + employeeAfterTax
      ytdHsa += employeeHsa + job.hsaEmployer
      ytdMatch += employerMatch

      return {
        date: date.toISOString().slice(0, 10),
        gross,
        employeeTraditional,
        employeeRoth,
        employeeAfterTax,
        employeeHsa,
        employerMatch,
        employerHsa: job.hsaEmployer,
        federalTax,
        stateTax,
        net,
        ytd401k,
        ytdHsa,
        ytdMatch,
      }
    })
  }, [afterTaxPct, hsaPct, job.grossPerPaycheck, job.hsaEmployer, job.matchCapPct, job.matchRate, paychecksPerYear, rothPct, schedule, traditionalPct])

  const totals = useMemo(
    () =>
      ledger.reduce(
        (acc, p) => {
          acc.gross += p.gross
          acc.taxes += p.federalTax + p.stateTax
          acc.traditional += p.employeeTraditional
          acc.roth += p.employeeRoth
          acc.afterTax += p.employeeAfterTax
          acc.hsa += p.employeeHsa
          acc.match += p.employerMatch
          acc.employerHsa += p.employerHsa
          acc.net += p.net
          return acc
        },
        { gross: 0, taxes: 0, traditional: 0, roth: 0, afterTax: 0, hsa: 0, match: 0, employerHsa: 0, net: 0 }
      ),
    [ledger]
  )

  const warnings = []
  if (totals.traditional + totals.roth > LIMITS.employee401k) warnings.push('Employee 401(k) limit exceeded')
  if (totals.hsa + totals.employerHsa > LIMITS.hsaFamily) warnings.push('HSA family limit exceeded')

  return (
    <>
      <header>
        <h1>2026 Household Retirement & Tax Optimization Visualizer</h1>
        <p>California · Married Filing Jointly · HSA Family Coverage</p>
      </header>
      <main>
        <section>
          <div className="badge">2026 limits</div>
          <div className="badge">Employee 401(k): {formatCurrency(LIMITS.employee401k)}</div>
          <div className="badge">HSA Family: {formatCurrency(LIMITS.hsaFamily)}</div>
        </section>

        <section>
          <h2>Manual Strategy</h2>
          <div className="slider-row">
            <label htmlFor="hsa">HSA %</label>
            <input id="hsa" type="range" min="0" max="20" value={hsaPct} onChange={(e) => setHsaPct(Number(e.target.value))} />
            <span>{hsaPct}%</span>
          </div>
          <div className="slider-row">
            <label htmlFor="traditional">Traditional 401(k) %</label>
            <input
              id="traditional"
              type="range"
              min="0"
              max="50"
              value={traditionalPct}
              onChange={(e) => setTraditionalPct(Number(e.target.value))}
            />
            <span>{traditionalPct}%</span>
          </div>
          <div className="slider-row">
            <label htmlFor="roth">Roth 401(k) %</label>
            <input id="roth" type="range" min="0" max="50" value={rothPct} onChange={(e) => setRothPct(Number(e.target.value))} />
            <span>{rothPct}%</span>
          </div>
          <div className="slider-row">
            <label htmlFor="aftertax">After-tax 401(k) %</label>
            <input
              id="aftertax"
              type="range"
              min="0"
              max="50"
              value={afterTaxPct}
              onChange={(e) => setAfterTaxPct(Number(e.target.value))}
            />
            <span>{afterTaxPct}%</span>
          </div>
        </section>

        <section className="grid">
          <div>
            <h3>Contribution Totals</h3>
            <p>Gross: {formatCurrency(totals.gross)}</p>
            <p>Taxes (est.): {formatCurrency(totals.taxes)}</p>
            <p>Traditional 401(k): {formatCurrency(totals.traditional)}</p>
            <p>Roth 401(k): {formatCurrency(totals.roth)}</p>
            <p>After-tax 401(k): {formatCurrency(totals.afterTax)}</p>
            <p>HSA Employee: {formatCurrency(totals.hsa)}</p>
            <p>Employer Match: {formatCurrency(totals.match)}</p>
            <p>Net Cash: {formatCurrency(totals.net)}</p>
            {warnings.length > 0 && (
              <div style={{ color: '#b91c1c' }}>
                <strong>Warnings:</strong>
                <ul>
                  {warnings.map((w) => (
                    <li key={w}>{w}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
          <div>
            <h3>Limit Timelines</h3>
            <p>
              Employee 401(k): {formatCurrency(totals.traditional + totals.roth)} / {formatCurrency(LIMITS.employee401k)}
            </p>
            <p>
              HSA: {formatCurrency(totals.hsa + totals.employerHsa)} / {formatCurrency(LIMITS.hsaFamily)}
            </p>
            <p>Employer additions: {formatCurrency(totals.match)} / {formatCurrency(LIMITS.annualAdditions)}</p>
          </div>
        </section>

        <section>
          <h2>Paycheck Table</h2>
          <table className="table">
            <thead>
              <tr>
                <th>Date</th>
                <th>Gross</th>
                <th>Traditional</th>
                <th>Roth</th>
                <th>After-tax</th>
                <th>HSA</th>
                <th>Match</th>
                <th>HSA (ER)</th>
                <th>Fed Tax</th>
                <th>CA Tax</th>
                <th>Net</th>
                <th>YTD 401(k)</th>
                <th>YTD HSA</th>
              </tr>
            </thead>
            <tbody>
              {ledger.slice(0, 10).map((row) => (
                <tr key={row.date}>
                  <td>{row.date}</td>
                  <td>{formatCurrency(row.gross)}</td>
                  <td>{formatCurrency(row.employeeTraditional)}</td>
                  <td>{formatCurrency(row.employeeRoth)}</td>
                  <td>{formatCurrency(row.employeeAfterTax)}</td>
                  <td>{formatCurrency(row.employeeHsa)}</td>
                  <td>{formatCurrency(row.employerMatch)}</td>
                  <td>{formatCurrency(row.employerHsa)}</td>
                  <td>{formatCurrency(row.federalTax)}</td>
                  <td>{formatCurrency(row.stateTax)}</td>
                  <td>{formatCurrency(row.net)}</td>
                  <td>{formatCurrency(row.ytd401k)}</td>
                  <td>{formatCurrency(row.ytdHsa)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p style={{ fontSize: '0.9rem' }}>Showing first 10 of {ledger.length} paychecks. Sliders update the table immediately.</p>
        </section>
      </main>
    </>
  )
}

export default App
