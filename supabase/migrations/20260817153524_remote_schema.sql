


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vote_finalize"("p_device_id" "uuid", "p_tmdb_id" integer, "p_user_id" "uuid", "p_nonce" "text", "p_has_scene" boolean, "p_worth_it" boolean, "p_weight" real, "p_ip_hash" "text", "p_verdict" "text", "p_trust_locked" boolean, "p_is_amendment" boolean) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_rows integer;
  v_outcome text := case when p_is_amendment then 'amended' else 'accepted' end;
begin
  update public.vote_challenges
    set consumed_at = now()
    where nonce = p_nonce and device_id = p_device_id and tmdb_id = p_tmdb_id
      and consumed_at is null and expires_at > now();
  get diagnostics v_rows = row_count;

  -- Lost the race against another request holding the same nonce, or it expired between
  -- `vote_prepare`'s peek and this call. Either way nothing else in this function has
  -- written anything yet, so there is nothing to roll back.
  if v_rows = 0 then
    return jsonb_build_object('error', 'bad_nonce');
  end if;

  insert into public.votes (tmdb_id, device_id, user_id, has_scene, worth_it, weight, updated_at)
    values (p_tmdb_id, p_device_id, p_user_id, p_has_scene, p_worth_it, p_weight, now())
    on conflict (tmdb_id, device_id) do update
      set has_scene = excluded.has_scene,
          worth_it = excluded.worth_it,
          weight = excluded.weight,
          updated_at = excluded.updated_at;

  insert into public.vote_attempts (device_id, tmdb_id, ip_hash, outcome, reason)
    values (p_device_id, p_tmdb_id, p_ip_hash, v_outcome, p_verdict);

  update public.devices set
    trust = case when p_trust_locked then trust else p_weight end,
    attested = (p_verdict = 'genuine'),
    attest_verdict = p_verdict,
    attest_checked_at = now()
  where id = p_device_id;

  return jsonb_build_object(
    'stats', (
      select to_jsonb(s) from public.movie_scene_stats s where s.tmdb_id = p_tmdb_id
    )
  );
end;
$$;


ALTER FUNCTION "public"."vote_finalize"("p_device_id" "uuid", "p_tmdb_id" integer, "p_user_id" "uuid", "p_nonce" "text", "p_has_scene" boolean, "p_worth_it" boolean, "p_weight" real, "p_ip_hash" "text", "p_verdict" "text", "p_trust_locked" boolean, "p_is_amendment" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vote_issue_challenge"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_ip_hash" "text", "p_ip_limit" integer, "p_device_limit" integer, "p_ttl_seconds" integer) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_device_id uuid;
  v_since timestamptz := now() - interval '1 hour';
  v_ip_count integer := 0;
  v_device_count integer;
  v_nonce text;
  v_expires timestamptz;
begin
  -- Checked before the device is resolved, because resolving one creates a row: without
  -- this, rotating the install id mints unlimited devices and resets the per-device
  -- limit on every request.
  if p_ip_hash is not null then
    select count(*) into v_ip_count from public.vote_challenges
      where ip_hash = p_ip_hash and issued_at >= v_since;
    if v_ip_count >= p_ip_limit then
      return jsonb_build_object('error', 'ip_rate_limited');
    end if;
  end if;

  insert into public.devices (install_id, platform, last_seen)
    values (p_install_id, p_platform, now())
    on conflict (install_id) do update
      set last_seen = excluded.last_seen, platform = excluded.platform
    returning id into v_device_id;

  select count(*) into v_device_count from public.vote_challenges
    where device_id = v_device_id and issued_at >= v_since;
  if v_device_count >= p_device_limit then
    return jsonb_build_object('error', 'device_rate_limited');
  end if;

  v_nonce := replace(gen_random_uuid()::text, '-', '')
    || replace(gen_random_uuid()::text, '-', '');
  v_expires := now() + make_interval(secs => p_ttl_seconds);

  insert into public.vote_challenges (nonce, device_id, tmdb_id, ip_hash, expires_at)
    values (v_nonce, v_device_id, p_tmdb_id, p_ip_hash, v_expires);

  -- Opportunistic cleanup, same as before; the table is not worth a cron job on its own
  -- now that it also gets a daily retention sweep (see the previous migration).
  delete from public.vote_challenges
    where expires_at < now() - make_interval(secs => p_ttl_seconds);

  return jsonb_build_object('nonce', v_nonce, 'expires_at', v_expires);
