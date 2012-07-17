#!/usr/bin/env ruby

# https://github.com/defunkt/gist/blob/master/lib/gist.rb

require 'open-uri'
require 'net/https'
require 'optparse'

require 'base64'

require File.join(File.dirname(__FILE__), 'json.rb')    unless defined?(JSON)

module Gist
  extend self
  
  GIST_URL   = 'https://api.github.com/gists/%s'
  CREATE_URL = 'https://api.github.com/gists'
  
  if ENV['HTTPS_PROXY']
  PROXY = URI(ENV['HTTPS_PROXY'])
  elsif ENV['HTTP_PROXY']
  PROXY = URI(ENV['HTTP_PROXY'])
  else
  PROXY = nil
end
PROXY_HOST = PROXY ? PROXY.host : nil
PROXY_PORT = PROXY ? PROXY.port : nil



# Create a gist on gist.github.com
def write(files, private_gist = false, description = nil)
  url = URI.parse(CREATE_URL)
  
  if PROXY_HOST
    proxy = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
    http  = proxy.new(url.host, url.port)
    else
    http = Net::HTTP.new(url.host, url.port)
  end
  
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_PEER
  http.ca_file = ca_cert
  
  req = Net::HTTP::Post.new(url.path)
  req.set_content_type("application/json")
  req.body = JSON.generate(data(files, private_gist, description))
  
  user, password = auth()
  if user && password
    req.basic_auth(user, password)
  end
  
  response = http.start{|h| h.request(req) }
  case response
    when Net::HTTPCreated
    JSON.parse(response.body)['html_url']
    else
    puts "Creating gist failed: #{response.code} #{response.message}"
    exit(false)
  end
end

private
# Give an array of file information and private boolean, returns
# an appropriate payload for POSTing to gist.github.com
def data(files, private_gist, description)
  i = 0
  file_data = {}
  files.each do |file|
    i = i + 1
    filename = file[:filename] ? file[:filename] : "gistfile#{i}"
    file_data[filename] = {:content => file[:input]}
  end
  
  data = {"files" => file_data}
  data.merge!({ 'description' => description }) unless description.nil?
  data.merge!({ 'public' => !private_gist })
  data
end

# Returns a basic auth string of the user's GitHub credentials if set.
# http://github.com/guides/local-github-config
#
# Returns an Array of Strings if auth is found: [user, password]
# Returns nil if no auth is found.
def auth
  user  = config("github.user")
  password = config("github.password")
  
  token = config("github.token")
  if password.to_s.empty? && !token.to_s.empty?
    # abort "Please set GITHUB_PASSWORD or github.password instead of using a token."
  end
  
  if user.to_s.empty? || password.to_s.empty?
    nil
    else
    [ user, password ]
  end
end

# Returns default values based on settings in your gitconfig. See
# git-config(1) for more information.
#
# Settings applicable to gist.rb are:
#
# gist.private - boolean
# gist.extension - string
def defaults
  extension = config("gist.extension")
  
  return {
    "private"   => config("gist.private"),
    "browse"    => config("gist.browse"),
    "extension" => extension
  }
end

# Reads a config value using:
# => Environment: GITHUB_PASSWORD, GITHUB_USER
#                 like vim gist plugin
# => git-config(1)
#
# return something useful or nil
def config(key)
  env_key = ENV[key.upcase.gsub(/\./, '_')]
  return env_key if env_key and not env_key.strip.empty?
  
  str_to_bool `git config --global #{key}`.strip
end

# Parses a value that might appear in a .gitconfig file into
# something useful in a Ruby script.
def str_to_bool(str)
  if str.size > 0 and str[0].chr == '!'
    command = str[1, str.length]
    value = `#{command}`
    else
    value = str
  end
  
  case value.downcase.strip
    when "false", "0", "nil", "", "no", "off"
    nil
    when "true", "1", "yes", "on"
    true
    else
    value
  end
end

def ca_cert
  File.join(File.dirname(__FILE__), "cacert.pem")
end

end

# for now, I just support one file to upload
file = ARGV[0] 
files = [{
  :input     => File.read(file),
  :filename  => "TotalFinder.crash",
  :extension => (File.extname(file) if file.include?('.'))
}]
puts Gist.write(files, true)