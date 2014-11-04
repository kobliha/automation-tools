#! /usr/bin/env ruby

require "./lib/bugzilla_api"
require "./lib/needinfo_email"
require "./lib/authentication"

def self.usage
  puts "ruby #{__FILE__} e-mail_of_the_needinfo_requestee [bugzilla_api_url]"
end

requestee = ARGV[0]
unless requestee
  usage
  exit 1
end

bugzilla = BugzillaSearch.new
auth = Authentication.new("~/.bugzilla.conf")

if !bugzilla.api_url
  bugzilla.api_url = auth.api_url || ARGV[1] || bugzilla.default_api_url
end

user = auth.user_for(bugzilla.api_url) || `read -p "#{bugzilla.api_url} login: " uid; echo $uid`.chomp
pass = auth.pass_for(bugzilla.api_url) || `read -s -p "#{bugzilla.api_url} password: " password; echo $password`.chomp

bugzilla.set_auth(user, pass)

ids = bugzilla.needinfo_bugs(requestee)
bugzilla.warn "Found bugs: #{ids}"

if ids != []
  bugs = bugzilla.bugs_details(ids)
  e_mail = NeedinfoEMail.new(bugs, bugzilla)
  puts e_mail.build
else
  bugzilla.warn "No bugs for #{requestee}"
end

#
# ruby needinfo-checker.rb requestee@suse.com | mailx -r yast-ci@opensuse.org -s "Bugzilla: Information Still Needed" requestee@suse.com
#