end;
$$;


ALTER FUNCTION "public"."vote_issue_challenge"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_ip_hash" "text", "p_ip_limit" integer, "p_device_limit" integer, "p_ttl_seconds" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vote_log_attempt"("p_device_id" "uuid", "p_tmdb_id" integer, "p_ip_hash" "text", "p_outcome" "text", "p_reason" "text") RETURNS "void"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
  insert into public.vote_attempts (device_id, tmdb_id, ip_hash, outcome, reason)
  values (p_device_id, p_tmdb_id, p_ip_hash, p_outcome, p_reason);
$$;


ALTER FUNCTION "public"."vote_log_attempt"("p_device_id" "uuid", "p_tmdb_id" integer, "p_ip_hash" "text", "p_outcome" "text", "p_reason" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vote_prepare"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_nonce" "text", "p_ip_hash" "text") RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'pg_temp'
    AS $$
declare
  v_device public.devices%rowtype;
  v_since timestamptz := now() - interval '1 hour';
  v_device_accepted integer;
  v_ip_accepted integer := 0;
  v_ip_all integer := 0;
  v_nonce_ok boolean;
  v_existing_weight real;
begin
  insert into public.devices (install_id, platform, last_seen)
    values (p_install_id, p_platform, now())
    on conflict (install_id) do update
      set last_seen = excluded.last_seen, platform = excluded.platform
    returning id into v_device.id;

  -- Locked so a device racing itself (a retried request, a double tap that slipped past
  -- the client) resolves its rate-limit counts and weight against one consistent read.
  select * into v_device from public.devices where id = v_device.id for update;

  select count(*) into v_device_accepted from public.vote_attempts
    where device_id = v_device.id and outcome = 'accepted' and created_at >= v_since;

  if p_ip_hash is not null then
    select count(*) into v_ip_accepted from public.vote_attempts
      where ip_hash = p_ip_hash and outcome = 'accepted' and created_at >= v_since;
    select count(*) into v_ip_all from public.vote_attempts
      where ip_hash = p_ip_hash and created_at >= v_since;
  end if;

  -- A peek, not a consume: whether to spend the nonce depends on the rate-limit decision
  -- the caller makes with the counts above, so the actual UPDATE happens in
  -- `vote_finalize` instead, atomically with the write it is guarding.
  select exists(
    select 1 from public.vote_challenges
    where nonce = p_nonce and device_id = v_device.id and tmdb_id = p_tmdb_id
      and consumed_at is null and expires_at > now()
  ) into v_nonce_ok;

  select weight into v_existing_weight from public.votes
    where tmdb_id = p_tmdb_id and device_id = v_device.id;

  return jsonb_build_object(
    'device_id', v_device.id,
    'blocked_at', v_device.blocked_at,
    'first_seen', v_device.first_seen,
    'trust', v_device.trust,
    'trust_locked', v_device.trust_locked,
    'device_accepted_last_hour', v_device_accepted,
    'ip_accepted_last_hour', v_ip_accepted,
    'ip_attempts_last_hour', v_ip_all,
    'nonce_ok', v_nonce_ok,
    'movie_known', exists(select 1 from public.movies where tmdb_id = p_tmdb_id),
    'existing_weight', v_existing_weight
  );
end;
$$;


ALTER FUNCTION "public"."vote_prepare"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_nonce" "text", "p_ip_hash" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."devices" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "install_id" "text" NOT NULL,
    "platform" "text" NOT NULL,
    "attested" boolean DEFAULT false NOT NULL,
    "first_seen" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_seen" timestamp with time zone DEFAULT "now"() NOT NULL,
    "blocked_at" timestamp with time zone,
    "trust" real DEFAULT 0.0 NOT NULL,
    "attest_verdict" "text" DEFAULT 'unavailable'::"text" NOT NULL,
    "attest_checked_at" timestamp with time zone,
    "trust_locked" boolean DEFAULT false NOT NULL,
    CONSTRAINT "devices_attest_verdict_check" CHECK (("attest_verdict" = ANY (ARRAY['genuine'::"text", 'unavailable'::"text", 'failed'::"text"])))
);


ALTER TABLE "public"."devices" OWNER TO "postgres";


COMMENT ON COLUMN "public"."devices"."trust" IS 'Vote weight, 0..1. Written only by the vote function. A device is never told this value, and a rejected vote is never reported as rejected — an attacker with no feedback has nothing to iterate against.';



