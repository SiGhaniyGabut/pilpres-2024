# frozen_string_literal: true

module Jobs
  class RecapitulationCrawler < PlaceCrawler
    # Using create_relation because each recapitulation is a single document
    def perform(place_gid, relation, path)
      place_model(place_gid).create_recapitulation! relation, payload(path)
    end

    private

    def payload(path)
      Apis::RecapitulationCrawler.crawl path
    end
  end
end
