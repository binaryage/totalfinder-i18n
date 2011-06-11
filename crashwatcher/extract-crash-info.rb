#!/usr/bin/env ruby

file = ARGV[0]
content = File.read(file)

res = ""

begin
    plugin = content.match(/PlugIn Identifier:(.*?)\n/m)[1]
    res += "in " + plugin.strip + " "
    rescue
end

begin
    type = content.match(/Exception Type:(.*?)\n/m)[1]
    x = type.match(/(.*?)\(.*\)/)
    type = x[1] if x # remove braced part if present
    res += type.strip + " "
rescue
end

begin
    thread = content.match(/Crashed Thread:(.*?)\n/m)[1].split(" ")[0]
    res += "(T"+thread.strip+") "
    rescue
end

puts res