COMMENT ON COLUMN "public"."devices"."trust_locked" IS 'When true, the vote function leaves `trust` exactly as it is instead of recomputing it. Set by hand, never by the application.';



CREATE TABLE IF NOT EXISTS "public"."votes" (
    "tmdb_id" integer NOT NULL,
    "device_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "has_scene" boolean NOT NULL,
    "worth_it" boolean,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "weight" real DEFAULT 0 NOT NULL,
    CONSTRAINT "worth_it_only_with_scene" CHECK (("has_scene" OR ("worth_it" IS NULL)))
);


ALTER TABLE "public"."votes" OWNER TO "postgres";


COMMENT ON COLUMN "public"."votes"."weight" IS 'The device''s trust at the moment this vote was cast. Frozen deliberately: weight is a property of the vote, not of the device''s current standing.';



CREATE OR REPLACE VIEW "public"."movie_scene_stats" WITH ("security_invoker"='false', "security_barrier"='true') AS
 SELECT "v"."tmdb_id",
    ("count"(*))::integer AS "raw_votes",
    COALESCE("sum"("v"."weight"), (0)::real) AS "total_weight",
    COALESCE("sum"("v"."weight") FILTER (WHERE "v"."has_scene"), (0)::real) AS "scene_weight",
    COALESCE("sum"("v"."weight") FILTER (WHERE "v"."worth_it"), (0)::real) AS "worth_weight",
    COALESCE("sum"("v"."weight") FILTER (WHERE ("v"."has_scene" AND ("v"."worth_it" IS NOT NULL))), (0)::real) AS "worth_total"
   FROM ("public"."votes" "v"
     JOIN "public"."devices" "d" ON (("d"."id" = "v"."device_id")))
  WHERE ("d"."blocked_at" IS NULL)
  GROUP BY "v"."tmdb_id";


