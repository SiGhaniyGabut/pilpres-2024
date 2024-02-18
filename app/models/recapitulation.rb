# frozen_string_literal: true

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

  belongs_to :polling_station, inverse_of: :recapitulations

  before_create :set_frontend_url

  private

  def set_frontend_url
    self.frontend_url = url
  end

  def url
    Constants::FRONTEND_URL + polling_station.url_path
  end
end
