# frozen_string_literal: true

module Jobs
  class BackupCrawler
    include Sidekiq::Job

    sidekiq_options retry: 1, queue: 'backup_crawler'

    def perform(model_gid, version, exclude_attrs, destroy_old)
      model_class(model_gid).create_backup! version, exclude_attrs, destroy_old:
    end

    private

    def model_class(global_id)
      GlobalID::Locator.locate global_id
    end
  end
end
