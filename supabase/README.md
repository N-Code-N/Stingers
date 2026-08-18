# Backend (Supabase)

Postgres holds the votes, two Edge Functions hold everything the client is not allowed to
be trusted with. Rationale lives in [`../PROJECT_PLAN.md`](../PROJECT_PLAN.md) §3 and §6.

## Layout

```
migrations/20260815120000_init.sql   schema, the weighted stats view, RLS
functions/_shared/http.ts            error envelope, CORS, IP hashing
functions/_shared/tmdb.ts            TMDb access + the movies snapshot upsert
functions/tmdb/index.ts              read-only proxy, path + query allowlist
functions/vote/index.ts              the only write path in the system
```

## Deploy

Requires the [Supabase CLI](https://supabase.com/docs/guides/cli) (not installed in this
checkout) and a project on supabase.com.

```bash
supabase link --project-ref <ref>
supabase db push

supabase secrets set TMDB_ACCESS_TOKEN=<TMDb v4 read access token>
supabase secrets set IP_HASH_SECRET=<any long random string>

supabase functions deploy tmdb
supabase functions deploy vote
```

### Device weighting

`devices.trust` is the weight a device's next vote carries, recomputed by the `vote`
function every time it votes. Two columns override that:

| column         | effect                                                        |
| -------------- | ------------------------------------------------------------- |
| `blocked_at`   | the device weighs nothing and is excluded from the aggregate  |
| `trust_locked` | `trust` is left exactly as set instead of being recomputed    |

Weight is snapshotted onto `votes.weight` when a vote is cast, so changing a device's
standing affects its future votes, not its past ones. Both columns are set by hand, from
the SQL editor; there is deliberately no application path to either.

## Contract

`tmdb` passes the TMDb envelope through unchanged, so the Dart models mirror TMDb
directly:

```
GET /functions/v1/tmdb/movie/now_playing?page=1&region=US
GET /functions/v1/tmdb/movie/{id}
GET /functions/v1/tmdb/search/movie?query=dune&page=1
GET /functions/v1/tmdb/movie/{id}/watch/providers
```

Anything outside that path allowlist is a 404, and any query parameter outside
`page | query | region | language | include_adult` is dropped.

`vote` takes a POST and answers with the film's row from `movie_scene_stats`:

```jsonc
// request
{ "tmdb_id": 1234, "install_id": "…", "platform": "ios",
  "has_scene": true, "worth_it": false }

// response
{ "tmdb_id": 1234, "raw_votes": 14, "total_weight": 12.0,
  "scene_weight": 11.0, "worth_weight": 7.0, "worth_total": 11.0 }
```

Errors from both functions share one envelope, `{"error_type": "...", "error": "..."}`,
and the client dispatches on `error_type` only.

## Verifying the write path is actually closed

In the SQL editor, as `anon`:

```sql
set role anon;
insert into public.votes (tmdb_id, device_id, user_id, has_scene)
values (1, gen_random_uuid(), gen_random_uuid(), true);
-- expected: new row violates row-level security policy
```

There is no INSERT policy on any table. That is the design, not an oversight.
