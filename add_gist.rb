require 'rubygems'
require 'net/http'
require 'uri'
require 'json'
require 'OpenSSL'
require 'find'
require 'dotenv/load'

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

  def self.build_request
    uri = URI.parse(GISTS_URL)
    uri.query = URI.encode_www_form(access_token: ENV['ACCESS_TOKEN'])

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(uri.request_uri)
    [http, request]
  end

  def self.send_request(files, options = {})
    http, request = build_request

    request.body = {
      description: options[:description].to_s,
      public: options[:is_public],
      files: files
    }.to_json

    http.request(request)
  end

  private_class_method :read_files, :send_request, :build_request
end

if ARGV.length != 3
  puts %(Usage: ruby addGist.rb <dirname/filename> <public? (boolean)> <"gist description">)
  exit
end

path = ARGV[0]
is_public = ARGV[1].casecmp?(AddGist::TRUE)
gist_description = ARGV[2]

AddGist.upload_files(path, is_public: is_public, description: gist_description)
