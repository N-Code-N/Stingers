// TMDb access, shared by the `tmdb` proxy and the `vote` function.
//
// The TMDb read token lives here and only here (`supabase secrets set TMDB_ACCESS_TOKEN=...`).
// It is never shipped to the client: Dart string constants survive AOT compilation and fall
// out of `libapp.so` under `strings`, so a key in the binary is a published key.

import type { SupabaseClient } from 'npm:@supabase/supabase-js@2';

const TMDB_BASE = 'https://api.themoviedb.org/3';

export function tmdbToken(): string {
  const token = Deno.env.get('TMDB_ACCESS_TOKEN');
  if (!token) throw new Error('TMDB_ACCESS_TOKEN is not configured');
  return token;
}

export async function tmdbGet(path: string, query: URLSearchParams): Promise<Response> {
  const url = new URL(TMDB_BASE + path);
  url.search = query.toString();
  return await fetch(url, {
    headers: {
      Authorization: `Bearer ${tmdbToken()}`,
      Accept: 'application/json',
    },
  });
}

export interface MovieSnapshot {
  tmdb_id: number;
  title: string;
  poster_path: string | null;
  release_date: string | null;
}

/// TMDb sends `release_date: ""` for unscheduled films; Postgres rejects that for a
/// `date` column, so an empty string has to become NULL rather than travel as-is.
export function snapshotFrom(movie: Record<string, unknown>): MovieSnapshot | null {
  const id = movie.id;
  const title = movie.title ?? movie.original_title;
  if (typeof id !== 'number' || typeof title !== 'string') return null;

  const releaseDate = typeof movie.release_date === 'string' && movie.release_date !== ''
    ? movie.release_date
    : null;

  return {
    tmdb_id: id,
    title,
    poster_path: typeof movie.poster_path === 'string' ? movie.poster_path : null,
    release_date: releaseDate,
  };
}

/// Keeps `public.movies` in step with what the client has actually seen, so the FK
/// from `votes` is satisfied by the time anyone votes. Failure here must not fail the
/// caller's read — a stale snapshot is worth less than a broken feed.
export async function upsertSnapshots(
  admin: SupabaseClient,
  movies: MovieSnapshot[],
): Promise<void> {
  if (movies.length === 0) return;
  const { error } = await admin
    .from('movies')
    .upsert(movies.map((m) => ({ ...m, updated_at: new Date().toISOString() })), {
      onConflict: 'tmdb_id',
    });
  if (error) console.error('movies upsert failed', error);
}
