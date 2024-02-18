# frozen_string_literal: true

module Apis
  # This class is used as Parent class for Crawler classes
  class Crawler
    include LontaraUtilities
    include Constants

    def self.request(url, options = {})
      JSON.parse HTTPClient.get(url: "#{url}.json", timeout: 30, headers:, **options).body
    end

    def self.headers
      {
        user_agent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0',
        accept: 'application/json',
      }
    end

    private_class_method :request, :headers
  end
end
