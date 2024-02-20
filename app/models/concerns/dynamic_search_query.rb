# frozen_string_literal: true

# This module provides the `dynamically search` method for Entities.
module DynamicSearchQuery
  extend ActiveSupport::Concern

  class_methods do
    # This method used to `dynamically search` data based on Query Params.
    # Parameter `searchable_params` is an array of `searchable` fields.
    # Since this method used in `Product` and `Voucher` Entities, we need to define it dynamically too.
    def search(query, searchable_params)
      queries = {}
      case_insensitive_search = %i[nama]

      query.slice(*searchable_params).each do |key, value|
        if case_insensitive_search.include?(key)
          # Possible value is Array of String. These data must be case-insensitive.
          queries[key] = value.is_a?(Array) ? { '$in': value.map { |v| /#{v}/i } } : /#{value}/i
        elsif %w[from_date to_date].include?(key)
          from_date = Time.parse(query['from_date']).beginning_of_day
          to_date = Time.parse(query['to_date']).end_of_day

          queries[:created_at] = from_date..to_date

        else
          queries[key] = value
        end
      end

      where(queries)
    end
  end
end
