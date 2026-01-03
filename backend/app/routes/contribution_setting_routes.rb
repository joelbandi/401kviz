# frozen_string_literal: true

# ContributionSetting CRUD API Routes (nested under jobs)
class App < Sinatra::Base
  # GET /api/v1/jobs/:job_id/contribution_setting
  # Returns contribution settings for a job
  get '/api/v1/jobs/:job_id/contribution_setting' do
    job = Job[params[:job_id]]
    halt 404, json(error: 'Job not found') unless job

    setting = job.contribution_setting
    if setting
      json(setting.to_api_hash)
    else
      halt 404, json(error: 'Contribution setting not found')
    end
  end

  # POST /api/v1/jobs/:job_id/contribution_setting
  # Creates contribution settings for a job
  #
  # Request body:
  # {
  #   "pretax_pct": 10.0,
  #   "roth_pct": 5.0,
  #   "aftertax_pct": 0.0
  # }
  post '/api/v1/jobs/:job_id/contribution_setting' do
    job = Job[params[:job_id]]
    halt 404, json(error: 'Job not found') unless job

    # Check if contribution setting already exists
    halt 400, json(error: 'Contribution setting already exists for this job') if job.contribution_setting

    data = parse_json_body

    setting = ContributionSetting.new(
      job_id: job.id,
      pretax_pct: data['pretax_pct'] || 0.0,
      roth_pct: data['roth_pct'] || 0.0,
      aftertax_pct: data['aftertax_pct'] || 0.0
    )

    if setting.valid?
      setting.save
      status 201
      json(setting.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: setting.errors)
    end
  end

  # PUT /api/v1/jobs/:job_id/contribution_setting
  # Updates contribution settings for a job
  put '/api/v1/jobs/:job_id/contribution_setting' do
    job = Job[params[:job_id]]
    halt 404, json(error: 'Job not found') unless job

    setting = job.contribution_setting
    halt 404, json(error: 'Contribution setting not found') unless setting

    data = parse_json_body

    setting.update(
      pretax_pct: data.key?('pretax_pct') ? data['pretax_pct'] : setting.pretax_pct,
      roth_pct: data.key?('roth_pct') ? data['roth_pct'] : setting.roth_pct,
      aftertax_pct: data.key?('aftertax_pct') ? data['aftertax_pct'] : setting.aftertax_pct
    )

    if setting.valid?
      setting.save
      json(setting.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: setting.errors)
    end
  end

  # DELETE /api/v1/jobs/:job_id/contribution_setting
  # Deletes contribution settings for a job
  delete '/api/v1/jobs/:job_id/contribution_setting' do
    job = Job[params[:job_id]]
    halt 404, json(error: 'Job not found') unless job

    setting = job.contribution_setting
    halt 404, json(error: 'Contribution setting not found') unless setting

    setting.destroy
    status 204
  end
end
