#!/usr/bin/env ruby
# frozen_string_literal: true

file = ARGV[0]
report = File.read(file)

# OSX stack traces look like sample.crash
# we want to test for presence of com.binaryage.* anywhere on the stack
#   we extract all com.binaryage.* ranges from "Binary Images" section
#   and also all addresses on all callstacks
#   then test if any of addresses hit some of our ranges

addresses = []
ranges = []

report.lines.each do |line|
  # extract addresses from callstacks on all threads
  # 8   com.apple.AppKit        	0x00007fff88a0d68f -[NSApplication run] + 395
  addresses << Regexp.last_match(1).to_i(16) if line =~ /^\s*\d+\s+.*?0x([0-9a-f]+)\s/

  # extract loaded module ranges, filter out only com.binaryage related
  # 0x1181c2000 -    0x1181c3ff7 +com.binaryage.totalfinder.nodesktopdots ##VERSION## (##VERSION##) <...> /some/path
  if line =~ /^\s*0x([0-9a-f]+)\s+-\s+0x([0-9a-f]+)\s+.*?com\.binaryage/
    ranges << [Regexp.last_match(1).to_i(16), Regexp.last_match(2).to_i(16)]
  end
end

# test if any address is present inside our ranges
addresses.each do |address|
  ranges.each do |range|
    hit = address >= range[0] && address <= range[1]
    # puts "#{address} ? #{range[0]} - #{range[1]} => #{hit}"
    exit 3 if hit # yes, present!
  end
end

exit 0 # not present
