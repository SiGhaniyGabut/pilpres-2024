# frozen_string_literal: true

module Backup
  class Version
    include Mongoid::Document
    include Mongoid::Timestamps

    field :class_name, type: String
    field :version, type: Integer
  end
end
