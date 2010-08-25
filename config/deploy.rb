set :user, 'rails'
role :production, "hashref.com"

def execute_in_rc(method, command)
  send(method, "export PATH=/opt/ruby-enterprise-1.8.7-2010.02/bin:/usr/local/bin:/usr/bin:/bin; export RAILS_ENV=production; cd /home/rails/rails-contributors; #{command}")
end

def run_in_rc(command)
  execute_in_rc(:run, command)
end

def stream_in_rc(command)
  execute_in_rc(:stream, command)  
end

namespace :rc do
  task :tail, :roles => :production do
    stream_in_rc "tail -f log/production.log"
  end

  task :pull, :roles => :production do
    run_in_rc "git pull"
  end

  task :delete_all_contributions, :roles => :production do
    run_in_rc %{script/runner 'Contribution.delete_all'}
  end

  task :restart, :roles => :production do
    run_in_rc "touch tmp/restart.txt"
  end

  task :expire_caches, :roles => :production do
    run_in_rc "rm -f public/stylesheets/all.css"
    run_in_rc "rm -f public/javascripts/all.js"
    
    # Inspired by John Leach's
    # http://blog.brightbox.co.uk/posts/expiring-an-entire-page-cache-tree-atomically
    suffix = Time.now.to_i
    run_in_rc "mv tmp/cache/views tmp/cache/views_#{suffix}"
    run_in_rc "rm -rf tmp/cache/views_#{suffix}"
  end

  task :deploy do
    pull
    update_repo
    restart
    expire_caches
  end

  task :maintenance_on, :roles => :production do
    run_in_rc "cp public/system/maintenance.html.deleteme public/system/maintenance.html"
  end

  task :maintenance_off, :roles => :production do
    run_in_rc "rm public/system/maintenance.html"
  end
end
