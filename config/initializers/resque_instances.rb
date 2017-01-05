require 'pathname'
if Rails.env.test?
  RESQUES = Resques.new([
    ResqueInstance.new(
      name: "localhost", 
      resque_data_store: Resque::DataStore.new(Redis::Namespace.new(:resque,redis: Redis.new)),
      stale_worker_seconds: (ENV['RESQUE_BRAIN_STALE_WORKER_SECONDS'] || '3600').to_i
    )
  ])
else
  if ENV['CONFIG_FILE']
    configfile = Pathname.new(ENV['CONFIG_FILE']).absolute? ? ENV['CONFIG_FILE'] : Pathname.new(Rails.root).join(ENV['CONFIG_FILE']).to_s
    RESQUES = Resques.from_config(configfile)
  else
    RESQUES = Resques.from_environment
  end
end
