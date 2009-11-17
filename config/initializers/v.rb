if `which git`.strip.blank?
  executables = %w[ /usr/local/git/bin/git /opt/local/bin/git ]

  V::Adapters::Git::Environment.
      which_git = executables.find { |exe| File.executable? exe }
end