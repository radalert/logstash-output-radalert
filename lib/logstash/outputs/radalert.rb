# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"


class LogStash::Outputs::RadAlert < LogStash::Outputs::Base
  milestone 1
  config_name "radalert"

  # The RadAlert API Key
  config :api_key, :validate => :string, :required => true

  # Heartbeating endpoint
  config :pdurl, :validate => :string, :default => "http://requestb.in/1lnaxql1"

  # If it is a critical or ok event
  config :state, :validate => :string, :default => "CRITICAL"

  config :check, :validate => :string, :default => "Logstash %{host}"
  
  config :summary, :validate => :string, :default => "%{message}"


  public
  def register
    require 'net/http'
    require 'uri'
    @pd_uri = URI.parse(@pdurl)
    @client = Net::HTTP.new(@pd_uri.host, @pd_uri.port)
    puts "registering"
  end

  public
  def receive(event)
    return unless output?(event)
    puts "nizzle"
    rad_message = Hash.new
    rad_message[:api_key] = @api_key
    rad_message[:check] = event.sprintf(@check)
    rad_message[:state] = event.sprintf(@state)
    rad_message[:summary] = event.sprintf(@summary)
    rad_message[:tags] =  @tags if @tags
    request = Net::HTTP::Post.new(@pd_uri.path)
    request.body = rad_message.to_json
    response = @client.request(request)
    @logger.debug("RadAlert Response", :response => response.body)


  end





end
