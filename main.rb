#!/usr/bin/env ruby

require 'unimidi'
require 'byebug'

# Initialize!
INPUT = UniMIDI::Input.gets
OUTPUT = UniMIDI::Output.gets

class Fixnum
  def to_bin(width = 8)
    to_s(2).rjust(width, '0')
  end
end

def parse_compound_message(message)
  message.each_slice(3).to_a
end

def process_data(data)
  status_byte = data.first
  status_byte_bin = status_byte.to_bin

  # Note On Event: 1001 binary, 9 in decimal
  if /^1001/.match? status_byte_bin
    puts "- Note on: #{status_byte_bin}"
    puts "Pitch: #{data[1]}"

    OUTPUT.puts(0x90, data[1], 100) # pay forward Note On event
  end

  # Note Off Event: 1000 binary, 8 in decimal
  if /^1000/.match? status_byte_bin
    puts "- Note off: #{status_byte_bin}"

    OUTPUT.puts(0x80, data[1], 100) # pay forward Note Off event
  end
end

puts 'Send some MIDI messages now...'

loop do
  sleep 0.00001 # WTF: Avoid big latency issues

  messages = INPUT.gets

  next if messages.empty?

  messages.each do |message|
    data = message[:data]

    if data.count > 3
      # Buffered messages will be returned in the same array
      # E.g. [144, 60, 100, 128, 60, 100, 144, 40, 120]
      # Which consists of three messages
      parse_compound_message(data).each { |data| process_data(data) }
    else
      process_data(data)
    end
  end
end


