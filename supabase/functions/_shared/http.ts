// Shared HTTP helpers for the Stingers Edge Functions.

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

/// The single error envelope both functions speak. The client dispatches on
/// `error_type`, never on `error` — see the Dart `ApiException` set.
export function fail(status: number, errorType: string, message: string): Response {
  return json({ error_type: errorType, error: message }, status);
}

export function preflight(req: Request): Response | null {
  return req.method === 'OPTIONS' ? new Response('ok', { headers: corsHeaders }) : null;
}

/// The salt for [hashIp] (`supabase secrets set IP_HASH_SECRET=...`).
///
/// Missing is a hard error rather than a default, because a default would be a *known*
/// salt: IPv4 is only 2^32 addresses, so anyone holding the salt can brute-force every
/// stored hash in seconds, and `vote_attempts.ip_hash` stops being "we do not keep IPs"
/// and becomes a plaintext IP log. Failing the request is the cheap outcome.
export function ipHashSecret(): string {
  const secret = Deno.env.get('IP_HASH_SECRET');
  if (!secret) throw new Error('IP_HASH_SECRET is not configured');
  return secret;
}

/// HMAC-SHA256 of the caller's IP. The raw address is never stored: rate limiting
/// needs to recognise a repeat caller, not to know who they are.
///
/// The **last** entry of `x-forwarded-for`, not the first. The header is a list that
/// each proxy appends to, so the leftmost value is whatever the client claimed and the
/// rightmost is what the proxy directly in front of us observed. Taking the first would
/// let a caller reset their own rate limit by sending a header — and taking the last is
/// identical in the normal case, where the platform sets a single value.
export async function hashIp(req: Request, secret: string): Promise<string | null> {
  const forwarded = req.headers.get('x-forwarded-for');
  const hops = forwarded?.split(',').map((hop) => hop.trim()).filter(Boolean) ?? [];
  const ip = hops.at(-1);
  if (!ip) return null;

  const key = await crypto.subtle.importKey(
    'raw',
    new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(ip));
  return [...new Uint8Array(signature)].map((b) => b.toString(16).padStart(2, '0')).join(
    '',
  );
}
