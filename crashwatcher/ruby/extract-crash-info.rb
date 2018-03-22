#!/usr/bin/env ruby
# frozen_string_literal: true

def parse_module_version(content)
  m = content.match(/\+\s*com.binaryage.totalfinder\s*\((.*?)\)/m)
  return nil if m.nil?
  # m[1] == 1.5.18 - 1.5.18
  m[1].split('-')[0].strip
end

def parse_special_info(content)
  # "recent swizzled method" can appear in TotalFinder crash logs since v1.4.18
  m = content.match(/recent swizzled method:(.*?)\n/m)
  return nil if m.nil?
  m[1].strip
end

def parse_plugin_identifier(content)
  m = content.match(/PlugIn Identifier:(.*?)\n/m)
  return nil if m.nil?
  m[1]
end

def find_first_ba_module(content)
  addresses = []
  ranges = []

  content.lines.each do |line|
    # extract addresses from callstacks on all threads
    # 8   com.apple.AppKit        	0x00007fff88a0d68f -[NSApplication run] + 395
    addresses << Regexp.last_match(1).to_i(16) if line =~ /^\s*\d+\s+.*?0x([0-9a-f]+)\s/

    # extract loaded module ranges, filter out only com.binaryage related
    # 0x1181c2000 -    0x1181c3ff7 +com.binaryage.totalfinder.nodesktopdots ##VERSION## (##VERSION##) <...> /some/path
    if line.match?(/^\s*0x([0-9a-f]+)\s+-\s+0x([0-9a-f]+)\s+.*?(com\.binaryage.*?)\s/)
      ranges << [Regexp.last_match(1).to_i(16), Regexp.last_match(2).to_i(16), Regexp.last_match(3)]
    end
  end

  # test if any address is present inside our ranges
  addresses.each do |address|
    ranges.each do |range|
      hit = address >= range[0] && address <= range[1]
      return range[2] if hit
    end
  end
end

file = ARGV[0]
content = File.read(file)

res = 'TotalFinder '

module_version = parse_module_version(content)
res += "#{module_version} " if module_version
plugin = parse_special_info(content)
plugin ||= parse_plugin_identifier(content)
plugin ||= find_first_ba_module(content)
plugin.strip!
res += 'crashed in ' + plugin.gsub('com.binaryage.totalfinder.', '') + ' ' if plugin.size

details = []

version = content.match(/Version:(.*?)\n/m)[1].split(' ')[0]
details << 'v' + version.strip

version = content.match(/OS Version:.*?\((.*?)\)\n/m)[1]
details << 'OS ' + version.strip

type = content.match(/Exception Type:(.*?)\n/m)[1]
x = type.match(/(.*?)\(.*\)/)
type = x[1] if x # remove braced part if present
type.downcase!
type.sub!('exc_', '')
type.sub!('_', ' ')
details << type.strip

thread = content.match(/Crashed Thread:(.*?)\n/m)[1].split(' ')[0]
details << 'thread ' + thread.strip

res += "| #{details.join(', ')}"

puts res
