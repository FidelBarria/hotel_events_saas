require "fileutils"
require "securerandom"
require "sqlite3"

class DatabaseBackup
  RETENTION = 30
  BACKUP_PREFIX = "hotel-events-"
  LOCK = Mutex.new

  def self.create!
    new.create!
  end

  def create!
    return unless sqlite_database?

    LOCK.synchronize do
      FileUtils.mkdir_p(backup_directory)
      filename = "#{BACKUP_PREFIX}#{Time.current.strftime('%Y%m%d-%H%M%S-%6N')}-#{SecureRandom.hex(3)}.sqlite3"
      destination_path = backup_directory.join(filename)
      temporary_path = destination_path.sub_ext(".tmp")
      write_snapshot(temporary_path)
      File.rename(temporary_path, destination_path)
      prune_old_backups
      destination_path
    ensure
      File.delete(temporary_path) if temporary_path&.exist?
    end
  end

  private

  def sqlite_database?
    ActiveRecord::Base.connection.adapter_name.downcase.include?("sqlite")
  end

  def backup_directory
    Rails.root.join("storage", "backups")
  end

  def write_snapshot(path)
    source = ActiveRecord::Base.connection.raw_connection
    destination = SQLite3::Database.new(path.to_s)
    backup = SQLite3::Backup.new(destination, "main", source, "main")
    status = backup.step(-1)

    unless status == SQLite3::Constants::ErrorCode::DONE
      raise "SQLite backup returned status #{status}"
    end
  ensure
    backup&.finish
    destination&.close
  end

  def prune_old_backups
    backups = Dir.glob(backup_directory.join("#{BACKUP_PREFIX}*.sqlite3").to_s).sort.reverse
    backups.drop(RETENTION).each { |file| File.delete(file) }
  end
end
