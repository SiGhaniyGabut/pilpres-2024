# frozen_string_literal: true

module Apis
  class PlaceCrawler < Crawler
    def self.crawl(path)
      request(api_url(path))
    end

    def self.api_url(path)
      API_URL + PLACES_URL + path
    end
  end
end
