# frozen_string_literal: true

# Polling Station (TPS) Model class
class PollingStation
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification
  include DynamicSearchQuery
  include RecapitulationRelationCreator

  field :nama, type: String
  field :kode, type: String
  field :tingkat, type: String
  field :url_path, type: String

  index({ kode: 1 }, { unique: true })

  validates_uniqueness_of :kode

  belongs_to  :village, inverse_of: :polling_stations, index: true
  has_many    :recapitulations, inverse_of: :polling_station, dependent: :destroy

  # after_create :recapitulate_voters!

  def self.synchronize_recapitulations
    Jobs::RecapitulationRunner.perform_async 'PollingStation', 'recapitulate_all_voters!'
  end

  def self.recapitulate_all_voters!
    batch_process(&:recapitulate_voters!)
  end

  def recapitulate_voters!
    create_async_recapitulation! 'recapitulations', url_path
  end
end
