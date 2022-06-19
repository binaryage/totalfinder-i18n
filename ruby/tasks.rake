# frozen_string_literal: true

require 'date'
require 'pp'
require 'colored2'

################################################################################################
# constants

ROOT_DIR = File.expand_path('.')
FINDER_DIR = '/System/Library/CoreServices/Finder.app'
FINDER_RESOURCES_DIR = File.join(FINDER_DIR, 'Contents/Resources')
PLUGIN_RESOURCES_DIR = File.join(ROOT_DIR, 'plugin')
INSTALLER_RESOURCES_DIR = File.join(ROOT_DIR, 'installer')
ENGLISH_LPROJ = File.join(PLUGIN_RESOURCES_DIR, 'en.lproj')
SHELL_SOURCES = [File.join(ROOT_DIR, '..', 'shell'), File.join(ROOT_DIR, '..', 'frameworks')].freeze
TOTALFINDER_PLUGINS_SOURCES = File.join(ROOT_DIR, '..', 'plugins')

################################################################################################
# helpers

# this is here just IntelliJ to understand colors
class String
  def self.blue
    Colored2.blue(self)
  end

  def self.red
    Colored2.red(self)
  end

  def self.yellow
    Colored2.yellow(self)
  end

  def self.green
    Colored2.green(self)
  end

  def self.cyan
    Colored2.cyan(self)
  end

  def self.magenta
    Colored2.magenta(self)
  end

  def self.bold
    Colored2.bold(self)
  end

  def self.underline
    Colored2.underline(self)
  end
end

def die(msg, status=1)
  puts red("Error[#{status || $CHILD_STATUS}]: #{msg}").red
  exit status || $CHILD_STATUS
end

def sys(cmd)
  puts "> #{cmd}".yellow
  system(cmd)
end

################################################################################################
# routines

def write_file(filename, content)
  if ENV['dry']
    puts "in dry mode: would rewrite #{filename.blue} with content of size #{content.size}"
    return
  end

  File.write(filename, content)
end

def append_file(filename, content)
  if ENV['dry']
    puts "in dry mode: would append to #{filename.blue} content of size #{content.size}"
    return
  end

  File.open(filename, 'a') do |f|
    f.write content
  end
end

def get_list_of_plugins(filter=nil)
  filter ||= '*'

  plugins = []
  Dir.glob(File.join(TOTALFINDER_PLUGINS_SOURCES, filter)) do |file|
    if File.directory?(file) && File.exist?(File.join(file, "#{File.basename(file)}.xcodeproj"))
      plugins << File.basename(file)
    end
  end

  plugins.uniq
end

def ack(dir, glob, regexps)
  glob = File.join(dir, '**{,/*/**}', glob) # follow symlinks (http://stackoverflow.com/a/2724048/84283)
  set = []
  Dir.glob(glob) do |file|
    puts file if ENV['verbose']
    content = File.read(file)
    regexps.each do |r|
      match = content.scan(r)
      set.concat match.flatten
    end
  end
  set.sort.uniq
end

def stitch_broken_strings(strings)
  strings.map do |s|
    r = /([^\\])(".*?")/m
    s.gsub(r) do |_x|
      Regexp.last_match(1)
    end
  end
end

def extract_menu_strings(folder)
  dirs = Array(folder) # flexibility to pass multiple directories
  result = []
  dirs.each do |dir|
    result.concat ack(dir, '*.{cpp,mm,h}', [
        /\$M\s*\(\s*@\s*"(.*?)"\s*\)/m
    ])
  end

  stitch_broken_strings(result.sort.uniq)
end

def extract_code_strings(folder)
  dirs = Array(folder) # flexibility to pass multiple directories

  result = []
  dirs.each do |dir|
    result.concat ack(dir, '*.{cpp,mm,m,h}', [
        /\$+\s*\(\s*@\s*"(.*?)"\s*\)/m,
        /\$NSLocalizedString\s*\(\s*@\s*"(.*?)"\s*[,)]/m
    ])
  end

  stitch_broken_strings(result.sort.uniq)
end

