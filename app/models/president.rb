# frozen_string_literal: true

class President
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification
  include DynamicSearchQuery

  field :ts, type: String
  field :nama, type: String
  field :nomor_urut, type: String
  field :warna, type: String

  index({ nomor_urut: 1 }, { unique: true })

  def self.create_all!
    payload = Apis::PresidentCrawler.crawl
    JSON.parse(payload).each { |key, value| create! id: key, **value }
  end
end
