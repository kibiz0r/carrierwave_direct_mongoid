# encoding: utf-8

require 'mongoid'
require 'carrierwave/mongoid'
require 'carrierwave_direct'
require 'carrierwave_direct/validations/active_model'

module CarrierWave
  module Mongoid
    alias_method :mongoid_mount_uploader, :mount_uploader
  end
end

module CarrierWaveDirect
  module Mongoid
    include CarrierWaveDirect::Mount

    def mount_uploader(column, uploader=nil, options={}, &block)
      mongoid_mount_uploader column, uploader, options, &block

      uploader.instance_eval <<-RUBY, __FILE__, __LINE__+1
        include ActiveModel::Conversion
        extend ActiveModel::Naming
      RUBY

      include CarrierWaveDirect::Validations::ActiveModel

      validates_is_attached column if uploader_option(column.to_sym, :validate_is_attached)
      validates_is_uploaded column if uploader_option(column.to_sym, :validate_is_uploaded)
      validates_filename_uniqueness_of column if uploader_option(column.to_sym, :validate_unique_filename)
      validates_filename_format_of column if uploader_option(column.to_sym, :validate_filename_format)
      validates_remote_net_url_format_of column if uploader_option(column.to_sym, :validate_remote_net_url_format)

      self.instance_eval <<-RUBY, __FILE__, __LINE__+1
        attr_accessor   :skip_is_attached_validations
        attr_accessible :key, :remote_#{column}_net_url
      RUBY

      mod = Module.new
      include mod
      mod.class_eval <<-RUBY, __FILE__, __LINE__+1
        def filename_valid?
          if has_#{column}_upload?
            self.skip_is_attached_validations = true
            valid?
            self.skip_is_attached_validations = false
            column_errors = errors[:#{column}]
            errors.clear
            column_errors.each do |column_error|
              errors.add(:#{column}, column_error)
            end
            errors.empty?
          else
            true
          end
        end
      RUBY
    end
  end
end

Mongoid::Document::ClassMethods.send :include, CarrierWaveDirect::Mongoid
