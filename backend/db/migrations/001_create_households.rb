# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:households) do
      primary_key :id
      String :name, null: false
      Integer :tax_year, null: false
      String :filing_status, null: false
      String :state, size: 2 # Two-letter state code
      String :status, null: false, default: 'draft' # draft, in_progress, complete
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :tax_year
      index :status
    end
  end
end
