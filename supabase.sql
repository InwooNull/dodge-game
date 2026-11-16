-- 탄막 피하기 랭킹 테이블. Supabase 대시보드 → SQL Editor 에 통째로 붙여넣고 Run.
-- 닉네임은 처음 쓴 기기(브라우저)가 가져갑니다. 다른 기기에서 같은 닉네임은 쓸 수 없습니다.

create table if not exists public.players (
  nickname   text primary key,
  token      text not null,
  created_at timestamptz not null default now()
);
create unique index if not exists players_nickname_lower on public.players (lower(nickname));

create table if not exists public.scores (
  nickname   text primary key references public.players(nickname) on delete cascade,
  best_ms    integer not null check (best_ms >= 0),
  updated_at timestamptz not null default now()
);

alter table public.players enable row level security;  -- 정책 없음 = 브라우저에서 직접 접근 불가 (토큰 보호)
alter table public.scores  enable row level security;

drop policy if exists "scores are public" on public.scores;
create policy "scores are public" on public.scores for select to anon, authenticated using (true);

-- 닉네임 등록/확인. 같은 기기 토큰이면 통과, 다른 기기가 이미 쓰고 있으면 nickname_taken.
create or replace function public.claim_nickname(p_nickname text, p_token text)
returns text
language plpgsql security definer set search_path = public
as $$
declare v_nick text; v_token text;
begin
  p_nickname := btrim(coalesce(p_nickname, ''));
  if char_length(p_nickname) < 1 or char_length(p_nickname) > 12 or p_nickname ~ '[[:cntrl:]]' then
    raise exception 'bad_nickname';
  end if;
  if p_token is null or char_length(p_token) < 16 then
    raise exception 'bad_token';
  end if;

  select nickname, token into v_nick, v_token from players where lower(nickname) = lower(p_nickname);
  if v_nick is null then
    insert into players (nickname, token) values (p_nickname, p_token);
    return p_nickname;
  elsif v_token = p_token then
    return v_nick;
  else
    raise exception 'nickname_taken';
  end if;
end $$;

-- 기록 제출. 최고 기록만 남김. 반환값 = 저장된 최고 기록(ms).
create or replace function public.submit_score(p_nickname text, p_token text, p_ms integer)
returns integer
language plpgsql security definer set search_path = public
as $$
declare v_nick text; v_best integer;
begin
  if p_ms is null or p_ms < 0 or p_ms > 3600000 then
    raise exception 'bad_score';
  end if;
  select nickname into v_nick from players
   where lower(nickname) = lower(btrim(p_nickname)) and token = p_token;
  if v_nick is null then
    raise exception 'nickname_taken';
  end if;

  insert into scores (nickname, best_ms) values (v_nick, p_ms)
  on conflict (nickname) do update
     set best_ms    = greatest(scores.best_ms, excluded.best_ms),
         updated_at = case when excluded.best_ms > scores.best_ms then now() else scores.updated_at end
  returning best_ms into v_best;
  return v_best;
end $$;

revoke all on function public.claim_nickname(text, text) from public;
revoke all on function public.submit_score(text, text, integer) from public;
grant execute on function public.claim_nickname(text, text) to anon, authenticated;
grant execute on function public.submit_score(text, text, integer) to anon, authenticated;
grant select on public.scores to anon, authenticated;
