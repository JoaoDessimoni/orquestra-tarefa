// Etapa 3 — normalização + métricas de tempo (specs 02 §4–6 e 03).
// Lê dados/brutos/*.json (saída do bq) e grava:
//   dados/protocolos/<chat_id>.json   conversa unificada + métricas (entrada do avaliador; SEM telefone/CNPJ)
//   dados/metricas/protocolos.jsonl   índice por chat (sem texto)
//   dados/metricas/clientes.jsonl     clientes (telefone, CNPJ — PII)
//   dados/metricas/atendentes.json    atendentes humanos
//   dados/metricas/resumo.json        contagens para reconciliação
// Uso: node scripts/normalizar.mjs [--sem-arquivos]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const BR = path.join(BASE, "dados", "brutos");
const OUT_P = path.join(BASE, "dados", "protocolos");
const OUT_M = path.join(BASE, "dados", "metricas");
const SEM_ARQ = process.argv.includes("--sem-arquivos");
fs.mkdirSync(OUT_P, { recursive: true }); fs.mkdirSync(OUT_M, { recursive: true });

const ler = n => { const f = path.join(BR, n + ".json"); if (!fs.existsSync(f)) return []; const s = fs.readFileSync(f, "utf8").trim(); return s ? JSON.parse(s) : []; };
const bool = v => v === true || v === "true";
const OFF = 3 * 3600e3;                                   // Brasília = UTC−3, sem horário de verão
const wall = iso => iso ? Date.parse(iso) - OFF : null;   // relógio de parede de Brasília em ms "UTC"
const isoBR = ms => ms == null ? null : new Date(ms).toISOString().replace("Z", "-03:00");

/* ===== funções copiadas do artefato (raio-x-atendimento_cto_19-11-2026.html) — manter IDÊNTICAS às do HTML (bloco bizMin…metricas) ===== */
const median=a=>{if(!a.length)return null;const s=[...a].sort((x,y)=>x-y),m=s.length>>1;return s.length%2?s[m]:(s[m-1]+s[m])/2};
const mean=a=>a.length?a.reduce((x,y)=>x+y,0)/a.length:null;
const MIN=60000, DAY=86400000;
const CFG={exp:{dias:[1,2,3,4,5],ini:8,fim:18}};
function bizMin(a,b){if(b<=a)return 0;let t=a,tot=0;while(t<b){const d=new Date(t),d0=Date.UTC(d.getUTCFullYear(),d.getUTCMonth(),d.getUTCDate());
  if(CFG.exp.dias.includes(d.getUTCDay())){const s=Math.max(t,d0+CFG.exp.ini*3600e3),e=Math.min(b,d0+CFG.exp.fim*3600e3);if(e>s)tot+=e-s}t=d0+DAY}return tot/MIN}
const faixaDe=m=>m==null?"sem":m<=10?"f10":m<=20?"f20":m<=30?"f30":m<=60?"f60":"f60p";
const IA_MIN_MS=3000; // resposta da IA em menos de 3 s não é plausível: o turno ganha rap:true e fica fora da medição da IA (respIA, mediana da IA, mapa de calor)
/* Encerramento do cliente: o último bloco do cliente, sem réplica, só com cortesia curta (ok, obrigado, tchau, emoji…)
   depois de pelo menos um turno respondido. Não é "sem resposta" e fica fora da pior espera e da mediana. */
