# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"


class LogStash::Outputs::RadAlert < LogStash::Outputs::Base
  milestone 1
  config_name "radalert"

  # The RadAlert API Key
  config :api_key, :validate => :string, :required => true


  config :pdurl, :validate => :string, :default => "http://requestb.in/1lnaxql1"

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
    request = Net::HTTP::Post.new(@pd_uri.path)
    request.body = event.to_json
    response = @client.request(request)
    @logger.debug("PD Response", :response => response.body)


  end





end
