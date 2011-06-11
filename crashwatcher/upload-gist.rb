#!/usr/bin/env ruby

# https://github.com/defunkt/gist/blob/master/lib/gist.rb

require 'open-uri'
require 'net/https'

module Gist
    extend self
    GIST_URL = 'https://gist.github.com/%s.txt'
    CREATE_URL = 'https://gist.github.com/gists'
    
    PROXY = ENV['HTTP_PROXY'] ? URI(ENV['HTTP_PROXY']) : nil
    PROXY_HOST = PROXY ? PROXY.host : nil
    PROXY_PORT = PROXY ? PROXY.port : nil
    
    # Create a gist on gist.github.com
    def write(files, private_gist = false)
        url = URI.parse(CREATE_URL)
        
        if PROXY_HOST
            proxy = Net::HTTP::Proxy(PROXY_HOST, PROXY_PORT)
            http  = proxy.new(url.host, url.port)
        else
            http = Net::HTTP.new(url.host, url.port)
        end
        
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
        http.ca_file = File.join(File.dirname(__FILE__), "cacert.pem")
        
        req = Net::HTTP::Post.new(url.path)
        req.form_data = data(files, private_gist)
        
        http.start{|h| h.request(req) }['Location']
    end
    
private
    
    # Give an array of file information and private boolean, returns
    # an appropriate payload for POSTing to gist.github.com
    def data(files, private_gist)
        data = {}
        files.each do |file|
            i = data.size + 1
            data["file_ext[gistfile#{i}]"]      = file[:extention] ? file[:extention] : '.txt'
            data["file_name[gistfile#{i}]"]     = file[:filename]
            data["file_contents[gistfile#{i}]"] = file[:input]
        end
        data.merge(private_gist ? { 'action_button' => 'private' } : {})
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