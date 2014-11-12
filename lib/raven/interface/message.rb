module Raven
  class Interface::Message < Struct.new(:message, :params)
    def self.name; 'sentry.interfaces.Message'; end
  end

  register_interface :message => Interface::Message
end
