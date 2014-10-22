#! /usr/bin/env ruby

require "uri"
require "net/http"
require "nokogiri"
require "xmlsimple"
require "pp"

class BugzillaAPI
  SUSE_BUGZILLA = 'https://bugzilla.suse.com'

  def initialize(user, pass, bugzilla_api = SUSE_BUGZILLA)
    @bugzilla_url = bugzilla_api
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
    URI("#{@bugzilla_url}/#{script_name}?#{uri_params}")
  end

  private

  def get(script_name, params)
    uri = build_uri(script_name, params)

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

class NeedinfoEMail
  def initialize(bugs, bugzilla)
    @bugs = bugs
    @bugzilla = bugzilla
    @script_contact = "yast-devel@opensuse.org"
  end

  def build
    message = "Hi,\n\n" <<
      "Bugzilla is waiting for your response in #{@bugs.size} #{@bugs.size > 1 ? 'bugs' : 'bug'}:\n\n"

    @bugs.each do |bug|
      message << "  * Bug #" << bug["bug_id"][0] << ": " << bug["short_desc"][0] << "\n"
      message << "    Please answer at: " << @bugzilla.build_uri("show_bug.cgi", {"id" => bug["bug_id"][0]}).to_s << "\n"
      message << "\n"
    end

    message << "Thank you!\n"
    message << "\n"

    message << footer
  end

  private

  def footer
    "-- \n\n" <<
    "This e-mail has been automatically generated by #{__FILE__} script.\n" <<
    "Contact #{@script_contact} for more details."
  end
end

def self.usage
  puts "ruby #{__FILE__} e-mail_of_the_needinfo_requestee"
end

user = `read -p "Bugzilla login: " uid; echo $uid`.chomp
pass = `read -s -p "Password: " password; echo $password`.chomp

requestee = ARGV[0]
unless requestee
  usage
  exit 1
end

bugzilla = BugzillaSearch.new(user, pass)
ids = bugzilla.needinfo_bugs(requestee)
  bugzilla.warn "Found bugs: #{ids}"

if ids != []
  bugs = bugzilla.bugs_details(ids)
  e_mail = NeedinfoEMail.new(bugs, bugzilla)
  puts e_mail.build
else
  bugzilla.warn "No bugs for #{requestee}"
  exit 2
end

#
# ruby needinfo-checker.rb requestee@suse.com | mailx -r yast-ci@opensuse.org -s "Bugzilla: Information Still Needed" requestee@suse.com
#
