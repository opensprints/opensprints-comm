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
    elsif command =~ /^!l:/
      number = get_parameter(command)
      if number.to_i >= 2**16
        @output_stream << "L:NACK\r\n"
      else
        @output_stream << "L:#{number}\r\n"
      end
    elsif command =~ /^!t:/
      number = get_parameter(command)
      if number.to_i >= 2**16
        @output_stream << "T:NACK\r\n"
      else
        @output_stream << "T:#{number}\r\n"
      end
    elsif command =~ /^!c:/
      number = get_parameter(command)
      if (0 > number.to_i) 
        @output_stream << "NACK\r\n"
      elsif (number.to_i >= 2**8)
        @output_stream << "C:NACK\r\n"
      else
        @output_stream << "C:#{number}\r\n"
      end
    elsif command =~ /^!g\W$/
      @output_stream << "G\r\n"
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
