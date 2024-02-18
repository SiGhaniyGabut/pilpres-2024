# frozen_string_literal: true

module RecapitulationRelationCreator
  extend ActiveSupport::Concern
  include RelationCreator

  included do
    # This method uses create_recapitulation! because each recapitulation on each places is a single document
    def create_async_recapitulation!(relation, payload, queue_stock: 15)
      Jobs::RecapitulationCrawler.set(queue: queue(relation, queue_stock))
                                 .perform_async(to_global_id.to_s, relation, payload)
    end

    def create_recapitulation!(relation, data)
      create_relation!(relation, data)
    end
  end
end
