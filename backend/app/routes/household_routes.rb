# frozen_string_literal: true

# Household CRUD API Routes
class App < Sinatra::Base
  # GET /api/v1/households
  # Returns list of all households
  get '/api/v1/households' do
    households = Household.order(Sequel.desc(:updated_at)).all
    json(households: households.map(&:to_api_hash))
  end

  # GET /api/v1/households/:id
  # Returns a specific household with nested spouses
  get '/api/v1/households/:id' do
    household = Household[params[:id]]
    halt 404, json(error: 'Household not found') unless household

    household_hash = household.to_api_hash
    household_hash[:spouses] = household.spouses.map(&:to_api_hash)

    json(household_hash)
  end

  # POST /api/v1/households
  # Creates a new household
  #
  # Request body:
  # {
  #   "name": "Smith Family",
  #   "tax_year": 2026,
  #   "filing_status": "married_filing_jointly",
  #   "state": "CA"
  # }
  post '/api/v1/households' do
    data = parse_json_body

    # Validate required fields
    required_fields = %w[name tax_year filing_status]
    missing_fields = required_fields.reject { |field| data[field] }
    halt 400, json(error: "Missing required fields: #{missing_fields.join(', ')}") if missing_fields.any?

    household = Household.new(
      name: data['name'],
      tax_year: data['tax_year'],
      filing_status: data['filing_status'],
      state: data['state'],
      status: 'draft'
    )

    if household.valid?
      household.save
      status 201
      json(household.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: household.errors)
    end
  end

  # PUT /api/v1/households/:id
  # Updates an existing household
  put '/api/v1/households/:id' do
    household = Household[params[:id]]
    halt 404, json(error: 'Household not found') unless household

    data = parse_json_body

    household.update(
      name: data['name'] || household.name,
      tax_year: data['tax_year'] || household.tax_year,
      filing_status: data['filing_status'] || household.filing_status,
      state: data['state'].nil? ? household.state : data['state'],
      status: data['status'] || household.status
    )

    if household.valid?
      household.save
      json(household.to_api_hash)
    else
      halt 400, json(error: 'Validation failed', details: household.errors)
    end
  end

  # DELETE /api/v1/households/:id
  # Deletes a household and all associated data
  delete '/api/v1/households/:id' do
    household = Household[params[:id]]
    halt 404, json(error: 'Household not found') unless household

    household.destroy
    status 204
  end
end
