#! /usr/bin/env ruby

require "yaml"

class Authentication
  AUTH_FILE = File.expand_path("~/.bugzilla.conf")

  def initialize
    @auth = File.exist?(AUTH_FILE) ? parse(AUTH_FILE) : {}
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
      warn "There are no API configurations in #{AUTH_FILE}"
      return nil
    end

    if @auth.keys.size > 1
      warn "There are #{@auth.keys.size} API configurations in #{AUTH_FILE}"
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