def extract_ui_strings(folder, xibs)
  dirs = Array(folder) # flexibility to pass multiple directories
  result = []
  dirs.each do |dir|
    xibs.each do |xib|
      result.concat ack(dir, "#{xib}.xib", [
          /"\^(.*?[^\\])"/m
      ])
    end
  end
  result.sort.uniq
end

def parse_strings_file(filename)
  return [] unless File.exist? filename

  File.read(filename).lines
end

def update_strings(old_strings, new_keys, target)
  removed_count = 0
  count = 0

  # comment out existing strings as REMOVED or DUPLICIT if they are not present in new_strings
  known_keys = []
  strings = old_strings.map do |line|
    match = line =~ /^"(.*?)"/ # it is a valid key-definition line?
    next line unless match

    count += 1
    if new_keys.include? Regexp.last_match(1)
      if known_keys.include? Regexp.last_match(1)
        line = "/* DUPLICIT #{line.strip} */\n" # ***
        removed_count += 1
      else
        known_keys << Regexp.last_match(1)
      end
    else
      line = "/* REMOVED #{line.strip} */\n" # ***
      removed_count += 1
    end
    line
  end

  to_be_added = new_keys - known_keys

  write_file(target, strings.join)

  {
    'removed_count' => removed_count,
    'count' => count,
    'new_strings' => new_keys,
    'old_strings' => old_strings,
    'output' => strings,
    'to_be_added' => to_be_added.sort.uniq
  }
end

def update_english_strings(project, src_folder, xibs, additional_strings=[])
  target = File.join(ENGLISH_LPROJ, "#{project}.strings")
  code_strings = extract_code_strings(src_folder)
  ui_strings = extract_ui_strings(PLUGIN_RESOURCES_DIR, xibs)
  new_strings = code_strings.concat(ui_strings).concat(additional_strings)
  new_strings.sort.uniq!
  old_strings = parse_strings_file(target)

  res = update_strings(old_strings, new_strings, target)

  removed_count = res['removed_count']
  count = res['count']

  puts " #{"-#{removed_count}".red}/#{count.to_s.blue} in #{target}"

  res
end

def categorize_xibs(plugins, dir=PLUGIN_RESOURCES_DIR)
  xibs = {}

  # xib naming exceptions that don't follow conventions
  unconventional = {
    'SomeXibName' => 'SomePluginName'
  }

  Dir.glob(File.join(dir, '*.xib')) do |file|
    name = File.basename(file, '.xib')
    # does the name begin with some plugin name?
    plugin = plugins.find { |item| item == name || name.start_with?(item) }
    plugin = unconventional['name'] if plugin.nil? && unconventional['name']

    unless plugin.nil?
      xibs[plugin] ||= []
      xibs[plugin] << name
      next
    end

    xibs['SHELL'] ||= []
    xibs['SHELL'] << name
  end

  xibs
end

def process_english_strings_in_plugins(plugins, xibs, dir=TOTALFINDER_PLUGINS_SOURCES)
  additions = {}
  plugins.each do |plugin|
    plugin_dir = File.join(dir, plugin)
    next unless File.exist? plugin_dir
    next if xibs[plugin].nil? || xibs[plugin].empty? # an edge case for empty array

    additions[plugin] = update_english_strings(plugin, plugin_dir, xibs[plugin])['to_be_added'] # process just plugin xibs
  end
  additions
end

def process_english_strings_in_shell(xibs, duplicates, shell_dir=SHELL_SOURCES)
  update_english_strings('TotalFinder', shell_dir, xibs, duplicates) # process just shell xibs
end

def get_additions_duplicates(additions)
  all = []
  additions.each do |_k, v|
    all.concat v
  end

  # count occurrences and return only duplicities
  all.each_with_object(Hash.new(0)) { |v, h| h[v] += 1; }.reject { |_k, v| v == 1 }.keys.sort.uniq
end

def insert_additions(list, target)
  return if list.empty?

  strings = []
  strings << "\n"
  strings << "/* NEW STRINGS - TODO: SORT THEM IN OR CREATE A NEW SECTION */\n"

  list.each do |key|
    value = key.gsub('MenuItem:', '') # MenuItems special case
    strings << "\"#{key}\" = \"#{value}\";"
  end

  append_file(target, strings.join("\n"))

  puts " #{"+#{list.size}".yellow} in #{target}"
