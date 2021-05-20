# Upload a CSV file and return the uploaded data as-is for now.
#
# Example, use slice size to create more input slices for testing:
# job = CSVJob.new
# job.input_category.slice_size = 1
# job.upload('myfile.csv')
# job.save!
#
# Example, manually upload csv formatted data.
# job = CSVJob.new
# job.input_category.slice_size = 1
# job.upload do |stream|
#   # Write header row.
#   stream << "name,age,state"
#
#   # Write 10 lines.
#   10.times { |i| stream << "jack,#{i+20},FL" }
# end
# job.save!
class CSVJob < RocketJob::Job
  include RocketJob::Batch

  input_category format: :csv

  field :optional, type: String, user_editable: true

  self.destroy_on_complete = false

  def perform(record)
    record
  end
end
