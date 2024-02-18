# frozen_string_literal: true

module Jobs
  class RecapitulationRunner < PlaceRunner
    sidekiq_options queue: 'recapitulation_runner'
  end
end