end

def inprint_strings(source, dest, shared_originals=[])
  strings = parse_strings_file(source)
  originals = []
  originals.concat shared_originals
  originals.concat parse_strings_file(dest)

  # transform lang back to english
  index = 0
  strings.map! do |line|
    index += 1
    next line unless line.strip[0...1] == '"'

    line =~ /^\s*?(".*")\s*?=\s*?(".*")\s*?;\s*?/
    die "syntax error in #{source.blue}:#{index} [#{line}]" unless Regexp.last_match(1)

    line = "#{Regexp.last_match(1)} = #{Regexp.last_match(1)};\n"

    line
  end

  # replace translations we already know from previous version
  index = 0
  originals.each do |original|
    index += 1
    next unless original.strip[0...1] == '"'

    original =~ /^\s*?(".*")\s*?=\s*?(".*")\s*?;(.*)$/
    needle = Regexp.last_match(1)
    haystack = Regexp.last_match(2)
    rest = Regexp.last_match(3)
    die "syntax error in #{dest.blue}:#{index} [#{original}]" unless Regexp.last_match(1) && Regexp.last_match(2)

    strings.map! do |line|
      line = "#{needle} = #{haystack};#{rest}\n" if line.start_with?(needle)

      line
    end
  end

  write_file(dest, strings.join)

  strings
end

def find_key(key, lines)
  lines.each do |line|
    next unless line.strip[0...1] == '"'

    line =~ /^\s*?(".*")\s*?=\s*?(".*")\s*?;(.*)$/
    needle = Regexp.last_match(1)
    haystack = Regexp.last_match(2)
    die "syntax error in [#{line}]" unless Regexp.last_match(1) && Regexp.last_match(2)
    return haystack if needle == key
  end

  nil
end

def post_process_menu(dest, shared_originals=[])
  strings = parse_strings_file(dest)

  strings.map! do |line|
    next line unless line.strip[0...1] == '"'

    line =~ /^\s*?(".*")\s*?=\s*?(".*")\s*?;(.*)$/
    die "syntax error in #{source.blue}:#{index} [#{line}]" unless Regexp.last_match(1)

    key = Regexp.last_match(1)
    val = Regexp.last_match(2)
    rest = Regexp.last_match(3)

    if key == val
      # try to lookup existing val
      translated_val = find_key(key.gsub('MenuItem:', ''), shared_originals)
      line = "#{key} = #{translated_val};#{rest}\n" unless translated_val.nil?
    end

    line
  end

  File.open(dest, 'w') do |f|
    f << strings.join
  end

  strings
end

def propagate_english_to_cwd
  total = 0

  # TotalFinder.strings are master files, some strings may move between files
  all = parse_strings_file File.join(Dir.pwd, 'TotalFinder.strings')

  Dir.glob(File.join(ENGLISH_LPROJ, '*.strings')) do |file|
    puts "  #{File.basename(file)}".yellow
    total += inprint_strings(file, File.join(Dir.pwd, File.basename(file)), all).size
  end

  puts "  -> #{total.to_s.green} strings processed"
end

def remove_missing_files_in_cwd
  files1 = Dir.glob(File.join(ENGLISH_LPROJ, '*')).map { |f| File.basename f }
  files2 = Dir.glob(File.join(Dir.pwd, '*')).map { |f| File.basename f }
  to_be_deleted = files2 - files1

  to_be_deleted.each do |file|
    puts "deleting '#{file}'".red
    FileUtils.rm(file)
  end
end

def propagate_from_english_to_other_lprojs
  glob = ENV['to'] || '*.lproj'

  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, glob)) do |dir|
    Dir.chdir dir do
      puts dir.blue
      propagate_english_to_cwd
      remove_missing_files_in_cwd
    end
  end
end

def create_localizations_for_project
  glob = ENV['to'] || '*.lproj'
  project = ENV['project'] || die('Project name not defined')

  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, glob)) do |dir|
    Dir.chdir dir do
      write_file(File.join(dir, "#{project}.strings"), '/* no strings */')
    end
  end
end

