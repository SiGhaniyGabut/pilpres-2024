# frozen_string_literal: true

module Fraud
  class PollingStationChecker
    def self.check(max_voters = 300, mode: :max_voters, station_sample: 100, detail: true)
      # Fetch all recapitulations
      recapitulations = recapitulations_by_mode(mode).limit(station_sample)

      # Initialize a hash to store the recapitulations grouped by president's name
      grouped_recapitulations = Hash.new { |hash, key| hash[key] = [] }

      # Iterate over the recapitulations
      recapitulations.each do |recapitulation|
        # Iterate over the keys in the 'chart' field
        recapitulation.chart.each do |key, value|
          president = President.find(key)

          # Exit chart iteration if the president is nil, or the value is less than 300
          next unless president && data_fraud?(max_voters, recapitulation, value, mode)

          # Add the recapitulation to the group for this president
          # if the value is greater than 300 and a president was found
          grouped_recapitulations[president.nama] << recapitulation.attributes
        end
      end

      # Convert the grouped recapitulations to an array of hashes
      grouped_recapitulations.map do |president_name, recapitulations|
        { president: president_name, fraud_mode: mode, fraud_count: recapitulations.count }.tap do |result|
          result[:r13s] = recapitulations if detail.eql?(true)
          result[:r13s] = recapitulations.map { |data| data.slice('images', 'frontend_url') } if detail.eql?(:urls_only)
        end
      end
    end

    def self.data_fraud?(max_voters, recapitulation, president_votes_count, mode)
      raise 'Invalid Mode for Data Fraud' unless %i[max_voters valid_voters_with_president_votes_count].include?(mode)
      return president_votes_count.to_i > max_voters if mode == :max_voters

      president_votes_count.to_i > recapitulation.administrasi['suara_sah'].to_i
    end

    def self.recapitulations_by_mode(mode)
      return recapitulations.where.not(administrasi: nil) if mode == :valid_voters_with_president_votes_count

      recapitulations
    end

    def self.recapitulations
      Recapitulation.where.not(chart: nil)
    end

    private_class_method :data_fraud?, :recapitulations_by_mode, :recapitulations
  end
end
