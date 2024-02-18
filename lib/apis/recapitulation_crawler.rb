# frozen_string_literal: true

module Apis
  class RecapitulationCrawler < PlaceCrawler
    def self.api_url(path)
      API_URL + RECAPITULATION_URL + path
    end
  end
end
