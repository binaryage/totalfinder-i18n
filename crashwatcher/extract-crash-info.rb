#!/usr/bin/env ruby

file = ARGV[0]
content = File.read(file)

res = ""

begin
    plugin = content.match(/PlugIn Identifier:(.*?)\n/m)[1]
    res += "in " + plugin.strip + " "
rescue
end

details = []

begin
    version = content.match(/Version:(.*?)\n/m)[1].split(" ")[0]
    details << "v"+version.strip
rescue
end

begin
    thread = content.match(/Crashed Thread:(.*?)\n/m)[1].split(" ")[0]
    details << "thread "+thread.strip
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
    version = content.match(/OS Version:.*?\((.*?)\)\n/m)[1]
    details << "OS "+version.strip
rescue
end

res += "(#{details.join(", ")})"

puts res