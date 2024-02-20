# frozen_string_literal: true

module Jobs
  class BackupRunner < PlaceRunner
    sidekiq_options queue: 'backup_runner'
  end
end
