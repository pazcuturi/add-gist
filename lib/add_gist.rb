require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'OpenSSL'
require 'find'
require 'dotenv/load'
require 'byebug'
require 'stringio'
require 'net/http/uploadprogress'

module AddGist
  GISTS_URL = 'https://api.github.com/gists'.freeze
  HTML_URL = 'html_url'.freeze
  TRUE = 'true'.freeze

  def self.upload_files(path, options = {})
    files = read_files(path)
    return if files.nil? || files.empty?

    response = send_request(files, options)

    if response.is_a?(Net::HTTPCreated)
      html_url = JSON.parse(response.body)[HTML_URL]
      puts "Gist created successfully! \nAccess URL: #{html_url}"
    else
      puts response.code
      puts JSON.parse(response.body)['message']
    end
  end

  def self.read_files(pwd = Dir.pwd)
    files = {}
    Find.find(pwd) do |path|
      files.merge!(File.basename(path) => { 'content': File.open(path, 'r+').read }) unless File.directory?(path)
    end
    files
  rescue Errno::ENOENT
    puts "The path '#{pwd}' does not exist."
  end

  def self.send_request(files, options = {})
    http, req = build_request

    body = {
      description: options[:description].to_s,
      public: options[:is_public],
      files: files
    }.to_json.to_s

    io = StringIO.new(body)
    req.content_length = io.size
    req.body_stream = io

    Net::HTTP::UploadProgress.new(req) do |progress|
      puts "Uploaded: #{calculate_progress(req.content_length, progress.upload_size).round(1)}%"
    end

    begin
      http.request(req)
    rescue StandardError => e
      puts %(The following error occurred: '#{e.message}'. \nWould you like to resume (y/n)?)
      answer = $stdin.gets.chomp
      if answer[0].casecmp?('y')
        retry
      else
        exit
      end
    end
  end

  def self.build_request
    uri = URI.parse(GISTS_URL)
    uri.query = URI.encode_www_form(access_token: ENV['ACCESS_TOKEN'])
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    [http, request]
  end

  def self.calculate_progress(total, amount)
    amount * 100.0 / total
  end

  private_class_method :read_files, :send_request, :calculate_progress, :build_request
end

return unless $PROGRAM_NAME == __FILE__

if ARGV.length != 3
  puts %(Usage: ruby addGist.rb <dirname/filename> <public? (boolean)> <"gist description">)
  exit
end

path = ARGV[0]
is_public = ARGV[1].casecmp?(AddGist::TRUE)
gist_description = ARGV[2]
AddGist.upload_files(path, is_public: is_public, description: gist_description)
