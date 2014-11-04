#! /usr/bin/env ruby

require "uri"
require "net/http"
require "nokogiri"
require "xmlsimple"

class BugzillaAPI
  SUSE_BUGZILLA = 'https://bugzilla.suse.com'

  attr_reader :api_url

  def set_auth(user, pass)
    @user = user
    @pass = pass
  end

  def search(params)
    warn "Using search for #{params}"
    get("buglist.cgi", params)
  end

  def bugs_info(bugs)
    get("show_bug.cgi", {'ctype' => 'xml', 'excludefield' => 'attachmentdata', 'id' => bugs.join(',')})
  end

  def warn(msg)
    $stderr.puts "#{self.class}: #{msg}"
  end

  def build_uri(script_name, params)
    uri_params = params.map{|k,v| URI.escape(k) + '=' + URI.escape(v)}.join('&')
    URI("#{@api_url}/#{script_name}?#{uri_params}")
  end

  def api_url=(url)
    warn "API URL: #{url}"
    @api_url = url
  end

  def default_api_url
    SUSE_BUGZILLA
  end

  private

  def get(script_name, params)
    uri = build_uri(script_name, params)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"

    request = Net::HTTP::Get.new(uri.request_uri)
    if !["", nil].include?(@user) && !["", nil].include?(@pass)
      warn "Using bugzilla auth"
      request.basic_auth @user, @pass
    end

    warn "Downloading details from #{uri}"
    res = http.request(request)

    case res
    when Net::HTTPRedirection
      raise "Redirected to #{res['location']}"
    when Net::HTTPSuccess
      res.body
    else
      raise "Error code #{res.value} not solved"
    end
  end
end

class BugzillaSearch < BugzillaAPI
  def needinfo_bugs(needinfo_from_who)
    params = {
     'f1' => 'requestees.login_name',
     'o1' => 'equals',
     'v1' => needinfo_from_who,

     'f2' => 'flagtypes.name',
     'o2' => 'equals',
     'v2' => 'needinfo?',

     'list_id' => rand.to_s,
     'query_format' => 'advanced',
     'resolution' => '---',

     'columnlist' => 'id',
    }

    needinfo_bugs = search(params)
    html_doc = Nokogiri::HTML(needinfo_bugs)
    # Find all 'td' elements with bug numbers
    rows = html_doc.xpath("//table[contains(@class, 'bz_buglist')]//tr[contains(@class, 'bz_bugitem')]//td[contains(@class, 'bz_id_column')]")
    rows.map(&:text).map(&:strip)
  end

  def bugs_details(ids)
    xml_doc = bugs_info(ids)
    XmlSimple.xml_in(xml_doc).fetch('bug',[])
  end
end