def exec_cmd_in_lprojs(cmd)
  glob = ENV['to'] || '*.lproj'

  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, glob)) do |dir|
    puts dir.blue
    Dir.chdir dir do
      sys(cmd)
    end
  end
end

def merge_string_tables
  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, '*.lproj')) do |dir|
    puts dir.blue

    string_files = Dir.glob(File.join(dir, '*.strings')).sort!
    totalfinder_strings = string_files.filter { |file| /TotalFinder\.strings/.match?(file) }
    other_strings = string_files.filter { |file| !/TotalFinder\.strings/.match?(file) }

    other_strings.each do |strings_file|
      unless /Template\.strings/.match?(strings_file)
        file_content = File.read(strings_file)

        strings_file =~ /\/([^\/]*)\.strings/
        name = Regexp.last_match(1)

        contents = []
        contents << ''
        contents << ''
        contents << "/* --- #{name} --- */"
        contents << ''
        contents << file_content
        content = contents.join("\n")

        append_file(totalfinder_strings.first, content)
      end

      File.delete(strings_file)
    end
  end
end

def validate_strings_file(path)
  lines = parse_strings_file(path)

  in_multi_line_comment = false
  counter = 0
  lines.each do |line|
    counter += 1
    if in_multi_line_comment && line =~ /.*\*\/\w*$/
      in_multi_line_comment = false
      next
    end
    next if in_multi_line_comment

    line = "#{line.gsub(/\r\n?/, '')}\n"
    next if line =~ /^".*?"\s*=\s*".*?";\s*$/
    next if line =~ /^".*?"\s*=\s*".*?";\s*\/\*.*?\*\/$/
    next if line =~ /^".*?"\s*=\s*".*?";\s*\/\/.*?$/
    next if line =~ /^\/\*.*?\*\/$/
    next if line =~ /^\s*$/

    if line =~ /^\/\*[^*]*/
      in_multi_line_comment = true
      next
    end

    puts "#{"line ##{counter}: unrecognized pattern".red} (fix rakefile if this is a valid pattern)"
    puts line
    puts "mate -l #{counter} \"#{path}\"".yellow
    return false
  end

  true
end

def validate_strings_files
  begin
    require 'cmess/guess_encoding'
  rescue LoadError
    die 'You must "gem install cmess" to use character encoding detection'
  end

  glob = ENV['to'] || '*.lproj'

  counter = 0
  failed = 0
  warnings = 0

  known_files = []
  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, 'en.lproj', '*')) do |path|
    known_files << File.basename(path)
  end

  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, '*.lproj')) do |dir|
    unrecognized_files = []
    missing_files = known_files.dup

    Dir.glob(File.join(dir, '*')) do |path|
      file = File.basename(path)

      if missing_files.include?(file)
        missing_files.delete(file)
      else
        unrecognized_files << file
      end
    end

    if !missing_files.empty? || !unrecognized_files.empty?
      warnings += 1

      puts "in #{dir.blue}:"
      puts "  missing files: #{missing_files.join(', ')}" unless missing_files.empty?
      puts "  unrecognized files: #{unrecognized_files.join(', ')}" unless unrecognized_files.empty?
    end
  end

  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, glob, '*.strings')) do |path|
    counter += 1
    ok = 1
    input = File.read path
    charset = 'ASCII'
    unless input.strip.empty?
      charset = CMess::GuessEncoding::Automatic.guess(input)
      ok = ((validate_strings_file path) && ((charset == 'ASCII') || (charset == 'UTF-8')))
    end
    puts "#{charset.magenta} #{path.blue} #{'ok'.yellow}" if ok
    puts "#{charset.magenta} #{path.blue} #{'failed'.red}" unless ok
    failed += 1 unless ok
  end

  all = []
  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, 'en.lproj', '*.strings')) do |file|
    all.concat parse_strings_file(file)
  end

  list = []
  all.each do |original|
    next unless original.strip[0...1] == '"'

    original =~ /^\s*?"(.*)"\s*?=/
    list << Regexp.last_match(1)
  end

  dups = list.each_with_object(Hash.new(0)) { |v, h| h[v] += 1; }.reject { |_k, v| v == 1 }.keys

  unless dups.empty?
    puts
    puts 'found duplicate keys:'.red
    dups.each { |x| puts "  #{x}" }
    puts
    puts 'solution:'.yellow + ' shared keys should be placed in TotalFinder.strings'.blue
    puts
  end

  puts '-----------------------------------'
  failed_msg = (failed.positive? ? "#{failed} failed".red : 'all is ok'.yellow)
  warnings_msg = (warnings.positive? ? " [#{warnings} warnings]".green : '')
  puts "checked #{"#{counter} files".magenta} and #{failed_msg}#{warnings_msg}"
