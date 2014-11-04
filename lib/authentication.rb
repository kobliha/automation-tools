#! /usr/bin/env ruby

require "yaml"

class Authentication
  def initialize(auth_file)
    @auth_file = File.expand_path(auth_file)
    @auth = File.exist?(@auth_file) ? parse(@auth_file) : {}
  end

  def user_for(url)
    return nil unless @auth
    @auth.fetch(api_url, {}).fetch("user", nil)
  end

  def pass_for(url)
    return nil unless @auth
    @auth.fetch(api_url, {}).fetch("pass", nil)
  end

  # Returns the Bugzilla API URL if only one URL is present
  # in the auth-file, otherwise returns nil.
  def api_url
    return nil unless @auth

    if @auth.empty?
      warn "There are no API configurations in #{@auth_file}"
      return nil
    end

    if @auth.keys.size > 1
      warn "There are #{@auth.keys.size} API configurations in #{@auth_file}"
      return nil
    end

    @auth.keys.first
  end

  private

  def parse(file)
    warn "Parsing #{file} auth file"
    YAML.load_file(file)
  end
end
