#!/usr/bin/env ruby
# frozen_string_literal: true

# ABOUTME: This script manages Homebrew installations idempotently by merging multiple Brewfiles
# ABOUTME: and providing cleanup mechanisms to remove packages not in the desired state.

require 'json'
require 'optparse'
require 'set'
require 'yaml'

# Homebrew Package Manager with idempotent installation and cleanup
class HomebrewManager
  VERSION = '1.0.0'

  def initialize
    @brewfiles_dir = determine_brewfiles_dir
    @options = {}
    @desired_state = {
      'tap' => Set.new,
      'brew' => Set.new,
      'cask' => Set.new,
      'mas' => Set.new,
      'vscode' => Set.new
    }
    @actual_state = {
      'tap' => Set.new,
      'brew' => Set.new,
      'cask' => Set.new,
      'mas' => Set.new,
      'vscode' => Set.new
    }
    @protected_packages = Set.new([
      'homebrew/core',
      'homebrew/cask',
      'homebrew/bundle',
      'brew',
      'git',
      'curl',
      'zsh'
    ])
  end

  def run
    parse_options
    log_verbose "Using brewfiles directory: #{@brewfiles_dir}"
    load_brewfiles
    load_actual_state
    
    case @options[:action]
    when 'install'
      install_packages
    when 'cleanup'
      cleanup_packages
    when 'sync'
      sync_packages
    when 'diff'
      show_diff
    when 'backup'
      backup_state
    else
      puts "Unknown action: #{@options[:action]}"
      exit 1
    end
  end

  private

  def determine_brewfiles_dir
    # Follow the same pattern as other scripts: ${SCRIPT_DIR}/../brewfiles
    # where SCRIPT_DIR is the absolute path to the script's directory
    script_dir = File.expand_path(__dir__)
    brewfiles_dir = File.expand_path('../brewfiles', script_dir)
    
    # Allow override via environment variable
    if ENV['BREWFILES_DIR'] && Dir.exist?(ENV['BREWFILES_DIR'])
      return ENV['BREWFILES_DIR']
    end
    
    # Use the standard location relative to script directory
    brewfiles_dir
  end

  def parse_options
    @options = {
      action: 'sync',
      dry_run: false,
      verbose: false,
      force: false,
      brewfiles: [],
      output: nil
    }

    OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"
      opts.separator ""
      opts.separator "Actions:"
      
      opts.on('--install', 'Install packages from Brewfiles') do
        @options[:action] = 'install'
      end
      
      opts.on('--cleanup', 'Remove packages not in any Brewfile') do
        @options[:action] = 'cleanup'
      end
      
      opts.on('--sync', 'Install missing and remove extra packages (default)') do
        @options[:action] = 'sync'
      end
      
      opts.on('--diff', 'Show difference between desired and actual state') do
        @options[:action] = 'diff'
      end
      
      opts.on('--backup', 'Backup current state to file') do
        @options[:action] = 'backup'
      end
      
      opts.separator ""
      opts.separator "Options:"
      
      opts.on('-f', '--brewfiles FILE1,FILE2', Array, 'Specific Brewfiles to use') do |files|
        @options[:brewfiles] = files
      end
      
      opts.on('-n', '--dry-run', 'Show what would be done without executing') do
        @options[:dry_run] = true
      end
      
      opts.on('-v', '--verbose', 'Verbose output') do
        @options[:verbose] = true
      end
      
      opts.on('--force', 'Force operations without confirmation') do
        @options[:force] = true
      end
      
      opts.on('-o', '--output FILE', 'Output file for backup or diff') do |file|
        @options[:output] = file
      end
      
      opts.on('-h', '--help', 'Show this help') do
        puts opts
        exit
      end
      
      opts.on('--version', 'Show version') do
        puts "Homebrew Manager v#{VERSION}"
        exit
      end
    end.parse!
  end

  def load_brewfiles
    brewfiles = if @options[:brewfiles].any?
                  @options[:brewfiles].map do |f|
                    # Check if it's an absolute path or exists in current directory
                    if f.start_with?('/') || File.exist?(f)
                      File.expand_path(f)
                    else
                      # Otherwise, look in the brewfiles directory
                      brewfile_path = File.join(@brewfiles_dir, f)
                      # Add .brewfile extension if not present
                      brewfile_path += '.brewfile' unless f.end_with?('.brewfile')
                      brewfile_path
                    end
                  end
                else
                  Dir.glob("#{@brewfiles_dir}/*.brewfile").sort
                end

    log_verbose "Loading Brewfiles: #{brewfiles.join(', ')}"

    brewfiles.each do |brewfile|
      unless File.exist?(brewfile)
        puts "Error: Brewfile not found: #{brewfile}"
        exit 1
      end
      
      parse_brewfile(brewfile)
    end

    log_verbose "Loaded desired state:"
    @desired_state.each do |type, packages|
      log_verbose "  #{type}: #{packages.size} packages"
    end
  end

  def parse_brewfile(brewfile)
    log_verbose "Parsing #{brewfile}"
    
    File.readlines(brewfile).each_with_index do |line, index|
      line = line.strip
      
      # Skip comments and empty lines
      next if line.empty? || line.start_with?('#')
      
      case line
      when /^tap\s+["']([^"']+)["']/
        @desired_state['tap'] << $1
      when /^tap\s+([^\s]+)/
        @desired_state['tap'] << $1
      when /^brew\s+["']([^"']+)["']/
        @desired_state['brew'] << $1
      when /^brew\s+([^\s,]+)/
        @desired_state['brew'] << $1
      when /^cask\s+["']([^"']+)["']/
        @desired_state['cask'] << $1
      when /^cask\s+([^\s,]+)/
        @desired_state['cask'] << $1
      when /^mas\s+["']([^"']+)["'],\s*id:\s*(\d+)/
        @desired_state['mas'] << $1
      when /^mas\s+([^,]+),\s*id:\s*(\d+)/
        @desired_state['mas'] << $1
      when /^vscode\s+["']([^"']+)["']/
        @desired_state['vscode'] << $1
      when /^vscode\s+([^\s]+)/
        @desired_state['vscode'] << $1
      else
        log_verbose "Unrecognised line in #{brewfile}:#{index + 1}: #{line}" unless line.match(/^\s*$/)
      end
    end
  end

  def load_actual_state
    log_verbose "Loading actual state from system"
    
    # Load taps
    taps = `brew tap`.strip.split("\n")
    taps.each { |tap| @actual_state['tap'] << tap }
    
    # Load brews
    brews = `brew list --formula`.strip.split("\n")
    brews.each { |brew| @actual_state['brew'] << brew }
    
    # Load casks
    casks = `brew list --cask`.strip.split("\n")
    casks.each { |cask| @actual_state['cask'] << cask }
    
    # Load mas apps (if mas is installed)
    if system('which mas > /dev/null 2>&1')
      mas_apps = `mas list`.strip.split("\n")
      mas_apps.each do |line|
        if line.match(/^\d+\s+(.+?)\s+\(/)
          @actual_state['mas'] << $1
        end
      end
    end
    
    # Load VS Code extensions (if code is installed)
    if system('which code > /dev/null 2>&1')
      vscode_exts = `code --list-extensions`.strip.split("\n")
      vscode_exts.each { |ext| @actual_state['vscode'] << ext }
    end

    log_verbose "Loaded actual state:"
    @actual_state.each do |type, packages|
      log_verbose "  #{type}: #{packages.size} packages"
    end
  end

  def install_packages
    log_verbose "Installing missing packages"
    
    %w[tap brew cask mas vscode].each do |type|
      to_install = @desired_state[type] - @actual_state[type]
      next if to_install.empty?
      
      puts "Installing #{type} packages: #{to_install.to_a.join(', ')}"
      
      unless @options[:dry_run]
        install_packages_of_type(type, to_install.to_a)
      end
    end
  end

  def cleanup_packages
    log_verbose "Cleaning up extra packages"
    
    %w[tap brew cask mas vscode].each do |type|
      to_remove = @actual_state[type] - @desired_state[type] - @protected_packages
      next if to_remove.empty?
      
      puts "Removing #{type} packages: #{to_remove.to_a.join(', ')}"
      
      unless @options[:dry_run]
        if @options[:force] || confirm_removal(type, to_remove.to_a)
          remove_packages_of_type(type, to_remove.to_a)
        end
      end
    end
  end

  def sync_packages
    puts "Synchronising packages..."
    install_packages
    cleanup_packages
  end

  def show_diff
    output = @options[:output] ? File.open(@options[:output], 'w') : $stdout
    
    %w[tap brew cask mas vscode].each do |type|
      to_install = @desired_state[type] - @actual_state[type]
      to_remove = @actual_state[type] - @desired_state[type] - @protected_packages
      
      next if to_install.empty? && to_remove.empty?
      
      output.puts "#{type.upcase}:"
      
      unless to_install.empty?
        output.puts "  To install:"
        to_install.each { |pkg| output.puts "    + #{pkg}" }
      end
      
      unless to_remove.empty?
        output.puts "  To remove:"
        to_remove.each { |pkg| output.puts "    - #{pkg}" }
      end
      
      output.puts ""
    end
    
    output.close if @options[:output]
  end

  def backup_state
    backup_file = @options[:output] || "homebrew-backup-#{Time.now.strftime('%Y%m%d-%H%M%S')}.yaml"
    
    backup_data = {
      'timestamp' => Time.now.iso8601,
      'hostname' => `hostname`.strip,
      'homebrew_version' => `brew --version`.split("\n").first,
      'packages' => {}
    }
    
    @actual_state.each do |type, packages|
      backup_data['packages'][type] = packages.to_a.sort
    end
    
    File.write(backup_file, backup_data.to_yaml)
    puts "Backup saved to: #{backup_file}"
  end

  def install_packages_of_type(type, packages)
    case type
    when 'tap'
      packages.each { |pkg| system("brew tap #{pkg}") }
    when 'brew'
      packages.each { |pkg| system("brew install #{pkg}") }
    when 'cask'
      packages.each { |pkg| system("brew install --cask #{pkg}") }
    when 'mas'
      packages.each { |pkg| system("mas install #{pkg}") }
    when 'vscode'
      packages.each { |pkg| system("code --install-extension #{pkg}") }
    end
  end

  def remove_packages_of_type(type, packages)
    case type
    when 'tap'
      packages.each { |pkg| system("brew untap #{pkg}") }
    when 'brew'
      packages.each { |pkg| system("brew uninstall #{pkg}") }
    when 'cask'
      packages.each { |pkg| system("brew uninstall --cask #{pkg}") }
    when 'mas'
      puts "Warning: MAS apps cannot be automatically uninstalled"
    when 'vscode'
      packages.each { |pkg| system("code --uninstall-extension #{pkg}") }
    end
  end

  def confirm_removal(type, packages)
    puts "Are you sure you want to remove these #{type} packages?"
    packages.each { |pkg| puts "  - #{pkg}" }
    print "Continue? (y/N): "
    
    response = $stdin.gets.chomp.downcase
    %w[y yes].include?(response)
  end

  def log_verbose(message)
    puts message if @options[:verbose]
  end
end

# Run the manager if this file is executed directly
if __FILE__ == $0
  HomebrewManager.new.run
end