end

def stub_installer_lprojs
  glob = '*.lproj'

  english_source = File.join(INSTALLER_RESOURCES_DIR, 'en.lproj')
  die("need #{english_source}!") unless File.exist?(english_source)

  Dir.glob(File.join(PLUGIN_RESOURCES_DIR, glob)) do |dir|
    name = File.basename(dir)
    next if name == 'en.lproj'

    full_path = File.join(INSTALLER_RESOURCES_DIR, name)
    next if File.exist?(full_path) # already have it

    puts "Creating stub #{full_path.blue}"
    sys("cp -r \"#{english_source}\" \"#{full_path}\"")
  end
end

################################################################################################
# tasks

desc 'switch /Applications/TotalFinder.app into dev mode'
task :dev do
  sys('./bin/dev.sh')
end

desc 'switch /Applications/TotalFinder.app into non-dev mode'
task :undev do
  sys('./bin/undev.sh')
end

desc 'restart Finder.app'
task :restart do
  sys('./bin/restart.sh')
end

desc 'normalize Finder.app so it contains all our language folders (run with sudo)'
task :normalize do
  lprojs = File.join(PLUGIN_RESOURCES_DIR, '*.lproj')
  Dir.glob(lprojs) do |folder|
    dir = File.join(FINDER_RESOURCES_DIR, File.basename(folder))
    if File.exist? dir
      puts dir.blue + ' exists'.yellow
    else
      die('Unable to create a folder. Hint: you should run this as sudo rake normalize') unless sys("mkdir -p \"#{dir}\"")
      puts dir.blue + ' created'.green
    end
  end
end

desc 'cherrypicks strings from sources and applies missing strings to en.lproj'
task :cherrypick do
  die 'install ack 2.0+ | for example via homebrew:> brew install ack' if `which ack` == ''
  die 'upgrade your ack to 2.0+ | for example via homebrew:> brew install ack' unless `ack --version` =~ /ack 2/

  plugins = get_list_of_plugins
  xibs = categorize_xibs(plugins)

  puts 'XIBs:'.blue
  pp xibs

  puts
  puts 'Processing string files:'.yellow

  # additions is a hash containing an array of added translation keys for each plugin
  additions = process_english_strings_in_plugins(plugins, xibs)
  duplicates = get_additions_duplicates(additions)
  res = process_english_strings_in_shell(xibs['SHELL'], duplicates) # duplicates will be moved into shell
  shell_additions = res['to_be_added']
  shell_new_strings = res['new_strings']

  # insert additions to shell
  target = File.join(ENGLISH_LPROJ, 'TotalFinder.strings')
  insert_additions(shell_additions, target)

  unhandled_duplicates = duplicates - shell_new_strings
  unless unhandled_duplicates.empty?
    puts
    puts 'Found these shared keys in plugins and shell, we moved them to TotalFinder.strings:'.yellow
    puts unhandled_duplicates.join(', ').magenta
  end
end

desc 'propagates structure of en.lproj to all other language folders while keeping already translated strings'
task :propagate do
  propagate_from_english_to_other_lprojs
end

desc 'make stub lproj folders for installer, creates all which exist in plugin'
task :stub do
  stub_installer_lprojs
end

desc 'exec command in all lproj folders'
task :exec do
  exec_cmd_in_lprojs(ENV['cmd'] || 'ls')
end

desc 'validates all strings files and checks them for syntax errors'
task :validate do
  validate_strings_files
end

desc 'validates all strings files and checks them for syntax errors'
task :create_localization do
  create_localizations_for_project
end

desc 'merge all string tables into single TotalFinder.strings'
task :merge_string_tables do
  merge_string_tables
end

task default: :restart
