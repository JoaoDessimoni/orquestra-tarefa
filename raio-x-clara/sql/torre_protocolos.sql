-- Rodar com mcp__supabase-prod__execute_sql (só leitura). Um protocolo por linha.
-- A Torre só registra a conversa quando o cliente responde: first_user vazio quase nunca acontece.
-- O conteúdo das mensagens é apagado após ~30 dias; as contagens continuam valendo.
with m as (
  select 'blips' org, protocol, role, occurred_at from org_blips.ai_messages where agent_id = '418fb5c2-0804-4dfe-b9a7-9425b0d23939'
  union all
  select 'finza', protocol, role, occurred_at from org_finza.ai_messages where agent_id = 'b9939d16-9acd-4937-b717-55cd90d297e9'
)
select org, protocol,
       min(occurred_at) filter (where role = 'user') first_user,
       count(*) filter (where role = 'user') n_user,
       count(*) filter (where role = 'assistant') n_ai,
       min(occurred_at) first_msg
from m
group by 1, 2
order by 3;