const CORT_RE=/\b(?:muito obrigad[oa]|obrigad[oa]|obrigadao|obgd?[oa]?|brigad[oa]|agradeco|grat[oa]|valeu|vlw|flw|falou|blz|beleza|ta (?:bom|bem|certo|otimo|ok|joia)|tudo (?:bem|certo|ok|bom|joia)|ok|okay|oks|certo|certinho|perfeito|combinado|entendi|entendido|show|top|joia|bom dia|boa tarde|boa noite|amem|de nada|por nada|tchau|ate (?:mais|logo|breve|amanha))\b/g;
const CORT_OK=new Set("muito mesmo viu entao pela pelo por atencao ajuda retorno e a o moca moco amigo amiga querida querido senhor senhora sr sra dr dra pra para voce vc tambem tb tbm deus abencoe te lhe fica fique com um uma otimo otima bom boa dia tarde noite semana fim final de trabalho descanso abraco abs k rs ai ja ta tudo bem igualmente tmj legal".split(" "));
function ehCortesia(texto){
  const t=String(texto??"").trim();
  if(!t||t.length>40||/[?\[\]\d]/.test(t))return false;
  const semEmoji=t.replace(/[\p{Extended_Pictographic}\p{Emoji_Modifier}‍️]/gu,""),temEmoji=semEmoji.length<t.length;
  const n=semEmoji.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g,"").replace(/[^a-z]+/g," ").replace(/([a-z])\1+/g,"$1").trim();
  if(!n)return temEmoji;
  let nucleo=0;const resto=n.replace(CORT_RE,()=>{nucleo++;return " "}).trim();
  if(!nucleo)return false;
  return !resto||resto.split(/\s+/).every(w=>CORT_OK.has(w));
}
function fechaMet(turnos,assumir,transf){
  const val=turnos.filter(x=>!x.enc),nt=val.length;
  const pior=k=>val.some(x=>x[k]==null)?null:Math.max(0,...val.map(x=>x[k]));
  const med=k=>median(val.filter(x=>x[k]!=null).map(x=>x[k]));
  const resp=(w,k)=>mean(val.filter(x=>x.por===w&&!x.rap&&x[k]!=null).map(x=>x[k]));
  return {turnos,pior:{cor:pior("cor"),com:pior("com")},mediana:{cor:med("cor"),com:med("com")},faixaCor:nt?faixaDe(pior("cor")):null,faixaCom:nt?faixaDe(pior("com")):null,
    primeira:{cor:turnos[0]?.cor??null,com:turnos[0]?.com??null},semResposta:val.some(x=>x.cor==null),encerramento:turnos.some(x=>x.enc),
    respIA:{cor:resp("ia","cor"),com:resp("ia","com")},respHum:{cor:resp("humano","cor"),com:resp("humano","com")},
    assumir:assumir==null?null:{cor:assumir,com:bizMin(transf,transf+assumir*MIN)}};
}
function metricas(p){
  const turnos=[];let bloco=null,btx=[],assumir=null;
  for(const m of p.msgs){
    if(m.autor==="cliente"){if(bloco==null){bloco=m.ts;btx=[]}btx.push(m.texto)}
    else if(m.autor!=="sistema"){if(bloco!=null){const t={ini:bloco,cor:(m.ts-bloco)/MIN,com:bizMin(bloco,m.ts),por:m.autor};if(m.autor==="ia"&&m.ts-bloco<IA_MIN_MS)t.rap=true;turnos.push(t);bloco=null}
      if(m.autor==="humano"&&p.transf!=null&&assumir==null)assumir=(m.ts-p.transf)/MIN}}
  if(bloco!=null){const enc=turnos.length>0&&btx.every(ehCortesia);turnos.push(enc?{ini:bloco,cor:null,com:null,por:"enc",enc:true}:{ini:bloco,cor:null,com:null,por:null})}
  return fechaMet(turnos,assumir,p.transf);
}
/* ===== fim das funções do artefato ===== */

// ---------- referências ----------
const deptos = new Map(ler("ref_deptos").map(d => [d.department_id, { nome: d.name, ia: String(d.is_ia_dpto) === "1", cob: String(d.is_cobranca_dpto) === "1", tenant: d.tenant_name }]));
const agRef = new Map(ler("ref_agentes").map(a => [a.id, { nome: (a.name || "").trim(), email: (a.email || "").trim().toLowerCase() }]));
// atendente = e-mail (sem homônimos): ids diferentes com o mesmo e-mail viram um só
const emailCanon = new Map();
const atKey = id => { const a = agRef.get(id); if (!a) return id; if (!a.email) return id; if (!emailCanon.has(a.email)) emailCanon.set(a.email, id); return emailCanon.get(a.email); };
const atNome = id => agRef.get(id)?.nome || "Atendente sem cadastro";
const IA_NOMES = [["e9dbe911", "Esperanza · Blips"], ["c2e3a30e", "Esperanza · Finza"], ["9a952883", "Valentina · Finza"], ["418fb5c2", "Clara · Blips"], ["b9939d16", "Clara · Finza"]];
const iaNome = id => (IA_NOMES.find(([p]) => (id || "").startsWith(p)) || [])[1] || null;

