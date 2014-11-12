module Raven
  class Interface::Stacktrace

    attr_accessor :frames

    def self.name
      'stacktrace'
    end

    def frame(&block)
      self.frames ||= []
      new_frame = Frame.new
      yield new_frame
      frames << new_frame
    end

    class Frame < Struct.new(:abs_path, :function, :vars, :pre_context, :post_context, :context_line, :lineno, :in_app)

      def filename
        return nil if self.abs_path.nil?

        prefix = $LOAD_PATH.select { |s| self.abs_path.start_with?(s.to_s) }.sort_by { |s| s.to_s.length }.last
        prefix ? self.abs_path[prefix.to_s.chomp(File::SEPARATOR).length+1..-1] : self.abs_path
      end
    end
  end

  register_interface :stack_trace => Interface::Stacktrace
end
