# frozen_string_literal: true

module Jobs
  class PlaceRunner
    include Sidekiq::Job

    sidekiq_options retry: 1, queue: 'place_runner'

    def perform(model_class, method)
      model_class.constantize.send(method)
    end
  end
end
