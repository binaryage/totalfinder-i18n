#!/usr/bin/env ruby

def parse_module_version(content)
  m = content.match(/\+\s*com.binaryage.totalfinder\s*\((.*?)\)/m)
  return nil if m.nil?
  # m[1] == 1.5.18 - 1.5.18
  m[1].split("-")[0].strip
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
    # extract adressess from callstacks on all threads
    # 8   com.apple.AppKit        	0x00007fff88a0d68f -[NSApplication run] + 395
    if line =~ /^\s*\d+\s+.*?0x([0-9a-f]+)\s/ then
      addresses << $1.to_i(16)
    end

    # extract loaded module ranges, filter out only com.binaryage related
    # 0x1181c2000 -    0x1181c3ff7 +com.binaryage.totalfinder.nodesktopdots ##VERSION## (##VERSION##) <1243063C-4405-3DD6-8AC8-816EFA979801> /Applications/TotalFinder.app/Contents/Resources/TotalFinder.bundle/Contents/PlugIns/NoDesktopDots.bundle/Contents/MacOS/NoDesktopDots
    if line =~ /^\s*0x([0-9a-f]+)\s+-\s+0x([0-9a-f]+)\s+.*?(com\.binaryage.*?)\s/ then
      ranges << [$1.to_i(16), $2.to_i(16), $3]
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

res = "TotalFinder "

begin
  mversion = parse_module_version(content)
  res += "#{mversion} " if mversion
  plugin = parse_special_info(content)
  plugin = parse_plugin_identifier(content) unless plugin
  plugin = find_first_ba_module(content) unless plugin
  plugin.strip!
  res += "crashed in " + plugin.gsub("com.binaryage.totalfinder.", "") + " " if plugin.size
rescue
end

details = []

begin
  version = content.match(/Version:(.*?)\n/m)[1].split(" ")[0]
  details << "v"+version.strip
rescue
end

begin
  version = content.match(/OS Version:.*?\((.*?)\)\n/m)[1]
  details << "OS "+version.strip
rescue
end

begin
  type = content.match(/Exception Type:(.*?)\n/m)[1]
  x = type.match(/(.*?)\(.*\)/)
  type = x[1] if x # remove braced part if present
  type.downcase!
  type.sub!("exc_", "")
  type.sub!("_", " ")
  details << type.strip
rescue
end

begin
  thread = content.match(/Crashed Thread:(.*?)\n/m)[1].split(" ")[0]
  details << "thread "+thread.strip
rescue
end

res += "| #{details.join(", ")}"

puts res