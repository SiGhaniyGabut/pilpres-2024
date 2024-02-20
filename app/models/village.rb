# frozen_string_literal: true

# Village (Kelurahan) Model class
class Village
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification
  include DynamicSearchQuery
  include PlaceRelationCreator

  field :nama, type: String
  field :kode, type: String
  field :tingkat, type: String
  field :url_path, type: String

  index({ kode: 1 }, { unique: true })

  validates_uniqueness_of :kode

  belongs_to  :district, inverse_of: :villages, index: true
  has_many    :polling_stations, inverse_of: :village, dependent: :destroy

  after_create :create_polling_stations

  def self.synchronize_places
    Jobs::PlaceRunner.perform_async 'Village', 'create_all_polling_stations'
  end

  def self.create_all_polling_stations
    batch_process(&:create_polling_stations)
  end

  def create_polling_stations
    create_async_relations 'polling_stations', url_path, queue_stock: 8
  end
end
