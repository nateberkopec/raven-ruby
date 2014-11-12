module Raven
  class Interface::Exception < Struct.new(:type, :value, :module, :stacktrace)
    def self.name; 'exception'; end
  end

  register_interface :exception => Interface::Exception
end
