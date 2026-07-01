# A batch job that reads a CSV file, normalizes each record, and collects the
# transformed output.
#
# Demonstrates the batch input/output categories, slices, and output views.
class DataImportJob < RocketJob::Job
  include RocketJob::Batch

  self.description         = "Import customer records and normalize them"
  self.destroy_on_complete = false

  input_category  format: :csv
  output_category format: :csv

  field :region, type: String, default: "us-east", user_editable: true

  def perform(record)
    record["name"]  = record["name"].to_s.strip.upcase
    record["state"] = record["state"].to_s.strip.upcase
    record
  end
end
