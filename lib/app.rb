require 'data_mapper'
require 'dotenv/load'

require 'incoming/dallas/models'

require 'omniauth/strategies/dallas'
require 'omniauth-dropbox2'

DataMapper::Logger.new($stdout, (ENV['DATAMAPPER_LOG_LEVEL'] || :info).to_sym)
DataMapper.setup(:default, ENV['POSTGRES_URL'])
DataMapper.finalize
DataMapper.auto_upgrade!

