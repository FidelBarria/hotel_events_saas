class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  after_commit :create_database_backup, on: %i[create update destroy]

  private

  def create_database_backup
    return if Rails.env.test?

    DatabaseBackup.create!
  rescue StandardError => error
    Rails.logger.error("Backup do banco falhou apos salvar #{self.class}##{id}: #{error.class}: #{error.message}")
  end
end