ALTER VIEW "public"."movie_scene_stats" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."movies" (
    "tmdb_id" integer NOT NULL,
    "title" "text" NOT NULL,
    "poster_path" "text",
    "release_date" "date",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."movies" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."vote_attempts" (
    "id" bigint NOT NULL,
    "device_id" "uuid",
    "tmdb_id" integer,
    "ip_hash" "text",
    "outcome" "text" NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."vote_attempts" OWNER TO "postgres";


COMMENT ON COLUMN "public"."vote_attempts"."outcome" IS 'accepted | amended | rate_limited | rejected. ''amended'' is a changed answer on a film the device already voted on, carrying no new weight — deliberately excluded from the accepted-count queries the rate limiter and the trust formula both read, so changing your mind does not spend the same hourly quota as a new vote.';



ALTER TABLE "public"."vote_attempts" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."vote_attempts_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."vote_challenges" (
    "nonce" "text" NOT NULL,
    "device_id" "uuid" NOT NULL,
    "tmdb_id" integer NOT NULL,
    "issued_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "expires_at" timestamp with time zone NOT NULL,
    "consumed_at" timestamp with time zone,
    "ip_hash" "text"
);


ALTER TABLE "public"."vote_challenges" OWNER TO "postgres";


ALTER TABLE ONLY "public"."devices"
    ADD CONSTRAINT "devices_install_id_key" UNIQUE ("install_id");



ALTER TABLE ONLY "public"."devices"
    ADD CONSTRAINT "devices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."movies"
    ADD CONSTRAINT "movies_pkey" PRIMARY KEY ("tmdb_id");



ALTER TABLE ONLY "public"."vote_attempts"
    ADD CONSTRAINT "vote_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."vote_challenges"
    ADD CONSTRAINT "vote_challenges_pkey" PRIMARY KEY ("nonce");



ALTER TABLE ONLY "public"."votes"
    ADD CONSTRAINT "votes_pkey" PRIMARY KEY ("tmdb_id", "device_id");



CREATE INDEX "vote_attempts_device_idx" ON "public"."vote_attempts" USING "btree" ("device_id", "created_at" DESC);



CREATE INDEX "vote_attempts_ip_idx" ON "public"."vote_attempts" USING "btree" ("ip_hash", "created_at" DESC);



CREATE INDEX "vote_challenges_device_idx" ON "public"."vote_challenges" USING "btree" ("device_id", "issued_at" DESC);



CREATE INDEX "vote_challenges_expiry_idx" ON "public"."vote_challenges" USING "btree" ("expires_at");



CREATE INDEX "vote_challenges_ip_idx" ON "public"."vote_challenges" USING "btree" ("ip_hash", "issued_at" DESC);



CREATE INDEX "votes_user_id_idx" ON "public"."votes" USING "btree" ("user_id");



ALTER TABLE ONLY "public"."vote_attempts"
    ADD CONSTRAINT "vote_attempts_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."vote_challenges"
    ADD CONSTRAINT "vote_challenges_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."votes"
    ADD CONSTRAINT "votes_device_id_fkey" FOREIGN KEY ("device_id") REFERENCES "public"."devices"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."votes"
    ADD CONSTRAINT "votes_tmdb_id_fkey" FOREIGN KEY ("tmdb_id") REFERENCES "public"."movies"("tmdb_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."votes"
    ADD CONSTRAINT "votes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE "public"."devices" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."movies" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "public read" ON "public"."movies" FOR SELECT USING (true);



CREATE POLICY "read own votes" ON "public"."votes" FOR SELECT USING (("auth"."uid"() = "user_id"));



ALTER TABLE "public"."vote_attempts" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."vote_challenges" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."votes" ENABLE ROW LEVEL SECURITY;




ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";





GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";











































































































































































REVOKE ALL ON FUNCTION "public"."vote_finalize"("p_device_id" "uuid", "p_tmdb_id" integer, "p_user_id" "uuid", "p_nonce" "text", "p_has_scene" boolean, "p_worth_it" boolean, "p_weight" real, "p_ip_hash" "text", "p_verdict" "text", "p_trust_locked" boolean, "p_is_amendment" boolean) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vote_finalize"("p_device_id" "uuid", "p_tmdb_id" integer, "p_user_id" "uuid", "p_nonce" "text", "p_has_scene" boolean, "p_worth_it" boolean, "p_weight" real, "p_ip_hash" "text", "p_verdict" "text", "p_trust_locked" boolean, "p_is_amendment" boolean) TO "service_role";



REVOKE ALL ON FUNCTION "public"."vote_issue_challenge"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_ip_hash" "text", "p_ip_limit" integer, "p_device_limit" integer, "p_ttl_seconds" integer) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vote_issue_challenge"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_ip_hash" "text", "p_ip_limit" integer, "p_device_limit" integer, "p_ttl_seconds" integer) TO "service_role";



REVOKE ALL ON FUNCTION "public"."vote_log_attempt"("p_device_id" "uuid", "p_tmdb_id" integer, "p_ip_hash" "text", "p_outcome" "text", "p_reason" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vote_log_attempt"("p_device_id" "uuid", "p_tmdb_id" integer, "p_ip_hash" "text", "p_outcome" "text", "p_reason" "text") TO "service_role";



REVOKE ALL ON FUNCTION "public"."vote_prepare"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_nonce" "text", "p_ip_hash" "text") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."vote_prepare"("p_install_id" "text", "p_platform" "text", "p_tmdb_id" integer, "p_nonce" "text", "p_ip_hash" "text") TO "service_role";
























GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."devices" TO "anon";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."devices" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."devices" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."votes" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."votes" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."votes" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."movie_scene_stats" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."movie_scene_stats" TO "authenticated";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."movie_scene_stats" TO "service_role";



GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."movies" TO "anon";
GRANT SELECT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."movies" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN,UPDATE ON TABLE "public"."movies" TO "service_role";



GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."vote_attempts" TO "anon";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."vote_attempts" TO "authenticated";
GRANT SELECT,INSERT,REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."vote_attempts" TO "service_role";



GRANT UPDATE ON SEQUENCE "public"."vote_attempts_id_seq" TO "anon";
GRANT UPDATE ON SEQUENCE "public"."vote_attempts_id_seq" TO "authenticated";
GRANT UPDATE ON SEQUENCE "public"."vote_attempts_id_seq" TO "service_role";



GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."vote_challenges" TO "anon";
GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLE "public"."vote_challenges" TO "authenticated";
GRANT ALL ON TABLE "public"."vote_challenges" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT UPDATE ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT UPDATE ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT UPDATE ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT REFERENCES,TRIGGER,TRUNCATE,MAINTAIN ON TABLES TO "service_role";
































--
-- Dumped schema changes for auth and storage
--

