#! /usr/bin/env ruby

class BugzillaEmail
  DEFAULT_CONTACT = "yast-devel@opensuse.org"
  PROJECT_HOME_PAGE = "https://github.com/kobliha/automation-tools"

  def initialize(bugs, bugzilla, contact_email = DEFAULT_CONTACT)
    @bugs = bugs
    @bugzilla = bugzilla
    @contact_email = contact_email
  end

  def build
    message = header

    @bugs.each do |bug|
      message << "  * Bug #" << bug["bug_id"][0] << ": " << bug["short_desc"][0] << "\n"
      message << "    Please answer at: " << @bugzilla.build_uri("show_bug.cgi", {"id" => bug["bug_id"][0]}).to_s << "\n"
      message << "\n"
    end

    message << footer
  end

  private

  def header
    "Hi,\n\n" <<
      "Bugzilla is waiting for your response in #{@bugs.size} #{@bugs.size > 1 ? 'bugs' : 'bug'}:\n\n"
  end

  def footer
    "Thank you!\n\n" <<
    "-- \n\n" <<
    "This e-mail has been automatically generated by #{__FILE__} script from\n" <<
    "#{PROJECT_HOME_PAGE} project.\n" <<
    "Contact #{@contact_email} for more details."
  end
end
