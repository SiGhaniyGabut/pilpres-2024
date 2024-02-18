# frozen_string_literal: true

# District (Kecamatan) Model class
class District
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification
  include PlaceRelationCreator

  field :nama, type: String
  field :kode, type: String
  field :tingkat, type: String
  field :url_path, type: String

  validates_uniqueness_of :kode

  belongs_to  :state, inverse_of: :districts
  has_many    :villages, inverse_of: :district, dependent: :destroy

  after_create :create_villages

  def self.synchronize_places
    Jobs::PlaceRunner.perform_async 'District', 'create_all_villages'
  end

  def self.create_all_villages
    batch_process(&:create_villages)
  end

  def create_villages
    create_async_relations 'villages', url_path, queue_stock: 5
  end
end