const aiProt = new Map();   // rec|protocol -> {ini, transf, fim, agent}
for (const a of ler("ai_protocols")) {
  const k = a.rec + "|" + a.protocol, v = { ini: wall(a.started_at), transf: wall(a.transferred_at), fim: wall(a.finalized_at), agent: a.agent_id };
  const o = aiProt.get(k); if (!o || (v.ini ?? 0) < (o.ini ?? 0)) aiProt.set(k, v);
}

// ---------- mensagens por chat ----------
const msgsPor = new Map();  // chat_id -> []
const add = (id, m) => { let a = msgsPor.get(id); if (!a) msgsPor.set(id, a = []); a.push(m); };
const protToChat = new Map();
const chats = [...ler("chats_A"), ...ler("chats_B")];
for (const c of chats) protToChat.set(c.rec + "|" + c.protocol, c.chat_id);
const chatSet = new Set(chats.map(c => c.chat_id));
let orfas = 0;
const carregarMsgs = (arq, rec) => { const rows = ler(arq); let n = 0;
  for (const r of rows) { let id = chatSet.has(r.chat_id) ? r.chat_id : protToChat.get(rec + "|" + r.protocol); if (!id) { orfas++; continue; } add(id, r); n++; } return [rows.length, n]; };
const cargas = { msgs_A: carregarMsgs("msgs_A", "A") };
for (const m of ["2026-08", "2026-09", "2026-10", "2026-11"]) cargas["msgs_B_" + m] = carregarMsgs("msgs_B_" + m, "B");

// ---------- gabarito de texto: automação × fala humana ----------
// Nas fontes aproximadas (reconstrução/amostra) ~1/3 das falas humanas chega rotulada "bot" (recall 66%).
// Para não virar "sistema" e gerar "sem resposta" falso, cada texto "out" rotulado bot, em estágio com atendente
// atribuído, é decidido por: (1) gabarito do chat_history (sender_kind oficial) para o mesmo texto;
// (2) texto raro (< 10 ocorrências) = fala humana; (3) texto frequente = humano se ≥ 30% das ocorrências vieram rotuladas agent.
const normTxt = s => (s || "").toLowerCase().replace(/\d+/g, "#").replace(/\s+/g, " ").trim().slice(0, 160);
const TX = { A: new Map(), B: new Map() }, GAB = new Map();
for (const [id, arr] of msgsPor) { const rec = arr[0]?.fonte === "reconstrucao_lastMessage" ? "A" : "B";
  for (const r of arr) { if (r.direction !== "out" || !r.texto || r.message_type === "hsm") continue; const n = normTxt(r.texto);
    let s = TX[rec].get(n); if (!s) TX[rec].set(n, s = { n: 0, ag: 0 }); s.n++; if (r.sender_kind === "agent") s.ag++;
    if (r.fonte === "chat_history_completo") { let g = GAB.get(n); if (!g) GAB.set(n, g = { ag: 0, bot: 0 }); r.sender_kind === "agent" ? g.ag++ : g.bot++; } } }
const botEhHumano = (rec, r) => {
  const mt = r.message_type;
  if (mt === "file" || mt === "document") return false;
  if (mt !== "text" || !r.texto) return true;               // áudio, imagem, hsm em estágio com atendente: gabarito mostra maioria humana
  const n = normTxt(r.texto), g = GAB.get(n);
  if (g && g.ag + g.bot >= 5) return g.ag / (g.ag + g.bot) >= 0.5;
  const s = TX[rec].get(n); if (!s || s.n < 10) return true;
  return s.ag / s.n >= 0.3;
};
let resgatadas = { A: 0, B: 0 };

