# frozen_string_literal: true

# Spouse CRUD API Routes (nested under households)
class App < Sinatra::Base
  # GET /api/v1/households/:household_id/spouses
  # Returns all spouses for a household
  get '/api/v1/households/:household_id/spouses' do
    household = Household[params[:household_id]]
    halt 404, json(error: 'Household not found') unless household

    spouses = household.spouses_dataset.order(:id).all
    json(spouses: spouses.map(&:to_api_hash))
  end

  # GET /api/v1/spouses/:id
  # Returns a specific spouse with nested jobs
  get '/api/v1/spouses/:id' do
    spouse = Spouse[params[:id]]
    halt 404, json(error: 'Spouse not found') unless spouse

    spouse_hash = spouse.to_api_hash
    spouse_hash[:jobs] = spouse.jobs_dataset.all.map(&:to_api_hash)

    json(spouse_hash)
  end

  # POST /api/v1/households/:household_id/spouses
  # Creates a new spouse
  #
  # Request body:
  # {
  #   "name": "John Smith"
  # }
  post '/api/v1/households/:household_id/spouses' do
    household = Household[params[:household_id]]
    halt 404, json(error: 'Household not found') unless household

    data = parse_json_body

    # Validate required fields
    halt 400, json(error: 'Missing required field: name') unless data['name']

    spouse = Spouse.new(
      household_id: household.id,
      name: data['name']
    )

    if spouse.valid?
      spouse.save
      status 201
      json(spouse.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: spouse.errors)
    end
  end

  # PUT /api/v1/spouses/:id
  # Updates an existing spouse
  put '/api/v1/spouses/:id' do
    spouse = Spouse[params[:id]]
    halt 404, json(error: 'Spouse not found') unless spouse

    data = parse_json_body

    spouse.update(
      name: data['name'] || spouse.name
    )

    if spouse.valid?
      spouse.save
      json(spouse.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: spouse.errors)
    end
  end

  # DELETE /api/v1/spouses/:id
  # Deletes a spouse and all associated data
  delete '/api/v1/spouses/:id' do
    spouse = Spouse[params[:id]]
    halt 404, json(error: 'Spouse not found') unless spouse

    spouse.destroy
    status 204
  end
end
