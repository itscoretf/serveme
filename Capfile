# Load DSL and set up stages
require 'capistrano/setup'

require "capistrano/scm/git"
install_plugin Capistrano::SCM::Git

# Include default deployment tasks
require 'capistrano/deploy'

require 'capistrano/maintenance'

require 'capistrano/rvm'
require 'capistrano/bundler'
require 'capistrano/rails'
require 'capistrano/faster_assets'

require 'capistrano/puma'
require 'capistrano/sidekiq'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
