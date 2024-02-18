# frozen_string_literal: true

module Apis
  class PresidentCrawler < Crawler
    def self.crawl
      request(api_url)
    end

    def self.api_url
      API_URL + PRESIDENT_URL
    end
  end
end
