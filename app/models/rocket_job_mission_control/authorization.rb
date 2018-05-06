module RocketJobMissionControl
  class Authorization
    ROLES = %i[admin editor operator manager dirmon user view]
    attr_accessor *ROLES
    attr_accessor :login


    def initialize(roles: [], login: nil)
      @login = login
      return if roles.blank?
      invalid_roles = roles - ROLES
      raise(ArgumentError, "Invalid Roles Supplied: #{invalid_roles.inspect}") unless invalid_roles.empty?

      roles.each { |role| public_send("#{role}=", true) }
    end
  end
end