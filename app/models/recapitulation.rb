# frozen_string_literal: true

class Recapitulation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include GlobalID::Identification
  include DynamicSearchQuery
  include RecapitulationRelationCreator

  field :images, type: Array
  field :chart, type: Hash
  field :administrasi, type: Hash
  field :ts, type: String
  field :psu
  field :status_suara
  field :status_adm
  field :frontend_url, type: String

  belongs_to :polling_station, inverse_of: :recapitulations, index: true

  before_create :set_frontend_url

  def self.run_backup
    Jobs::BackupRunner.perform_async 'Recapitulation', 'backup_all!'
  end

  def self.backup_all!
    backup = Backup::Version.find_or_create_by(class_name: self) { |b| b.version = 1 if b.version.nil? }
    version = backup.version

    batch_process { |recapitulation| recapitulation.create_async_backup(version, %w[_id chart], queue_stock: 5) }

    backup.inc(version: 1)
  end

  def create_async_backup(version, exclude_attrs = [], queue_stock: 2)
    Jobs::BackupCrawler.set(queue: "backup_#{rand(queue_stock)}_crawler")
                       .perform_async(to_global_id.to_s, version, exclude_attrs, true)
  end

  def create_backup!(version, exclude_attrs = [], destroy_old: false)
    backup_model = "Backup::#{self.class}".constantize
    backup_model.create!(attributes.excluding(exclude_attrs).merge(backup_version: version))

    destroy! if destroy_old
  end

  private

  def set_frontend_url
    self.frontend_url = url
  end

  def url
    Constants::FRONTEND_URL + polling_station.url_path
  end
end
