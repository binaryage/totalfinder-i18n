#!/usr/bin/env ruby
# frozen_string_literal: true

# https://github.com/defunkt/gist/blob/master/lib/gist.rb

require 'net/https'
require 'cgi'
require 'uri'

begin
  require 'json'
rescue LoadError
  require File.join File.dirname(__FILE__), 'json.rb'
end

# It just gists.
module Gist
  module_function

  VERSION = '6.0.0'

  # A list of clipboard commands with copy and paste support.
  CLIPBOARD_COMMANDS = {
    'pbcopy' => 'pbpaste',
    'xclip' => 'xclip -o',
    'xsel -i' => 'xsel -o',
    'putclip' => 'getclip'
  }.freeze

  GITHUB_API_URL = URI('https://api.github.com/')
  GITHUB_URL = URI('https://github.com/')
  GIT_IO_URL = URI('https://git.io')

  GITHUB_BASE_PATH = ''
  GHE_BASE_PATH = '/api/v3'

  GITHUB_CLIENT_ID = '4f7ec0d4eab38e74384e'

  URL_ENV_NAME = 'GITHUB_URL'
  CLIENT_ID_ENV_NAME = 'GIST_CLIENT_ID'

  USER_AGENT = "gist/#{VERSION} (Net::HTTP, #{RUBY_DESCRIPTION})"

  # Exception tag for errors raised while gisting.
  module Error
    def self.exception(*args)
      RuntimeError.new(*args).extend(self)
    end
  end

  class ClipboardError < RuntimeError
    include Error
  end

  # helper module for authentication token actions
  module AuthTokenFile
    def self.filename
      if ENV.key?(URL_ENV_NAME)
        File.expand_path "~/.gist.#{ENV[URL_ENV_NAME].gsub(/:/, '.').gsub(/[^a-z0-9.-]/, '')}"
      else
        File.expand_path '~/.gist'
      end
    end

    def self.read
      File.read(filename).chomp
    end

    def self.write(token)
      File.open(filename, 'w', 0o600) do |f|
        f.write token
      end
    end
  end

  # auth token for authentication
  #
  # @return [String] string value of access token or `nil`, if not found
  def auth_token
    @token ||= begin
      AuthTokenFile.read
    rescue
      nil
    end
  end

  # Upload a gist to https://gist.github.com
  #
  # @param [String] content  the code you'd like to gist
  # @param [Hash] options  more detailed options, see
  #   the documentation for {multi_gist}
  #
  # @see http://developer.github.com/v3/gists/
  def gist(content, options={})
    filename = options[:filename] || default_filename
    multi_gist({ filename => content }, options)
  end

  def default_filename
    'gistfile1.txt'
  end

  # Upload a gist to https://gist.github.com
  #
  # @param [Hash] files  the code you'd like to gist: filename => content
  # @param [Hash] options  more detailed options
  #
  # @option options [String] :description  the description
  # @option options [Boolean] :public  (false) is this gist public
  # @option options [Boolean] :anonymous  (false) is this gist anonymous
  # @option options [String] :access_token  (`File.read("~/.gist")`) The OAuth2 access token.
  # @option options [String] :update  the URL or id of a gist to update
  # @option options [Boolean] :copy  (false) Copy resulting URL to clipboard, if successful.
  # @option options [Boolean] :open  (false) Open the resulting URL in a browser.
  # @option options [Boolean] :skip_empty (false) Skip gisting empty files.
  # @option options [Symbol] :output (:all) The type of return value you'd like:
  #   :html_url gives a String containing the url to the gist in a browser
  #   :short_url gives a String contianing a  git.io url that redirects to html_url
  #   :javascript gives a String containing a script tag suitable for embedding the gist
  #   :all gives a Hash containing the parsed json response from the server
  #
  # @return [String, Hash]  the return value as configured by options[:output]
  # @raise [Gist::Error]  if something went wrong
  #
  # @see http://developer.github.com/v3/gists/
  def multi_gist(files, options={})
    if options[:anonymous]
      raise 'Anonymous gists are no longer supported. Please log in with `gist --login`. ' \
            '(GitHub now requires credentials to gist https://bit.ly/2GBBxKw)'
    else
      access_token = (options[:access_token] || auth_token)
    end

    json = {}

    json[:description] = options[:description] if options[:description]
    json[:public] = !options[:public].nil?
    json[:files] = {}

    files.each_pair do |(name, content)|
      if content.to_s.strip == ''
        raise 'Cannot gist empty files' unless options[:skip_empty]
      else
        name = name == '-' ? default_filename : File.basename(name)
        json[:files][name] = { content: content }
      end
    end

    return if json[:files].empty? && options[:skip_empty]

    existing_gist = options[:update].to_s.split('/').last

    url = "#{base_path}/gists"
    url << '/' << CGI.escape(existing_gist) if existing_gist.to_s != ''

    request = Net::HTTP::Post.new(url)
    request['Authorization'] = "token #{access_token}" if access_token.to_s != ''
    request.body = JSON.dump(json)
    request.content_type = 'application/json'

    retried = false

    begin
      response = http(api_url, request)
      if response.is_a?(Net::HTTPSuccess)
        on_success(response.body, options)
      else
        raise "Got #{response.class} from gist: #{response.body}"
      end
    rescue => e
      raise if retried

      retried = true
      retry
    end
  rescue => e
    raise e.extend Error
  end

  # List all gists(private also) for authenticated user
  # otherwise list public gists for given username (optional argument)
  #
  # @param [String] user
  # @deprecated
  #
  # see https://developer.github.com/v3/gists/#list-gists
  def list_gists(user='')
    url = base_path.to_s

    if user == ''
      access_token = auth_token
      if access_token.to_s == ''
        raise Error, "Not authenticated. Use 'gist --login' to login or 'gist -l username' to view public gists."
      else
        url << '/gists'

        request = Net::HTTP::Get.new(url)
        request['Authorization'] = "token #{access_token}"
        response = http(api_url, request)

        pretty_gist(response)

      end

    else
      url << "/users/#{user}/gists"

      request = Net::HTTP::Get.new(url)
      response = http(api_url, request)

      pretty_gist(response)
    end
  end

  def list_all_gists(user='')
    url = base_path.to_s

    url << if user == ''
             '/gists?per_page=100'
           else
             "/users/#{user}/gists?per_page=100"
           end

    get_gist_pages(url, auth_token)
  end

  def read_gist(id, file_name=nil, options={})
    url = "#{base_path}/gists/#{id}"

    access_token = (options[:access_token] || auth_token)
    url << '?access_token=' << CGI.escape(access_token) if access_token.to_s != ''

    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "token #{access_token}" if access_token.to_s != ''
    response = http(api_url, request)

    if response.code == '200'
      body = JSON.parse(response.body)
      files = body['files']

      if file_name
        file = files[file_name]
        raise Error, "Gist with id of #{id} and file #{file_name} does not exist." unless file
      else
        file = files.values.first
      end

      file['content']
    else
      raise Error, "Gist with id of #{id} does not exist."
    end
  end

  def delete_gist(id)
    id = id.split('/').last
    url = "#{base_path}/gists/#{id}"

    access_token = auth_token
    if access_token.to_s == ''
      raise Error, "Not authenticated. Use 'gist --login' to login."
    else
      request = Net::HTTP::Delete.new(url)
      request['Authorization'] = "token #{access_token}"
      response = http(api_url, request)
    end

    if response.code == '204'
      puts 'Deleted!'
    else
      raise Error, "Gist with id of #{id} does not exist."
    end
  end

  def get_gist_pages(url, access_token='')
    request = Net::HTTP::Get.new(url)
    request['Authorization'] = "token #{access_token}" if access_token.to_s != ''
    response = http(api_url, request)
    pretty_gist(response)

    link_header = response.header['link']

    if link_header
      links = link_header.gsub(/(<|>|")/, '').split(',').to_h { |link| link.split('; rel=') }.invert
      get_gist_pages(links['next'], access_token) if links['next']
    end
  end

  # return prettified string result of response body for all gists
  #
  # @params [Net::HTTPResponse] response
  # @return [String] prettified result of listing all gists
  #
  # see https://developer.github.com/v3/gists/#response
  def pretty_gist(response)
    body = JSON.parse(response.body)
    if response.code == '200'
      body.each do |gist|
        description = "#{gist['description'] || gist['files'].keys.join(' ')} #{gist['public'] ? '' : '(secret)'}"
        puts "#{gist['html_url']} #{description.tr("\n", ' ')}\n"
        $stdout.flush
      end

    else
      raise Error, body['message']
    end
  end

  # Convert long github urls into short git.io ones
  #
  # @param [String] url
  # @return [String] shortened url, or long url if shortening fails
  def shorten(url)
    request = Net::HTTP::Post.new('/create')
    request.set_form_data(url: url)
    response = http(GIT_IO_URL, request)
    case response.code
    when '200'
      URI.join(GIT_IO_URL, response.body).to_s
    when '201'
      response['Location']
    else
      url
    end
  end

  # Convert github url into raw file url
  #
  # Unfortunately the url returns from github's api is legacy,
  # we have to taking a HTTPRedirection before appending it
  # with '/raw'. Let's looking forward for github's api fix :)
  #
  # @param [String] url
  # @return [String] the raw file url
  def rawify(url)
    uri = URI(url)
    request = Net::HTTP::Get.new(uri.path)
    response = http(uri, request)
    case response
    when Net::HTTPSuccess
      "#{url}/raw"
    when Net::HTTPRedirection
      rawify(response.header['location'])
    end
  end

  # Log the user into gist.
  #
  def login!(credentials={})
    if (login_url == GITHUB_URL || ENV.key?(CLIENT_ID_ENV_NAME)) && credentials.empty? && !ENV.key?('GIST_USE_USERNAME_AND_PASSWORD')
      device_flow_login!
    else
      access_token_login!(credentials)
    end
  end

  def device_flow_login!
    puts 'Requesting login parameters...'
    request = Net::HTTP::Post.new('/login/device/code')
    request.body = JSON.dump({
                               scope: 'gist',
                               client_id: client_id
                             })
    request.content_type = 'application/json'
    request['accept'] = 'application/json'
    response = http(login_url, request)

    raise Error, "HTTP #{response.code}: #{response.body}" if response.code != '200'

    body = JSON.parse(response.body)

    puts "Please sign in at #{body['verification_uri']}"
    puts "  and enter code: #{body['user_code']}"
    device_code = body['device_code']
    interval = body['interval']

    loop do
      sleep(interval.to_i)
      request = Net::HTTP::Post.new('/login/oauth/access_token')
      request.body = JSON.dump({
                                 client_id: client_id,
                                 grant_type: 'urn:ietf:params:oauth:grant-type:device_code',
                                 device_code: device_code
                               })
      request.content_type = 'application/json'
      request['Accept'] = 'application/json'
      response = http(login_url, request)
      raise Error, "HTTP #{response.code}: #{response.body}" if response.code != '200'

      body = JSON.parse(response.body)
      break unless body['error'] == 'authorization_pending'
    end

    raise Error, body['error_description'] if body['error']

    AuthTokenFile.write JSON.parse(response.body)['access_token']

    puts "Success! #{ENV[URL_ENV_NAME] || 'https://github.com/'}settings/connections/applications/#{client_id}"
  end

  # Logs the user into gist.
  #
  # This method asks the user for a username and password, and tries to obtain
  # and OAuth2 access token, which is then stored in ~/.gist
  #
  # @raise [Gist::Error]  if something went wrong
  # @see http://developer.github.com/v3/oauth/
  def access_token_login!(credentials={})
    puts 'Obtaining OAuth2 access_token from GitHub.'
    loop do
      print 'GitHub username: '
      username = credentials[:username] || $stdin.gets.strip
      print 'GitHub password: '
      password = credentials[:password] || begin
        begin
          `stty -echo`
        rescue
          nil
        end
        $stdin.gets.strip
      ensure
        begin
          `stty echo`
        rescue
          nil
        end
      end
      puts ''

      request = Net::HTTP::Post.new("#{base_path}/authorizations")
      request.body = JSON.dump({
                                 scopes: [:gist],
                                 note: "The gist gem (#{Time.now})",
                                 note_url: 'https://github.com/ConradIrwin/gist'
                               })
      request.content_type = 'application/json'
      request.basic_auth(username, password)

      response = http(api_url, request)

      if response.is_a?(Net::HTTPUnauthorized) && response['X-GitHub-OTP']
        print '2-factor auth code: '
        twofa_code = $stdin.gets.strip
        puts ''

        request['X-GitHub-OTP'] = twofa_code
        response = http(api_url, request)
      end

      case response
      when Net::HTTPCreated
        AuthTokenFile.write JSON.parse(response.body)['token']
        puts "Success! #{ENV[URL_ENV_NAME] || 'https://github.com/'}settings/tokens"
        return
      when Net::HTTPUnauthorized
        puts "Error: #{JSON.parse(response.body)['message']}"
        next
      else
        raise "Got #{response.class} from gist: #{response.body}"
      end
    end
  rescue => e
    raise e.extend Error
  end

  # Return HTTP connection
  #
  # @param [URI::HTTP] The URI to which to connect
  # @return [Net::HTTP]
  def http_connection(uri)
    env = ENV['http_proxy'] || ENV['HTTP_PROXY']
    connection = if env
                   proxy = URI(env)
                   if proxy.user
                     Net::HTTP::Proxy(proxy.host, proxy.port, proxy.user, proxy.password).new(uri.host, uri.port)
                   else
                     Net::HTTP::Proxy(proxy.host, proxy.port).new(uri.host, uri.port)
                   end
                 else
                   Net::HTTP.new(uri.host, uri.port)
                 end
    if uri.scheme == 'https'
      connection.use_ssl = true
      connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    connection.open_timeout = 10
    connection.read_timeout = 10
    connection
  end

  # Run an HTTP operation
  #
  # @param [URI::HTTP] The URI to which to connect
  # @param [Net::HTTPRequest] The request to make
  # @return [Net::HTTPResponse]
  def http(url, request)
    request['User-Agent'] = USER_AGENT

    http_connection(url).start do |http|
      http.request request
    end
  rescue Timeout::Error
    raise "Could not connect to #{api_url}"
  end

  # Called after an HTTP response to gist to perform post-processing.
  #
  # @param [String] body  the text body from the github api
  # @param [Hash] options  more detailed options, see
  #   the documentation for {multi_gist}
  def on_success(body, options={})
    json = JSON.parse(body)

    output = case options[:output]
             when :javascript
               %(<script src="#{json['html_url']}.js"></script>)
             when :html_url
               json['html_url']
             when :raw_url
               rawify(json['html_url'])
             when :short_url
               shorten(json['html_url'])
             when :short_raw_url
               shorten(rawify(json['html_url']))
             else
               json
             end

    Gist.copy(output.to_s) if options[:copy]
    Gist.open(json['html_url']) if options[:open]

    output
  end

  # Copy a string to the clipboard.
  #
  # @param [String] content
  # @raise [Gist::Error] if no clipboard integration could be found
  #
  def copy(content)
    IO.popen(clipboard_command(:copy), 'r+') { |clip| clip.print content }

    unless paste == content
      message = 'Copying to clipboard failed.'

      if ENV['TMUX'] && clipboard_command(:copy) == 'pbcopy'
        message << "\nIf you're running tmux on a mac, try http://robots.thoughtbot.com/post/19398560514/how-to-copy-and-paste-with-tmux-on-mac-os-x"
      end

      raise Error, message
    end
  rescue Error => e
    raise ClipboardError, e.message + "\nAttempted to copy: #{content}"
  end

  # Get a string from the clipboard.
  #
  # @param [String] content
  # @raise [Gist::Error] if no clipboard integration could be found
  def paste
    `#{clipboard_command(:paste)}`
  end

  # Find command from PATH environment.
  #
  # @param [String] cmd  command name to find
  # @param [String] options  PATH environment variable
  # @return [String]  the command found
  def which(cmd, path=ENV['PATH'])
    if RUBY_PLATFORM.downcase =~ /mswin(?!ce)|mingw|bccwin|cygwin/
      path.split(File::PATH_SEPARATOR).each do |dir|
        f = File.join(dir, "#{cmd}.exe")
        return f if File.executable?(f) && !File.directory?(f)
      end
      nil
    else
      system("which #{cmd} > /dev/null 2>&1")
    end
  end

  # Get the command to use for the clipboard action.
  #
  # @param [Symbol] action  either :copy or :paste
  # @return [String]  the command to run
  # @raise [Gist::ClipboardError] if no clipboard integration could be found
  def clipboard_command(action)
    command = CLIPBOARD_COMMANDS.keys.detect do |cmd|
      which cmd
    end
    raise ClipboardError, <<~EOT unless command
      Could not find copy command, tried:
          #{CLIPBOARD_COMMANDS.values.join(' || ')}
    EOT

    action == :copy ? command : CLIPBOARD_COMMANDS[command]
  end

  # Open a URL in a browser.
  #
  # @param [String] url
  # @raise [RuntimeError] if no browser integration could be found
  #
  # This method was heavily inspired by defunkt's Gist#open,
  # @see https://github.com/defunkt/gist/blob/bca9b29/lib/gist.rb#L157
  def open(url)
    command = if ENV['BROWSER']
                ENV['BROWSER']
              elsif RUBY_PLATFORM =~ /darwin/
                'open'
              elsif RUBY_PLATFORM =~ /linux/
                %w[
                  sensible-browser
                  xdg-open
                  firefox
                  firefox-bin
                ].detect do |cmd|
                  which cmd
                end
              elsif ENV['OS'] == 'Windows_NT' || RUBY_PLATFORM =~ /djgpp|(cyg|ms|bcc)win|mingw|wince/i
                'start ""'
              else
                raise 'Could not work out how to use a browser.'
              end

    `#{command} #{url}`
  end

  # Get the API base path
  def base_path
    ENV.key?(URL_ENV_NAME) ? GHE_BASE_PATH : GITHUB_BASE_PATH
  end

  def login_url
    ENV.key?(URL_ENV_NAME) ? URI(ENV[URL_ENV_NAME]) : GITHUB_URL
  end

  # Get the API URL
  def api_url
    ENV.key?(URL_ENV_NAME) ? URI(ENV[URL_ENV_NAME]) : GITHUB_API_URL
  end

  def client_id
    ENV.key?(CLIENT_ID_ENV_NAME) ? URI(ENV[CLIENT_ID_ENV_NAME]) : GITHUB_CLIENT_ID
  end

  def legacy_private_gister?
    return unless which('git')

    `git config --global gist.private` =~ /\Ayes|1|true|on\z/i
  end

  def should_be_public?(options={})
    if options.key? :private
      !options[:private]
    else
      !Gist.legacy_private_gister?
    end
  end
end
