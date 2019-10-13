#!/usr/bin/env ruby
# frozen_string_literal: true

# https://github.com/defunkt/gist/blob/master/lib/gist.rb

# this is to override encoding problems, users might have different locales set
# even US-ASCII could throw Encoding::InvalidByteSequenceError
# see https://makandracards.com/makandra/41250-ruby-s-default-encodings-can-be-unexpected
Encoding.default_external = 'UTF-8'

begin
  # noinspection RubyResolve
  require File.join File.dirname(__FILE__), 'gist.rb'
rescue LoadError
  # noinspection RubyResolve
  begin
    require File.join File.dirname(__FILE__), 'vendor', 'gist.rb'
  rescue LoadError
    raise 'Failed to require gist.rb'
  end
end

# for now, I just support one file to upload

file = ARGV[0].to_s
token = ARGV[1].to_s

raise 'no file path specified' if file.empty?
raise 'no github access token specified' if token.empty?

file_content = File.read(file)
options = {
  filename: 'TotalFinder.crash',
  access_token: token,
  output: :html_url
}
puts Gist.gist(file_content, options)
