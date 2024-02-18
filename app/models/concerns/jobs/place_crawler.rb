# frozen_string_literal: true

module Jobs
  class PlaceCrawler
    include Sidekiq::Job

    sidekiq_options retry: 7, retry_queue: 'low'

    def perform(place_gid, relation, path, next_on_error)
      place_model(place_gid).create_relations! relation, payload(path), next_on_error:
    end

    private

    def place_model(global_id)
      GlobalID::Locator.locate global_id
    end

    def payload(path)
      Apis::PlaceCrawler.crawl path
    end
  end
end
