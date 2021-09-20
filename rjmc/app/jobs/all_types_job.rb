class AllTypesJob < RocketJob::Job
  field :hash_field, type: Hash, user_editable: true
  field :array, type: Array, user_editable: true
  field :string, type: String, user_editable: true
  field :string_values, type: String, user_editable: true
  field :integer, type: Integer, user_editable: true
  field :float, type: Float, user_editable: true
  field :symbol, type: Mongoid::StringifiedSymbol, user_editable: true
  field :boolean, type: Mongoid::Boolean, user_editable: true
  field :secure, type: String

  validates :string_values, inclusion: %w(one two three)

  def perform
  end
end
