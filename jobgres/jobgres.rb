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
module Jobgres

  class Error < RuntimeError
  end

  # Raised when trying to queue an already queued job
  class JobExistsError < Error
  end

  module Job

    TABLE_NAME = 'jobgres_jobs'.freeze
    DEFAULT_PRIORITY = 0 # < is low priority and > 0 is high priority

    def self.included(base)
      base.extend(ClassMethods)

      base.class_attribute :job_table_name
      base.job_table_name = TABLE_NAME

      base.class_attribute :job_priority
      base.job_priority = DEFAULT_PRIORITY
    end

    module ClassMethods
      def job_table(table_name)
        self.job_table_name = table_name.to_s
      end

      def job_priority(priority)
        self.job_priority = priority.to_i
      end
    end

    def enqueue_job *params, priority: nil, signature: nil
      # Double single quotes to escape it (needed by postgres)
      table_name  = job_table_name.to_s
      priority    = (priority  || job_priority ).to_i
      signature   = (signature || jobgres_default_signature).gsub("'", "''")
      job_class   = self.class.name
      json_params = params.to_json
      json_params.gsub!("'", "''")

      sql_insert = %{
        INSERT INTO "#{table_name}"
                 ( "priority",   "signature",    "job_class",         "params",        "queued_at")
          VALUES (#{priority}, '#{signature}', '#{job_class}', '#{json_params}', current_timestamp)
          RETURNING "id";
      }

      begin
        job_id = jobgres_connection
          .execute(sql_insert)
          .values.first.try(:first)
      rescue ActiveRecord::RecordNotUnique
        msg = "Job with signature '#{signature}' is already queued"
        raise JobExistsError, msg
      end

      return job_id
    end

    # #try_enqueue_job is for debug purpose only
    def try_enqueue_job *params, priority: nil, signature: nil
      return enqueue_job(*params, priority: priority, signature: signature)
    rescue => e
      Rails.logger.warn("[JOBGRES] Cannot enqueue job : #{e.message}")
      return nil
    end


    def jobgres_default_signature
      "#{Time.now.to_f}-#{Process.pid}"
    end

    def jobgres_connection
      return ActiveRecord::Base.connection
    end

  end

end
