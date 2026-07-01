# A simple job with a variety of user editable fields.
#
# Demonstrates the edit/new forms with strings, arrays, and multi-select fields.
class EmailBlastJob < RocketJob::Job
  self.description = "Send a marketing email blast to a customer segment"
  self.priority    = 40

  field :subject,    type: String, user_editable: true
  field :body,       type: String, user_editable: true
  field :segment,    type: String, user_editable: true
  field :recipients, type: Array,  default: [], user_editable: true

  validates :segment, inclusion: %w[new active lapsed vip]

  def perform
    # Pretend to send emails.
  end
end
