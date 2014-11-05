#! /usr/bin/env ruby

require "uri"
require "net/http"
require "cgi"
require "crack"

class FateAPI
  def initialize(user, pass, url)
    @user = user
    @pass = pass
    @url = url
  end

  def get(user)
    escaped_params = CGI.escape(build_search(user))
    warn "\n" << escaped_params << "\n"
    uri = URI(@url + "feature?query=" + escaped_params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"

    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth @user, @pass

    warn "Downloading details from #{uri}"
    res = http.request(request)

    case res
    when Net::HTTPRedirection
      raise "Redirected to #{res['location']}"
    when Net::HTTPSuccess
      features = Crack::XML.parse(res.body)
      features.fetch("k:collection", {}).fetch("k:object", [])
    else
      raise "Error code #{res.value} not solved"
    end
  end

  private

  def build_search(user)
    "/feature[" <<
      "productcontext[" <<
        "not (status[done or rejected or duplicate or unconfirmed or validation])" <<
      "] " <<
      "and " <<
      "actor[" <<
        "(person/userid='#{user}' or person/email='#{user}' or person/fullname='#{user}')" <<
        "and role='infoprovider'" <<
      "]" <<
    "]"
  end

end
