# frozen_string_literal: true

# Job CRUD API Routes (nested under spouses)
class App < Sinatra::Base
  # GET /api/v1/spouses/:spouse_id/jobs
  # Returns all jobs for a spouse
  get '/api/v1/spouses/:spouse_id/jobs' do
    spouse = Spouse[params[:spouse_id]]
    halt 404, json(error: 'Spouse not found') unless spouse

    jobs = spouse.jobs_dataset.order(:id).all
    json(jobs: jobs.map(&:to_api_hash))
  end

  # GET /api/v1/jobs/:id
  # Returns a specific job with contribution settings
  get '/api/v1/jobs/:id' do
    job = Job[params[:id]]
    halt 404, json(error: 'Job not found') unless job

    job_hash = job.to_api_hash
    job_hash[:contribution_setting] = job.contribution_setting&.to_api_hash

    json(job_hash)
  end

  # POST /api/v1/spouses/:spouse_id/jobs
  # Creates a new job
  #
  # Request body:
  # {
  #   "employer_name": "Acme Corp",
  #   "first_paycheck_date": "2026-01-15",
  #   "pay_frequency": "biweekly",
  #   "base_salary": 12000000,
  #   "bonus_amount": 1000000,
  #   "bonus_date": "2026-12-15",
  #   "pretax_enabled": true,
  #   "roth_enabled": true,
  #   "aftertax_enabled": false,
  #   "mega_backdoor_allowed": false,
  #   "match_percent": 50.0,
  #   "match_cap_percent": 6.0,
  #   "true_up": false,
  #   "starting_ytd_pretax": 0,
  #   "starting_ytd_roth": 0,
  #   "starting_ytd_aftertax": 0,
  #   "starting_ytd_match": 0
  # }
  # rubocop:disable Metrics/BlockLength
  post '/api/v1/spouses/:spouse_id/jobs' do
    spouse = Spouse[params[:spouse_id]]
    halt 404, json(error: 'Spouse not found') unless spouse

    data = parse_json_body

    # Validate required fields
    required_fields = %w[employer_name first_paycheck_date pay_frequency base_salary]
    missing_fields = required_fields.reject { |field| data[field] }
    halt 400, json(error: "Missing required fields: #{missing_fields.join(', ')}") if missing_fields.any?

    job = Job.new(
      spouse_id: spouse.id,
      employer_name: data['employer_name'],
      first_paycheck_date: data['first_paycheck_date'],
      pay_frequency: data['pay_frequency'],
      base_salary: data['base_salary'],
      bonus_amount: data['bonus_amount'] || 0,
      bonus_date: data['bonus_date'],
      pretax_enabled: data.fetch('pretax_enabled', true),
      roth_enabled: data.fetch('roth_enabled', true),
      aftertax_enabled: data.fetch('aftertax_enabled', false),
      mega_backdoor_allowed: data.fetch('mega_backdoor_allowed', false),
      match_percent: data['match_percent'] || 0.0,
      match_cap_percent: data['match_cap_percent'] || 0.0,
      true_up: data.fetch('true_up', false),
      starting_ytd_pretax: data['starting_ytd_pretax'] || 0,
      starting_ytd_roth: data['starting_ytd_roth'] || 0,
      starting_ytd_aftertax: data['starting_ytd_aftertax'] || 0,
      starting_ytd_match: data['starting_ytd_match'] || 0
    )

    if job.valid?
      job.save
      status 201
      json(job.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: job.errors)
    end
  end
  # rubocop:enable Metrics/BlockLength

  # PUT /api/v1/jobs/:id
  # Updates an existing job
  put '/api/v1/jobs/:id' do
    job = Job[params[:id]]
    halt 404, json(error: 'Job not found') unless job

    data = parse_json_body

    # Update fields if provided
    update_fields = {}
    %w[
      employer_name first_paycheck_date pay_frequency base_salary bonus_amount bonus_date
      pretax_enabled roth_enabled aftertax_enabled mega_backdoor_allowed
      match_percent match_cap_percent true_up
      starting_ytd_pretax starting_ytd_roth starting_ytd_aftertax starting_ytd_match
    ].each do |field|
      update_fields[field.to_sym] = data[field] if data.key?(field)
    end

    job.update(update_fields) unless update_fields.empty?

    if job.valid?
      job.save
      json(job.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: job.errors)
    end
  end

  # DELETE /api/v1/jobs/:id
  # Deletes a job and all associated data
  delete '/api/v1/jobs/:id' do
    job = Job[params[:id]]
    halt 404, json(error: 'Job not found') unless job

    job.destroy
    status 204
  end
end