// Torre (Supabase, org_finza/org_blips.ai_messages): trecho cliente × IA com horário real (occurred_at). Texto retido só de meados de out/2026 em diante.
const TORRE_SEM_TXT = "[texto não retido pela Torre]";
const wallT = s => s ? Date.parse(String(s).replace(" ", "T").replace(/([+-]\d\d)$/, "$1:00")) - OFF : null;
const torreMsgs = new Map(); // rec|protocol -> [{ts, autor, txt, agent}]
const torreStat = { A: null, B: null };
for (const rec of ["A", "B"]) { const T = torreStat[rec] = { linhas: 0, a2a: 0, protocolo_fora_do_recorte: 0, chat_completo_ignorado: 0, fora_do_horario_do_chat: 0, duplicada_do_bq: 0, reclassificada_para_ia: 0, adicionadas: { cliente: 0, ia: 0 }, adicionadas_sem_texto: 0, chats_com_torre: 0 };
  for (const t of ler("torre_ai_messages_" + rec)) { T.linhas++; if (bool(t.is_a2a)) { T.a2a++; continue; } const ts = wallT(t.occurred_at); if (ts == null || isNaN(ts)) continue;
    const k = rec + "|" + t.protocol; let a = torreMsgs.get(k); if (!a) torreMsgs.set(k, a = []); a.push({ ts, autor: t.role === "user" ? "cliente" : "ia", txt: t.content || "", agent: t.agent_id }); } }
const transcr = new Map();  // protocol -> []
for (const t of ler("transcricoes_B")) { let a = transcr.get(t.protocol); if (!a) transcr.set(t.protocol, a = []); a.push({ tipo: t.type, texto: t.text, ts: wall(t.created_at), usado: false }); }

// ---------- helpers de mensagem ----------
const TIPO = { text: "texto", audio: "audio", image: "imagem", file: "documento", video: "video", hsm: "template", sticker: "imagem", document: "documento" };
const PLACE = { audio: "[áudio não transcrito]", image: "[imagem]", file: "[documento]", document: "[documento]", video: "[vídeo]", sticker: "[figurinha]", postback: "[clique em botão]", call: "[ligação]", contact: "[contato compartilhado]", location: "[localização]", reaction: "[reação]", list: "[lista de opções]", flows: "[formulário]", callPermissionReply: "[resposta a pedido de ligação]", callPermissionRequest: "[pedido de ligação]", mail: "[e-mail]" };
const norm = s => (s || "").toLowerCase().replace(/\s+/g, " ").trim();
const CUT = Date.parse("2026-11-19T23:59:59Z") - OFF + OFF; // corte da extração (parede)

function estagios(c) {
  return (c.jornada || []).map(j => ({ d: j.d, a: j.a || null, t: wall(j.t || j.q), e: wall(j.e) })).filter(j => j.t != null).sort((x, y) => x.t - y.t);
}
function estagioEm(est, ts) { let cur = null; for (const s of est) { if (s.t <= ts + 1000) cur = s; else break; } return cur; }

const stats = { A: null, B: null };
const novoStat = () => ({ chats: 0, clientes: 0, broadcast: 0, com_agente: 0, sem_mensagem: 0, msgs: { cliente: 0, humano: 0, ia: 0, sistema: 0 }, msgs_fonte: {}, fonte: {}, tipo: { so_ia: 0, ia_humano: 0, so_humano: 0 },
  com_turno: 0, faixaCor: {}, faixaCom: {}, sem_resposta: 0, encerramento: 0, sem_resposta_aberto: 0, outlier7d: 0, turnos: 0, audio_cli: 0, audio_transcrito: 0, com_cnpj_chats: 0, ambiguo_chats: 0, por_mes: {}, elegiveis: 0, receptivo: 0 });
stats.A = novoStat(); stats.B = novoStat();

const idxOut = fs.createWriteStream(path.join(OUT_M, "protocolos.jsonl"));
const clientes = new Map();
const ats = new Map(); // key -> {id, nome, rec, deptos:Map}
const ABERTO = new Set(["active", "queued", "hold", "overdue"]);

