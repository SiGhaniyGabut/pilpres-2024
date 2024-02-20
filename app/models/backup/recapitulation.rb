# frozen_string_literal: true

module Backup
  class Recapitulation
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Attributes::Dynamic

    field :images, type: Array
    field :chart, type: Hash
    field :administrasi, type: Hash
    field :ts, type: String
    field :psu
    field :status_suara
    field :status_adm
    field :frontend_url, type: String
    field :backup_timestamp, type: Time
    field :backup_version, type: Integer
    field :polling_station_id, type: String

    index({ backup_version: 1 })
    index({ polling_station_id: 1 })

    before_create :set_backup_timestamp

    private

    def set_backup_timestamp
      self.backup_timestamp = Time.now
    end
  end
end
