# frozen_string_literal: true

module Fraud
  class PollingStationChecker
    def self.check(
      max_voters = 300,
      comparator:,
      sample:,
      query: -> { all },
      detail: true,
      skip_ids: [],
      save: false,
      use_backup: false
    )
      # Fetch all recapitulations
      r13s = recapitulations(query, comparator, use_backup).limit(sample)

      # Fetch all presidents
      presidents = President.where.not(:id.in => skip_ids.map(&:to_s))
      presidents_by_id = presidents.index_by(&:id)

      # Initialize a hash to store the recapitulations grouped by president's name
      grouped_recaps = Hash.new { |hash, key| hash[key] = [] }

      # Iterate over the recapitulations
      r13s.each do |recapitulation|
        # Iterate over the keys in the 'chart' field
        recapitulation.chart.each do |key, value|
          president = presidents_by_id[key]

          # Exit chart iteration if the president is nil, or the value is less than 300
          next unless president && data_fraud?(max_voters, recapitulation, value, comparator)

          # Add the recapitulation to the group for this president
          # if the value is greater than 300 and a president was found
          grouped_recaps[president.nama] << recapitulation.attributes
        end
      end

      # Convert the grouped recapitulations to an array of hashes
      results = grouped_recaps.map do |president, recapitulations|
        { president:, comparator:, fraud_count: recapitulations.count }.tap do |result|
          result[:r13s] = recapitulations if detail.eql?(true)
          result[:r13s] = selected_recapitulations(recapitulations, detail[:only]) if detail.is_a?(Hash)
        end.deep_stringify_keys
      end

      save_to_db_or_file(results, save, comparator, sample) unless save.eql?(false)

      results
    end

    # Private methods

    def self.save_to_db_or_file(results, save, *args)
      return save_to_db(results) if save[:to].eql?(:db)

      save_to_file(results, save, *args)
    end

    def self.save_to_db(results)
      results.each { |data| Fraud::PollingStation.create! data }
    end

    def self.save_to_file(results, save, comparator, sample)
      filename = File.join(save[:path] || '.', saved_name(comparator, sample))
      File.open(filename, 'w') { |file| file.write(results.to_json) }
    end

    def self.saved_name(comparator, sample)
      ['fraud_checker', comparator, sample, Time.now.to_i].compact.join('_') + '.json'
    end

    def self.selected_recapitulations(recapitulations, options)
      recapitulations.map { |data| data.slice(*options.map(&:to_s)) }
    end

    def self.data_fraud?(max_voters, recapitulation, president_votes_count, comparator)
      raise 'Invalid fraud comparator' unless %i[max_voters valid_voters provisional_voters].include?(comparator)

      president_votes_count.to_i > case comparator
      when :valid_voters
        recapitulation.administrasi['suara_sah'].to_i
      when :provisional_voters
        recapitulation.administrasi['pengguna_total_j'].to_i
      else
        max_voters
      end
    end

    def self.recapitulations(query, comparator, use_backup)
      recapitulations = recapitulation_model(use_backup).instance_exec(&query)

      return recapitulations.not(chart: nil) if comparator == :max_voters

      recapitulations.not(chart: nil, administrasi: nil)
    end

    def self.recapitulation_model(use_backup)
      raise 'Invalid backup option.' unless use_backup.eql?(false) || use_backup.is_a?(Hash)

      use_backup.eql?(false) ? Recapitulation : Backup::Recapitulation.where(backup_version: use_backup[:version])
    end

    private_class_method :data_fraud?,
      :recapitulations,
      :recapitulation_model,
      :selected_recapitulations,
      :save_to_db_or_file,
      :save_to_db,
      :save_to_file,
      :saved_name
  end
end