for (const c of chats) {
  const rec = c.rec, S = stats[rec];
  const est = estagios(c);
  const ap = aiProt.get(rec + "|" + c.protocol) || null;
  const passouIA = est.some(s => deptos.get(s.d)?.ia) || !!deptos.get(c.department_id)?.ia;
  const raw = msgsPor.get(c.chat_id) || [];
  const fontesMsg = new Set();
  let msgs = [];
  for (const r of raw) {
    const ts = wall(r.mensagem_em); if (ts == null) continue;
    const dir = r.direction, mt = r.message_type, st = r.system_type;
    let autor, atendente = null, texto = r.texto, tipo = TIPO[mt] || "texto", agId = null, resg = false;
    const sEst = estagioEm(est, ts);
    const dId = r.department_id || sEst?.d || c.department_id;
    if (dir === "info" || mt === "system" || st) {
      autor = "sistema"; tipo = "sistema";
      if (st === "CHAT_TRANSFERED") { const dn = deptos.get(r.sys_department)?.nome, an = r.sys_agent ? atNome(r.sys_agent) : null; texto = "Transferido" + (dn ? ` para ${dn}` : "") + (an && an !== "Atendente sem cadastro" ? ` · ${an}` : ""); }
      else if (st === "FINISH_CHAT") texto = "Atendimento finalizado";
      else if (st === "ACTIVE_CHAT") { const dn = deptos.get(r.sys_department)?.nome; texto = "Atendimento iniciado" + (dn ? ` em ${dn}` : ""); }
      else if (st === "COMMENT_ADDED") texto = "[comentário interno]" + (texto ? " " + texto : "");
      else if (st === "TRIGGER") texto = "[gatilho automático]";
      else texto = texto || "[evento de sistema]";
    } else if (dir === "in") { autor = "cliente"; }
    else if (r.sender_kind === "agent") { autor = "humano"; agId = r.agent_id ? atKey(r.agent_id) : (sEst?.a ? atKey(sEst.a) : null); atendente = agId ? atNome(agId) : "Atendente não identificado"; }
    else { // bot: IA quando o estágio é depto de IA, ou o protocolo de IA (Torre) está ativo e não há humano atribuído
      const dIA = !!deptos.get(dId)?.ia;
      const humanoNoEstagio = !!(sEst && sEst.a && !deptos.get(sEst.d)?.ia);
      const apAtivo = !!ap && ap.ini != null && ts >= ap.ini - 60e3 && ts <= ((ap.transf ?? ap.fim ?? Infinity) + 60e3);
      if (dIA || (apAtivo && !humanoNoEstagio)) { autor = "ia"; atendente = iaNome(ap?.agent) || deptos.get(dId)?.nome || "IA"; }
      else if (humanoNoEstagio && r.fonte !== "chat_history_completo" && botEhHumano(rec, r)) { autor = "humano"; agId = atKey(sEst.a); atendente = atNome(agId); resgatadas[rec]++; resg = true; }
      else { autor = "sistema"; atendente = "Automação"; }
    }
    if (autor !== "sistema" || tipo !== "sistema") {
      if (!texto) texto = mt === "hsm" ? `[template${r.tpl ? " " + r.tpl : ""}]` : (PLACE[mt] || `[${mt || "mensagem"}]`);
    }
    fontesMsg.add(r.fonte);
    msgs.push({ ts, autor, texto, atendente, tipo, _ag: agId, _mt: mt, _f: r.fonte, _resg: !!resg });
  }
  // transcrições (BLIPS): casa por protocolo + tipo + horário mais próximo (até 6 h)
  const tr = transcr.get(c.protocol);
  if (tr && rec === "B") for (const m of msgs) if (m.autor === "cliente" && m._mt === "audio") {
    let best = null; for (const t of tr) if (!t.usado && t.tipo === "audio" && t.texto && t.ts != null) { const d = Math.abs(t.ts - m.ts); if (d <= 6 * 3600e3 && (!best || d < best.d)) best = { t, d }; }
    if (best) { best.t.usado = true; m.texto = "[áudio transcrito] " + best.t.texto; m._tr = true; }
  }
  // Torre: mensagens do cliente e da IA com horário real. Vale para A e B; em B só quando o chat não tem chat_history_completo (completo e oficial).
  // Deduplicação um-para-um contra o BigQuery: mesmo autor, ±5 min e texto contido; ou ±60 s quando um dos lados não tem texto comparável.
  // Fala que o BigQuery rotulou como automação ou resgatou como humana, mas que a Torre confirma como resposta da IA (texto contido, ±5 min), vira "ia".
  { const tu = torreMsgs.get(rec + "|" + c.protocol), T = torreStat[rec];
    if (tu && fontesMsg.has("chat_history_completo")) T.chat_completo_ignorado += tu.length;
    else if (tu) {
      const ini = wall(c.created_at), fim = (wall(c.finished_at) ?? CUT) + DAY, usados = new Set(); let add = 0;
      const contido = (a, b) => a && b && (a.includes(b.slice(0, 60)) || b.includes(a.slice(0, 60)));
      for (const t of tu) { if (t.ts < ini - 3600e3 || t.ts > fim) { T.fora_do_horario_do_chat++; continue; }
        const nt = norm(t.txt); let best = null, reclass = null;
        for (let i = 0; i < msgs.length; i++) { const m = msgs[i]; if (usados.has(i)) continue; const d = Math.abs(m.ts - t.ts); if (d > 5 * 60e3) continue; const k = norm(m.texto), semK = !k || k.startsWith("[");
          if (m.autor === t.autor) { if ((contido(nt, k) && !semK) || (d <= 60e3 && (!nt || semK))) { if (!best || d < best.d) best = { i, d }; } }
          else if (t.autor === "ia" && nt && !semK && contido(nt, k) && ((m.autor === "sistema" && m.atendente === "Automação") || (m.autor === "humano" && m._resg))) { if (!reclass || d < reclass.d) reclass = { i, d }; } }
        if (best) { usados.add(best.i); T.duplicada_do_bq++; continue; }
        if (reclass) { const m = msgs[reclass.i]; usados.add(reclass.i); m.autor = "ia"; m.atendente = iaNome(t.agent) || iaNome(ap?.agent) || "IA"; m._ag = null; m._resg = false; T.reclassificada_para_ia++; continue; }
        msgs.push({ ts: t.ts, autor: t.autor, texto: t.txt || TORRE_SEM_TXT, atendente: t.autor === "ia" ? (iaNome(t.agent) || iaNome(ap?.agent) || "IA") : null, tipo: "texto", _ag: null, _mt: "text", _f: "torre_ai_messages" });
        fontesMsg.add("torre_ai_messages"); T.adicionadas[t.autor]++; if (!t.txt) T.adicionadas_sem_texto++; add++; }
      if (add) T.chats_com_torre++;
    } }
  msgs.sort((a, b) => a.ts - b.ts);

  // transferência IA → humano: início do 1º estágio humano depois de um estágio de IA (ou transferred_at da Torre)
  let transf = null, viuIA = false;
  for (const s of est) { if (deptos.get(s.d)?.ia) viuIA = true; else if (viuIA) { transf = s.t; break; } }
  if (transf == null && ap?.transf != null) transf = ap.transf;
  if (transf != null && msgs.some(m => m.autor === "humano" && m.ts < transf)) transf = null;

  const temIA = msgs.some(m => m.autor === "ia"), temHum = msgs.some(m => m.autor === "humano");
  const agentesJ = [...new Set([...(c.agentes || []), ...est.map(s => s.a).filter(Boolean)].map(atKey))];
  const envolveIA = passouIA || !!ap;
  const tipo = temIA && temHum ? "ia_humano" : temIA ? "so_ia" : temHum ? "so_humano" : envolveIA ? (agentesJ.length ? "ia_humano" : "so_ia") : "so_humano";

  const p = { msgs, transf };
  const met = metricas(p);
  // dono de cada turno respondido por humano (spec 03 §6)
  const respAg = new Map(); { let bloco = null; for (const m of msgs) { if (m.autor === "cliente") { if (bloco == null) bloco = m.ts; } else if (m.autor !== "sistema") { if (bloco != null) { respAg.set(bloco, m._ag); bloco = null; } } } }
  const contAg = {}; for (const t of met.turnos) { t.at = respAg.get(t.ini) ?? null; if (t.por === "humano" && t.at) contAg[t.at] = (contAg[t.at] || 0) + 1; }
  const agMsgs = [...new Set(msgs.filter(m => m.autor === "humano" && m._ag).map(m => m._ag))];
  const atId = Object.entries(contAg).sort((a, b) => b[1] - a[1])[0]?.[0] || agMsgs.at(-1) || (c.agent_id ? atKey(c.agent_id) : null) || agentesJ.at(-1) || null;
  const iaNomes = [...new Set(msgs.filter(m => m.autor === "ia").map(m => m.atendente))];
  const humIds = [...new Set([...agMsgs, ...(tipo !== "so_ia" && atId ? [atId] : [])])];
  const atendentes = [...iaNomes, ...humIds.map(atNome)];
  const deptoNome = c.department_name || deptos.get(c.department_id)?.nome || "Sem departamento";
  const deptosJ = [...new Set([...est.map(s => deptos.get(s.d)?.nome).filter(Boolean), deptoNome])];
  const aberto = ABERTO.has(c.status);
  const outlier = met.turnos.some(t => t.cor != null && t.cor > 7 * 1440);
  const primCli = msgs.find(m => m.autor !== "sistema");
  const receptivo = !bool(c.is_broadcast) && primCli?.autor === "cliente";
  const fonte = fontesMsg.has("torre_ai_messages") ? "BQ + Torre (IA)" : !raw.length ? (rec === "A" ? "BQ reconstrução" : "BQ amostra") : fontesMsg.has("chat_history_completo") ? "BQ completa" : fontesMsg.has("tb_chat_messages_amostra") ? "BQ amostra" : "BQ reconstrução";
  const inicio = wall(c.created_at), fim = wall(c.finished_at);
  const telDig = (c.contact_phone || "").replace(/\D/g, "");
  const cliId = `${rec}_${c.tel_canon || telDig || c.contact_id || c.chat_id}`;
  const cnpjs = [...new Set(((c.clientes_crm || []).map(x => x.cnpj_cpf).filter(Boolean).length ? (c.clientes_crm || []).map(x => x.cnpj_cpf) : [c.cnpj_principal]).filter(Boolean))];

  // ---- estatísticas (só contagens) ----
  S.chats++; if (bool(c.is_broadcast)) S.broadcast++; if ((c.agentes || []).length) S.com_agente++; if (!raw.length) S.sem_mensagem++;
  for (const m of msgs) { S.msgs[m.autor]++; S.msgs_fonte[m._f] = (S.msgs_fonte[m._f] || 0) + 1; if (m.autor === "cliente" && m._mt === "audio") { S.audio_cli++; if (m._tr) S.audio_transcrito++; } }
  S.fonte[fonte] = (S.fonte[fonte] || 0) + 1; S.tipo[tipo]++;
  if (met.turnos.length) { S.com_turno++; S.elegiveis++; S.turnos += met.turnos.length; S.faixaCor[met.faixaCor] = (S.faixaCor[met.faixaCor] || 0) + 1; S.faixaCom[met.faixaCom] = (S.faixaCom[met.faixaCom] || 0) + 1;
    if (met.encerramento) S.encerramento++;
    if (met.semResposta) { S.sem_resposta++; if (aberto) S.sem_resposta_aberto++; } }
  if (outlier) S.outlier7d++; if (receptivo) S.receptivo++; if (cnpjs.length) S.com_cnpj_chats++; if (bool(c.match_ambiguo)) S.ambiguo_chats++;
  const mes = new Date(inicio).toISOString().slice(0, 7); S.por_mes[mes] = (S.por_mes[mes] || 0) + 1;

  // ---- clientes / atendentes ----
  let cli = clientes.get(cliId);
  if (!cli) clientes.set(cliId, cli = { id: cliId, rec, telefone: c.contact_phone || "", cnpjs: [], ambiguo: false, nome: null, protocolos: [] });
  for (const x of cnpjs) if (!cli.cnpjs.includes(x)) cli.cnpjs.push(x);
  if (bool(c.match_ambiguo)) cli.ambiguo = true; if (!cli.nome && c.nome_crm) cli.nome = c.nome_crm;
  cli.protocolos.push(c.chat_id);
  for (const id of humIds) { const k = rec + "|" + id; let a = ats.get(k); if (!a) ats.set(k, a = { id, rec, nome: atNome(id), deptos: {}, n: 0 }); a.n++; a.deptos[deptoNome] = (a.deptos[deptoNome] || 0) + 1; }

  const limpa = msgs.map(m => ({ ts: m.ts, autor: m.autor, texto: m.texto, atendente: m.atendente, tipo: m.tipo }));
  const semana = (() => { const d = new Date(inicio), j = Date.UTC(d.getUTCFullYear(), 0, 1); return d.getUTCFullYear() + "-" + String(Math.ceil(((inicio - j) / DAY + new Date(j).getUTCDay() + 1) / 7)).padStart(2, "0"); })();
  idxOut.write(JSON.stringify({ id: c.chat_id, protocol: c.protocol, rec, cliente: cliId, tipo, depto: deptoNome, deptos: deptosJ, atendentes, atId: tipo === "so_ia" ? null : atId, humIds, inicio, fim, status: c.status, aberto, broadcast: bool(c.is_broadcast), receptivo, transf, fonte, nMsgs: limpa.length, nCli: limpa.filter(m => m.autor === "cliente").length, audioNT: limpa.some(m => m.texto.includes("não transcrito")), semana, outlier, hi_ui: c.hi_ui, hi_si: c.hi_si, met }) + "\n");
  if (!SEM_ARQ) fs.writeFileSync(path.join(OUT_P, c.chat_id + ".json"), JSON.stringify({ chat_id: c.chat_id, protocol: c.protocol, recorte: rec === "A" ? "FINZA" : "BLIPS · Cobrança", rec, departamentos: deptosJ, atendentes, tipo, receptivo, inicio: isoBR(inicio), fim: isoBR(fim), status: c.status, fonte, transf,
    mensagens: limpa.map(m => ({ ts: isoBR(m.ts), autor: m.autor, atendente: m.atendente, tipo: m.tipo, texto: m.texto })),
    metricas: { n_turnos: met.turnos.length, turnos: met.turnos.map(t => ({ inicio: isoBR(t.ini), espera_corrida_min: t.cor == null ? null : +t.cor.toFixed(1), espera_comercial_min: t.com == null ? null : +t.com.toFixed(1), respondeu: t.por })),
      pior_espera_min: met.pior, primeira_resposta_min: met.primeira, faixa_pior_corrida: met.faixaCor, faixa_pior_comercial: met.faixaCom, sem_resposta: met.semResposta, encerramento_cliente: met.encerramento, chat_aberto_no_corte: aberto } }));
}
idxOut.end();
for (const r of ["A", "B"]) stats[r].clientes = [...clientes.values()].filter(c => c.rec === r).length;
for (const r of ["A", "B"]) { const cs = [...clientes.values()].filter(c => c.rec === r); stats[r].clientes_com_cnpj = cs.filter(c => c.cnpjs.length).length; stats[r].clientes_ambiguos = cs.filter(c => c.ambiguo).length; stats[r].atendentes = [...ats.values()].filter(a => a.rec === r).length; }
fs.writeFileSync(path.join(OUT_M, "clientes.jsonl"), [...clientes.values()].map(c => JSON.stringify(c)).join("\n") + "\n");
fs.writeFileSync(path.join(OUT_M, "atendentes.json"), JSON.stringify([...ats.values()].map(a => ({ id: a.id, rec: a.rec, nome: a.nome, depto: Object.entries(a.deptos).sort((x, y) => y[1] - x[1])[0]?.[0] || "", n: a.n }))));
for (const rec of ["A", "B"]) { const ps = new Set(chats.filter(c => c.rec === rec).map(c => String(c.protocol))); for (const [k, a] of torreMsgs) if (k.startsWith(rec + "|") && !ps.has(k.slice(2))) torreStat[rec].protocolo_fora_do_recorte += a.length; }
const resumo = { gerado_em: new Date().toISOString(), cargas, mensagens_orfas: orfas, falas_humanas_resgatadas: resgatadas, torre: torreStat, ...stats };
fs.writeFileSync(path.join(OUT_M, "resumo.json"), JSON.stringify(resumo, null, 1));
console.log(JSON.stringify(resumo, null, 1));
