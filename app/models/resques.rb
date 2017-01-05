require 'redis'
require 'uri'
require 'yaml'
require 'redis/namespace'
require 'resque/data_store'

# Repository of configured resques.  In general, you want in an initializer:
#
#     RESQUES = Resques.from_environment
#
# And then use `RESQUES` to access the configured resques.  
class Resques
  # Parses the environment, yielding each configured instance to the block
  def self.from_environment
    self.new(String(ENV["RESQUE_BRAIN_INSTANCES"]).split(/\s*,\s*/).map { |instance_name|
      uri = URI(ResqueUrl.new(instance_name).url)
      if (uri.path)
        namespace = uri.path.gsub(/^\//,'')
        uri.path = ''
        redis = Redis::Namespace.new(namespace ,redis: Redis.new(url: uri.to_s))
      else
        redis = Redis::Namespace.new(:resque,redis: Redis.new(url: ResqueUrl.new(instance_name).url))
      end
      ResqueInstance.new(name: instance_name, resque_data_store: Resque::DataStore.new(redis))
    })
  end

  def self.from_config(filename)
    resques = YAML.load_file(filename)
    self.new(resques.map { |instance|
      namespace = instance['namespace'] || :resque
      sentinels = []
      sentinels = instance['sentinels'].map{|s| u = URI(s); {:host => u.host, :port => u.port || 26379}} if instance['sentinels']
      redis = Redis::Namespace.new(namespace, redis: Redis.new(:url => instance['url'], :sentinels => sentinels))
      ResqueInstance.new(name: instance['name'], resque_data_store: Resque::DataStore.new(redis))
    })
  end

  def initialize(instances)
    @instances = Hash[instances.map { |instance|
      [instance.name,instance]
    }]
  end

  def all
    @instances.values
  end

  def find(name)
    @instances[name]
  end

end
