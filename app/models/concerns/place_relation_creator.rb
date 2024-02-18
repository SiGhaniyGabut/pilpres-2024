# frozen_string_literal: true

module PlaceRelationCreator
  extend ActiveSupport::Concern
  include RelationCreator

  included do
    def create_async_relations(relation, payload, queue_stock: 1)
      create_async_relations! relation, payload, queue_stock:, next_on_error: true
    end

    def create_async_relations!(relation, payload, next_on_error:, queue_stock: 1)
      Jobs::PlaceCrawler.set(queue: queue(relation, queue_stock))
                        .perform_async(to_global_id.to_s, relation, payload, next_on_error)
    end
  end
end
