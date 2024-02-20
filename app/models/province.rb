# frozen_string_literal: true

# Province (Provinsi) Model class
class Province
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

  has_many :states, inverse_of: :province, dependent: :destroy

  after_create :create_states

  def self.synchronize_places
    Jobs::PlaceRunner.perform_async 'Province', 'create_all_states'
  end

  def self.create_all!
    payload = Apis::PlaceCrawler.crawl '0'
    JSON.parse(payload).each { |province| create! province.deep_transform_values(&:to_s) }
  end

  def self.create_all_states
    batch_process(query: -> { order_by(created_at: -1) }, &:create_states)
  end

  def create_states
    create_async_relations 'states', kode
  end
end
