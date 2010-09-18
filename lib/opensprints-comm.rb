class MockFirmware
  def initialize()
    @output_stream ||= []
  end

  def self.open(file, mode)
    @@mock ||= self.new()
  end

  def readline
    @output_stream.pop
  end

  def write(command)
    if command =~ /^!a:/
      number = get_parameter(command)
      if number.to_i >= 2**16
        @output_stream << "A:NACK\r\n"
      else
        @output_stream << "A:#{number}\r\n"
      end
    else
      @output_stream << "NACK\r\n"
    end
  end

  def close

  end

  def flush

  end

  def get_parameter(command)
    command.gsub(/.*:(.*)\r\n/,'\1')
  end
end
