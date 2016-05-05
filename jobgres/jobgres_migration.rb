class AddJobgresTable < ActiveRecord::Migration
  def up
    execute %{
      -- Requires postgres 9.5+

      CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

      CREATE TABLE jobgres_jobs (
        id          uuid                    NOT NULL DEFAULT uuid_generate_v4(),
        priority    integer                 NOT NULL DEFAULT 0,
        signature   character varying(255)  NOT NULL,
        attemps     integer                 NOT NULL DEFAULT 0,
        job_class   character varying(255)  NOT NULL,
        params      jsonb,
        queued_at   timestamp               NOT NULL DEFAULT now(),
        --locked_at   timestamp, -- No lock needed
        started_at  timestamp,
        finished_at timestamp,
        status      integer,

        CONSTRAINT jobgres_jobs_pkey PRIMARY KEY (id)
      );

      -- Make sure there is no duplicated pending jobs
      CREATE UNIQUE INDEX jobgres_jobs_unique_idx ON jobgres_jobs
        (signature)
        WHERE finished_at IS NULL;
    }
  end

  def down
    execute %{ DROP TABLE jobgres_jobs; }
  end
end
