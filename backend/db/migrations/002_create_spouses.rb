# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:spouses) do
      primary_key :id
      foreign_key :household_id, :households, null: false, on_delete: :cascade
      String :name, null: false
      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      index :household_id
    end
  end
end
