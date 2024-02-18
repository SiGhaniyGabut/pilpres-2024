# frozen_string_literal: true

class President
  include Mongoid::Document
  include Mongoid::Timestamps
  include GlobalID::Identification

  field :ts, type: String
  field :nama, type: String
  field :nomor_urut, type: String
  field :warna, type: String

  def self.create_all!
    payload = Apis::PresidentCrawler.crawl
    JSON.parse(payload).each { |key, value| create! id: key, **value }
  end
end
