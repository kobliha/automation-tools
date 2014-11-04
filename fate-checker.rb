#! /usr/bin/env ruby

require "crack"

require "./lib/fate_api"
require "./lib/authentication"

ONE_DAY = (24 * 60 * 60)
TIME_NOW = Time.now

def build_info(feature)
  last_changed = Time.parse(feature["feature"]["k:versioningsummary"]["k:lastmodifydate"])
  info_provider = feature["feature"]["actor"].select{
    |actor|
    actor["role"] == "infoprovider" && [actor["person"]["email"], actor["person"]["userid"], actor["person"]["fullname"]].include?(@user)
  }.first.fetch("person", {})

  puts "Feature #" << feature["feature"]["k:id"] << ": " << feature["feature"]["title"] << "\n" <<
       "Last changed: " << last_changed.to_s <<
       " (" << ((TIME_NOW - last_changed).to_i / ONE_DAY).to_s << " days ago)\n" <<
       info_provider["fullname"] << " (" << info_provider["email"] << ")\n\n"
end

@user = ARGV[0]
unless ARGV[0]
  warn "Please provide username/email/'full name' argument for search"
  exit 1
end

auth = Authentication.new("~/.fate.conf")

fate_api_url = ARGV[1] || auth.api_url

user = auth.user_for(fate_api_url) || `read -p "#{fate_api_url} login: " uid; echo $uid`.chomp
pass = auth.pass_for(fate_api_url) || `read -s -p "#{fate_api_url} password: " password; echo $password`.chomp

fate = FateAPI.new(user, pass, fate_api_url)

features = Crack::XML.parse(fate.get(@user))

features = features.fetch("k:collection", {}).fetch("k:object", [])
if features.is_a?(Hash)
  build_info(features)
elsif features.is_a?(Array)
  features.each do |feature|
    build_info(feature)
  end
end
