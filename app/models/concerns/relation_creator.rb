# frozen_string_literal: true

module RelationCreator
  extend ActiveSupport::Concern

  class_methods do
    def batch_process(size = 1000, query: -> { all }, &block)
      page = 1
      loop do
        records = instance_exec(&query).limit(size).skip(size * (page - 1))

        break if records.empty?

        records.each(&block)
        page += 1
      end
    end
  end

  included do
    def create_relations(relation, payload, batch_size: 1000)
      create_relations! relation, payload, batch_size:, next_on_error: true
    end

    def create_relations!(relation, payload, next_on_error:, batch_size: 1000)
      payload.each_slice(batch_size) do |batch_data|
        create_relation!(relation, batch_data)
      rescue Mongoid::Errors::Validations, Mongo::Error::OperationFailure => error
        next if next_on_error

        raise error
      end
    end

    def create_relation!(relation, data)
      model(relation).create! reject_payload_if_exists(relation, transforms(data))
    end

    private

    def reject_payload_if_exists(relation, data)
      hash_no_id = data.is_a?(Hash) && !data.key?('id')
      array_of_hash_no_id = data.is_a?(Array) && !data.any? { |dt| dt.is_a?(Hash) && dt.key?('id') }

      return data if hash_no_id || array_of_hash_no_id

      existing_ids = model(relation).where(:id.in => data.map { |dt| dt['id'] }).pluck(:id)
      data.reject { |dt| existing_ids.include? dt['id'] }
    end

    def queue(relation, stock)
      [relation, rand(stock), 'crawler'].join('_')
    end

    def model(relation)
      send(relation)
    end

    def transforms(data)
      return data.map { |d| stringify_value(deep_remove_unuseful_keys(d)) } if data.is_a?(Array)

      stringify_value(deep_remove_unuseful_keys(data))
    end

    def stringify_value(data)
      data.deep_transform_values(&:to_s)
    end

    # Remove unuseful keys from the payload, like 'null', etc
    def deep_remove_unuseful_keys(data, keys: ['null'])
      data.transform_values do |v|
        v.is_a?(Hash) ? deep_remove_unuseful_keys(v, keys: keys) : v
      end.reject { |k| keys.include?(k) }.to_h
    end
  end
end
