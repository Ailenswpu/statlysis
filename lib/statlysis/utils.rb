# encoding: UTF-8

module Statlysis
  module Utils
    class << self
      def is_activerecord?(data); data.is_a?(ActiveRecordDataset) || !!((data.try(:included_modules) || []).index(ActiveRecord::Store)) end
      def is_mongoid?(data); data.is_a?(MongoidDataset) || !!((data.try(:included_modules) || []).index(Mongoid::Document)) end
    end
  end
end
