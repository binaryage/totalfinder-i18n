#!/usr/bin/env ruby

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

    # extract adressess from callstacks on all threads
    # 8   com.apple.AppKit              	0x00007fff88a0d68f -[NSApplication run] + 395
    if line =~ /^\s*\d+\s+.*?0x([0-9a-f]+)\s/ then
        addresses << $1.to_i(16)
    end
    
    # extract loaded module ranges, filter out only com.binaryage related
    # 0x1181c2000 -        0x1181c3ff7 +com.binaryage.totalfinder.nodesktopdots ##VERSION## (##VERSION##) <1243063C-4405-3DD6-8AC8-816EFA979801> /Applications/TotalFinder.app/Contents/Resources/TotalFinder.bundle/Contents/PlugIns/NoDesktopDots.bundle/Contents/MacOS/NoDesktopDots
    if line =~ /^\s*0x([0-9a-f]+)\s+-\s+0x([0-9a-f]+)\s+.*?com\.binaryage/ then
        ranges << [$1.to_i(16), $2.to_i(16)]
    end
    
end

# test if any address is present inside our ranges
addresses.each do |address|
    ranges.each do |range|
        hit = address >= range[0] && address <= range[1]
        exit 1 if hit # yes, present!
        # puts "#{address} ? #{range[0]} - #{range[1]} => #{hit}"
    end
end

exit 0 # not present