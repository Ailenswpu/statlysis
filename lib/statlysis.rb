# encoding: UTF-8
#
# Sequel的操作均需通过Symbol
#
# 删除匹配的统计表
# Statlysis.sequel.tables.select {|i| i.to_s.match(//i) }.each {|i| Statlysis.sequel.drop_table i }

# TODO Statlysis.sequel.tables.map {|t| eval "class ::#{t.to_s.camelize} < ActiveRecord::Base; self.establish_connection Statlysis.database_opts; self.table_name = :#{t}; end; #{t.to_s.camelize}" }

require "active_support/all"
require "active_support/core_ext"
require 'active_support/core_ext/module/attribute_accessors.rb'
require 'active_record'
require 'activerecord_idnamecache'
%w[yaml sequel mongoid].map(&method(:require))

# Fake a Rails environment
module Rails; end

require 'statlysis/constants'

module Statlysis
  class << self
    def setup &blk
      raise "Need to setup proc" if not blk

      logger.info "Start to setup Statlysis"
      time_log do
        self.config.instance_exec(&blk)
      end
      logger.info
    end

    def time_log text = nil
      t = Time.now
      logger.info text if text
      yield if block_given?
      logger.info "Time spend #{(Time.now - t).round(2)} seconds."
      logger.info "-" * 42
    end

    # delagate config methods to Configuration
    def config; Configuration.instance end
    require 'active_support/core_ext/module/delegation.rb'
    [:sequel, :set_database, :check_set_database,
     :default_time_zone,
     :set_tablename_default_pre, :tablename_default_pre
    ].each do |sym|
      delegate sym, :to => :config
    end

    attr_accessor :logger
    Statlysis.logger ||= Logger.new($stdout)

    def source_to_database_type; @_source_to_database_type ||= {} end


    def daily; CronSet.new(Statlysis.config.day_crons) end
    def hourly; CronSet.new(Statlysis.config.hour_crons) end

  end

end

require 'statlysis/utils'
require 'statlysis/configuration'
require 'statlysis/common'
require 'statlysis/timeseries'
require 'statlysis/clock'
require 'statlysis/rake'
require 'statlysis/cron'
require 'statlysis/cron_set'
require 'statlysis/similar'
require 'statlysis/multiple_dataset'

module Statlysis
  require 'short_inspect'
  ShortInspect.apply_to Cron, CronSet, MultipleDataset
  ShortInspect.apply_minimal_to ActiveRecord::Relation # lazy load
end


# load rake tasks
module Statlysis
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../statlysis/rake.rb', __FILE__)
    end
  end
end if defined? Rails::Railtie
