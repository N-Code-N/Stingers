-- Demo seed: synthetic votes with a realistic spread, so a first look at the app is not
-- thirty rows of "no verdict".
--
-- PREREQUISITES — run the app once against this project first. That does two things
-- this script deliberately does not do itself:
--   * populates `public.movies` (the `tmdb` function writes the snapshots, so no film id
--     or title is invented here — every seeded film is a real one the app has seen);
--   * creates an anonymous user in `auth.users`, which `votes.user_id` references.
--
-- Then run this in the SQL editor. It is idempotent: re-running replaces the synthetic
-- devices and their votes, and never touches a real one.
--
-- Every synthetic device is tagged `platform = 'seed'`, which is how they are found
-- again and how they stay distinguishable from real traffic in the audit trail.

do $$
declare
  demo_user   uuid;
  film        record;
  device      uuid;
  voters      int;
  scene_bias  numeric;   -- share of this film's voters who saw a scene
  worth_bias  numeric;   -- share of those who thought it was worth waiting for
  device_trust real;
  said_scene  boolean;
  said_worth  boolean;
begin
  select id into demo_user from auth.users order by created_at limit 1;
  if demo_user is null then
    raise exception
      'No user in auth.users. Launch the app against this project once, then re-run.';
  end if;

  if not exists (select 1 from public.movies) then
    raise exception
      'public.movies is empty. Open the feed in the app once, then re-run.';
  end if;

  -- Idempotence: drop the previous synthetic run. Votes and challenges cascade.
  delete from public.devices where platform = 'seed';

  for film in
    select tmdb_id from public.movies order by updated_at desc limit 30
  loop
    voters := 10 + floor(random() * 11)::int;      -- 10..20 voters per film

    -- Most films that people bother checking do have a scene, and the ones that do not
    -- are usually unambiguous. A uniform 50/50 would look synthetic at a glance.
    scene_bias := case
      when random() < 0.65 then 0.75 + random() * 0.22   -- clearly has one
      else 0.03 + random() * 0.17                        -- clearly does not
    end;
    worth_bias := 0.25 + random() * 0.6;

    for i in 1..voters loop
      -- The trust spread is the interesting part of this seed: it is what makes the gap
      -- between raw_votes and total_weight visible, which is the whole design in §6.
      device_trust := case
        when random() < 0.15 then 0.0                    -- a caught farm: stored, weightless
        when random() < 0.30 then 0.2 + random() * 0.3   -- unattested / new device
        else 0.85 + random() * 0.15                      -- attested, established
      end;

      insert into public.devices (install_id, platform, trust, attested, attest_verdict, first_seen)
      values (
        'seed-' || film.tmdb_id || '-' || i,
        'seed',
        device_trust,
        device_trust > 0.8,
        case when device_trust > 0.8 then 'genuine'
             when device_trust > 0 then 'unavailable'
             else 'failed' end,
        now() - (random() * 90 || ' days')::interval
      )
      returning id into device;

      said_scene := random() < scene_bias;
      said_worth := case when said_scene then random() < worth_bias else null end;

      insert into public.votes (tmdb_id, device_id, user_id, has_scene, worth_it, created_at, updated_at)
      values (
        film.tmdb_id,
        device,
        demo_user,
        said_scene,
        said_worth,
        now() - (random() * 30 || ' days')::interval,
        now()
      );
    end loop;
  end loop;
end $$;

-- Sanity check: where raw_votes and total_weight diverge, the weighting is doing its job.
select
  m.title,
  s.raw_votes,
  round(s.total_weight::numeric, 1) as weight,
  round((s.scene_weight / nullif(s.total_weight, 0) * 100)::numeric) as scene_pct
from public.movie_scene_stats s
join public.movies m using (tmdb_id)
order by s.raw_votes desc;
