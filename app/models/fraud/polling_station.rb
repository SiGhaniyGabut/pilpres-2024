# frozen_string_literal: true

module Fraud
  class PollingStation
    include Mongoid::Document
    include Mongoid::Timestamps
    include Mongoid::Attributes::Dynamic
  end
end
