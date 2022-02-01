# frozen_string_literal: true

# manage/troubleshoot selinux policies
package %w[policycoreutils-python-utils setroubleshoot-server] do
  only_if { platform_family? 'rhel' }
end
