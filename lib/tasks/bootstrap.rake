def app_dir
  dir = File.join File.dirname(__FILE__), %w[ .. .. ]
  File.expand_path dir
end

desc 'Run bootstrap procedure for FarmFacts'
task :bootstrap do
  git_excludes = File.join app_dir, %w[ .git info exclude ]
  excludes = File.read git_excludes
  excludes.include? 'config/database.yml' or
      File.open(git_excludes, 'a') { |f| f.puts 'config/database.yml' }

  database_yml = File.join app_dir, %w[ config database.yml ]
  system ENV['EDITOR'] || 'vi', '-w', database_yml
  File.exists? database_yml or
      raise RuntimeError, 'Could not find database.yml!'

  Rake::Task['gems:build'].invoke
  Rake::Task['db:create'].invoke
  Rake::Task['db:migrate'].invoke
end
