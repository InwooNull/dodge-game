// Supabase 연결 정보. 둘 다 비워 두면 "오프라인 모드"(이 브라우저에만 기록 저장)로 동작합니다.
// Supabase 대시보드 → Project Settings → API 에서 복사하세요.
// anon / publishable 키는 공개되어도 되는 키입니다 (service_role / secret 키는 절대 넣지 마세요).
window.DODGE_CONFIG = {
  SUPABASE_URL: "",   // 예: "https://abcdefghijkl.supabase.co"
  SUPABASE_KEY: "",   // 예: "sb_publishable_..." 또는 "eyJhbGciOi..." (anon)
};
