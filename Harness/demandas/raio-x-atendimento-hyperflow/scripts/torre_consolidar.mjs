// Consolida as páginas salvas pelo MCP do Supabase (SELECT em org_*.ai_messages) em dados/brutos/torre_ai_messages_<rec>.json.
// Uso: node scripts/torre_consolidar.mjs <A|B> <pagina1.txt> <pagina2.txt> ...   (só contagens na saída)
import fs from "node:fs";
const [, , rec, ...files] = process.argv;
const rows = [];
for (const f of files) {
  const res = JSON.parse(fs.readFileSync(f, "utf8")).result, a = res.indexOf("["), b = res.lastIndexOf("]");
  for (const r of JSON.parse(res.slice(a, b + 1))) rows.push({ protocol: r.p, role: r.r === "u" ? "user" : "assistant", occurred_at: r.o, received_at: r.v, agent_id: r.g, is_a2a: r.x, content: r.c });
}
rows.sort((x, y) => x.occurred_at < y.occurred_at ? -1 : x.occurred_at > y.occurred_at ? 1 : 0);
fs.writeFileSync(`dados/brutos/torre_ai_messages_${rec}.json`, JSON.stringify(rows));
const c = (f) => rows.filter(f).length, mes = {};
for (const r of rows) { const m = r.occurred_at.slice(0, 7), o = mes[m] ??= { n: 0, com_texto: 0 }; o.n++; if (r.content) o.com_texto++; }
const ag = {}; for (const r of rows) { const k = (r.agent_id || "null").slice(0, 8); ag[k] = (ag[k] || 0) + 1; }
console.log(JSON.stringify({ rec, linhas: rows.length, user: c(r => r.role === "user"), assistant: c(r => r.role === "assistant"), com_texto: c(r => !!r.content), sem_texto: c(r => !r.content), a2a: c(r => r.is_a2a), protocolos: new Set(rows.map(r => r.protocol)).size, por_mes: mes, agentes_prefixo: ag,
  formato: { occurred_at: rows[0].occurred_at.replace(/\d/g, "9"), protocol_tipo: typeof rows[0].protocol, protocol_len: [...new Set(rows.map(r => String(r.protocol).length))] } }));
