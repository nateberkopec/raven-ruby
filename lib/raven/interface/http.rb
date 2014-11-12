module Raven
  class Interface::Http < Struct.new(:url, :method, :data, :query_string, :cookies, :headers, :env)
    def self.name; 'request'; end
  end

  register_interface :http => Interface::Http
end
