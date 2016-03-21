# -*- coding: utf-8 -*-
#
# Did in something like 5 minutes
# It's not working at all, it just insert new 'jobs'
# I don't know exactly how it will look like
#
# My idea is to :
#   * create my own job queue
#   * with a syntax close to brandonhilkert/sucker_punch
#   * using DB and running in it's own process like tobi/delayed_job
#   * taking advantage of postgres mechanisms
#
class Jobgres

  TABLE_NAME = 'jobgres_queue'.freeze

  def self.table_name
    return 'delayed_jobs'.freeze # For tests with already existing table
    return TABLE_NAME
  end

  def self.default_priority
    return @default_priority||0
  end

  def self.queue_name
    return @queue_name.to_s
  end

  def self.connection
    return ActiveRecord::Base.connection
  end

  def self.enqueue *params, job_id: nil, priority: nil
    job_id ||= "#{Time.now.to_f}-#{Process.pid}"
    priority ||= default_priority

    # Double single quotes to escape it (needed by postgres)
    json_params = params.to_json.gsub!("'", "''")

    sql_insert = %{
      INSERT INTO "#{table_name}"
               ("id",                        "attempts", "created_at",      "failed_at", "handler",           "last_error", "locked_at", "locked_by", "priority",        "queue",                         "run_at",          "updated_at")
        VALUES ('#{job_id.gsub("'", "''")}', 0,          current_timestamp, null,        E'#{json_params}',    null,         null,        null,        #{priority.to_i}, '#{queue_name.gsub("'", "''")}', current_timestamp, null)
    }

    puts sql_insert
    connection.execute(sql_insert)

    return job_id
  end

end
