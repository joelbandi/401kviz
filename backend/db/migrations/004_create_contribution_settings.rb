# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:contribution_settings) do
      primary_key :id
      foreign_key :job_id, :jobs, null: false, on_delete: :cascade, unique: true

      # Contribution percentages (0-100)
      Float :pretax_pct, null: false, default: 0.0
      Float :roth_pct, null: false, default: 0.0
      Float :aftertax_pct, null: false, default: 0.0

      DateTime :created_at, null: false
      DateTime :updated_at, null: false

      # Ensure percentages are in valid range
      constraint(:valid_pretax_pct) { (pretax_pct >= 0) & (pretax_pct <= 100) }
      constraint(:valid_roth_pct) { (roth_pct >= 0) & (roth_pct <= 100) }
      constraint(:valid_aftertax_pct) { (aftertax_pct >= 0) & (aftertax_pct <= 100) }
      constraint(:valid_total_pct) { (pretax_pct + roth_pct + aftertax_pct <= 100) }

      index :job_id
    end
  end
end
