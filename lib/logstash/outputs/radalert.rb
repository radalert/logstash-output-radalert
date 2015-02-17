# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"


class LogStash::Outputs::RadAlert < LogStash::Outputs::Base
  milestone 1
  config_name "radalert"

  # The RadAlert API Key
  config :api_key, :validate => :string, :required => true

  # Heartbeating endpoint
  config :rad_heartbeat_url, :validate => :string, :default => "http://requestb.in/1bormpk1"

  # If set to true - will be an OK heartbeat
  config :event_state, :validate => :string, :default => "OK"

  # how long to expire the heartbeat after, if using one - set to -1 to not set it at all
  config :event_timeout, :validate => :number, :default => 1000

  # what to go to next
  config :event_transition_to, :validate => :string, :default => "UNKNOWN"

  # the check name will be calculated by default
  config :check, :validate => :string
  
  # the summary can just be the parsed log message
  config :summary, :validate => :string, :default => "%{message}"

  # optional event tags - usually use normal tags
  config :event_tags, :validate => :array



  public
  def register
    require 'net/http'
    require 'uri'
    @rad_uri = URI.parse(@rad_heartbeat_url)
    @client = Net::HTTP.new(@rad_uri.host, @rad_uri.port)
    puts "registering"
  end

  public
  def receive(event)
    return unless output?(event)
    puts event.to_json

    rad_message = Hash.new
    rad_message[:api_key] = @api_key
    rad_message[:check] = check_name(event)
    rad_message[:state] = event.sprintf(event['event_state'] ||= @event_state)
    rad_message[:transition_to] = event.sprintf(event['event_transition_to'] ||= @event_transition_to)
    rad_message[:summary] = event.sprintf(event['summary'] ||= @summary)

    if event['event_timeout'] or @event_timeout then
      rad_message[:ttl] = (event['event_timeout'] ||= @event_timeout)
    end

    
    rad_message[:tags] = ['logstash']
    if event['tags'] then      
      rad_message[:tags] += event['tags']
    else 
      #better than just having logstash as tag
      rad_message[:tags] += [rad_message[:check]] 
    end

    # can add tags in in the rad block itself too - why not.
    if @event_tags then
      rad_message[:tags] += @event_tags 
    end

    request = Net::HTTP::Post.new(@rad_uri.path)
    request.body = rad_message.to_json
    response = @client.request(request)

    puts request.body

    @logger.debug("RadAlert Response", :response => response.body)
  end

  def check_name event
    if event['check'] then
      event.sprintf(event['check'])
    else 
      if @check then
        event.sprintf(@check)
      else 
        if event['path'] then      
          "#{event['host']}:#{event['path']}"
        else 
          event['host']
        end
      end
    end
  end




end
