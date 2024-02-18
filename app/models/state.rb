# frozen_string_literal: true

# State (Kota/Kabupaten) Model class
class State
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification
  include PlaceRelationCreator

  field :nama, type: String
  field :kode, type: String
  field :tingkat, type: String
  field :url_path, type: String

  validates_uniqueness_of :kode

  belongs_to  :province, inverse_of: :states
  has_many    :districts, inverse_of: :state, dependent: :destroy

  after_create :create_districts

  def self.synchronize_places
    Jobs::PlaceRunner.perform_async 'State', 'create_all_districts'
  end

  def self.create_all_districts
    batch_process(&:create_districts)
  end

  def create_districts
    create_async_relations 'districts', url_path, queue_stock: 3
  end
end
