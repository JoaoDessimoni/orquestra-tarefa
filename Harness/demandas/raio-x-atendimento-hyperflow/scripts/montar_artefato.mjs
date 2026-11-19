// Etapa 6 — monta os arquivos de dados publicados ao lado da página do artefato (spec 06).
// Lê dados/metricas/* e dados/protocolos/<chat_id>.json e grava em dados/artefato/data/:
//   meta.json            data da extração, contagens por recorte, atendentes, notas, lista de arquivos
//   idx_<rec>[_n].json   índice compacto de clientes e protocolos, SEM texto de mensagem (tem telefone/CNPJ — PII)
//   m/<rec>_<nnn>.json   mensagens em lotes por cliente (PII), carregadas sob demanda
// Saída no terminal: só contagens e tamanhos.
// Uso: node --max-old-space-size=8192 scripts/montar_artefato.mjs [--teste 200]
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const BASE = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DM = path.join(BASE, "dados", "metricas"), DP = path.join(BASE, "dados", "protocolos");
const OUT = path.join(BASE, "dados", "artefato", "data");
const iT = process.argv.indexOf("--teste"), TESTE = iT > 0 ? Number(process.argv[iT + 1] || 200) : 0;
const LOTE_ALVO = 1.5e6, IDX_MAX = 12e6, OFF = 3 * 3600e3;
const EXTRAIDO_EM = "2026-11-19";

// funções de métrica: as mesmas do normalizar.mjs / HTML (lidas do fonte para não existir terceira cópia)
const srcN = fs.readFileSync(path.join(BASE, "scripts", "normalizar.mjs"), "utf8");
const blk = srcN.slice(srcN.indexOf("function bizMin"), srcN.indexOf("/* ===== fim das funções do artefato"));
const median = a => { if (!a.length) return null; const s = [...a].sort((x, y) => x - y), m = s.length >> 1; return s.length % 2 ? s[m] : (s[m - 1] + s[m]) / 2; };
const mean = a => a.length ? a.reduce((x, y) => x + y, 0) / a.length : null;
const MIN = 60000, DAY = 86400000, CFG = { exp: { dias: [1, 2, 3, 4, 5], ini: 8, fim: 18 } };
const { metricas, fechaMet, bizMin } = new Function("CFG", "DAY", "MIN", "median", "mean", blk + ";return {metricas,fechaMet,bizMin}")(CFG, DAY, MIN, median, mean);

const jl = f => fs.readFileSync(path.join(DM, f), "utf8").split("\n").filter(Boolean).map(l => JSON.parse(l));
const P = jl("protocolos.jsonl"), C = jl("clientes.jsonl"), ATS = JSON.parse(fs.readFileSync(path.join(DM, "atendentes.json"), "utf8"));
const resumo = JSON.parse(fs.readFileSync(path.join(DM, "resumo.json"), "utf8"));
const bytes = s => Buffer.byteLength(s, "utf8");
const dicio = () => { const m = new Map(), l = []; return { l, i: v => { let k = m.get(v); if (k == null) { m.set(v, k = l.length); l.push(v); } return k; } }; };

// A publicação recusa U+FFFD (caractere corrompido na origem) e o JSON não deve levar surrogate solto nem controle: vira U+25A1 (quadrado vazio).
// Para ehCortesia tanto faz (ambos são não-letra), e a prova de métricas abaixo roda já com o texto limpo.
const limpo = t => typeof t === "string" ? t.toWellFormed().replace(/[\uFFFD\u0000-\u0008\u000B\u000C\u000E-\u001F]/g, "\u25A1") : t;
const AUT = ["cliente", "humano", "ia", "sistema"], TIPOS_MSG = ["texto", "audio", "imagem", "documento", "video", "template", "sistema"];
const TIPO_P = ["so_ia", "ia_humano", "so_humano"], POR = { ia: 0, humano: 1 };

// ----- conversa: arquivo local -> formato compacto [base, [dt, autor, texto, atendenteIdx?, tipoIdx?], ...]
function lerMsgs(id) {
  const j = JSON.parse(fs.readFileSync(path.join(DP, id + ".json"), "utf8"));
  return j.mensagens.map(m => ({ ts: Date.parse(m.ts) - OFF, autor: m.autor, texto: limpo(m.texto), atendente: m.atendente ?? null, tipo: m.tipo }));
}
function compactar(msgs, nomes) {
  if (!msgs.length) return [0];
  const out = [msgs[0].ts]; let prev = msgs[0].ts;
  for (const m of msgs) {
    const a = AUT.indexOf(m.autor), t = TIPOS_MSG.indexOf(m.tipo), tDef = a === 3 ? 6 : 0, n = m.atendente == null ? -1 : nomes.i(m.atendente);
    if (a < 0 || t < 0) throw new Error("autor/tipo fora do dicionário: " + m.autor + "/" + m.tipo);
    const r = [m.ts - prev, a, m.texto]; if (n >= 0 || t !== tDef) r.push(n); if (t !== tDef) r.push(t);
    out.push(r); prev = m.ts;
  }
  return out;
}
// decodificador: MESMA lógica do carregador da página (decMsgs no HTML)
function expandir(arr, nomes) {
  const out = []; let ts = arr[0];
  for (let i = 1; i < arr.length; i++) { const r = arr[i]; ts += r[0]; out.push({ ts, autor: AUT[r[1]], texto: r[2], atendente: r[3] != null && r[3] >= 0 ? nomes[r[3]] : null, tipo: TIPOS_MSG[r[4] ?? (r[1] === 3 ? 6 : 0)] }); }
  return out;
}
// turnos do índice -> formato compacto [iniDelta, durMs (-1 sem resposta, -2 encerramento), por (0 IA, 1 humano, 2 IA fora da medição: < 3 s)]
function turnosCompactos(p) {
  const out = [];
  for (const t of p.met.turnos) { const dur = t.enc ? -2 : t.cor == null ? -1 : Math.round(t.cor * MIN); out.push(t.ini - p.inicio, dur, t.enc || t.cor == null ? -1 : t.rap ? 2 : POR[t.por]); }
  return out;
}
// decodificador de turnos: MESMA lógica do carregador da página
function turnosExpandidos(flat, inicio) {
  const out = [];
  for (let i = 0; i < flat.length; i += 3) { const ini = inicio + flat[i], d = flat[i + 1];
    out.push(d === -2 ? { ini, cor: null, com: null, por: "enc", enc: true } : d === -1 ? { ini, cor: null, com: null, por: null } : flat[i + 2] === 2 ? { ini, cor: d / MIN, com: bizMin(ini, ini + d), por: "ia", rap: true } : { ini, cor: d / MIN, com: bizMin(ini, ini + d), por: flat[i + 2] === 0 ? "ia" : "humano" }); }
  return out;
}
const igual = (a, b) => JSON.stringify(a) === JSON.stringify(b);
const semAt = m => ({ ...m, turnos: m.turnos.map(({ at, ...t }) => t) });

// ----- teste de carga (spec 06 §3): projeta o total a partir de N protocolos
if (TESTE) {
  let seed = 20261119; const R = () => { seed |= 0; seed = seed + 0x6D2B79F5 | 0; let t = Math.imul(seed ^ seed >>> 15, 1 | seed); t = t + Math.imul(t ^ t >>> 7, 61 | t) ^ t; return ((t ^ t >>> 14) >>> 0) / 4294967296; };
  for (const rec of ["A", "B"]) {
    const todos = P.filter(p => p.rec === rec), am = []; const usados = new Set();
    while (am.length < Math.min(TESTE, todos.length)) { const k = Math.floor(R() * todos.length); if (!usados.has(k)) { usados.add(k); am.push(todos[k]); } }
    const nomes = dicio(); let bM = 0, bI = 0, nM = 0;
    for (const p of am) { const msgs = lerMsgs(p.id); nM += msgs.length; bM += bytes(JSON.stringify(compactar(msgs, nomes))) + 45; bI += bytes(JSON.stringify([p.id, p.protocol, 0, 0, 0, [0], 0, p.inicio, 0, 0, 0, 0, turnosCompactos(p)])) + 2; }
    const f = todos.length / am.length;
    console.log(`TESTE ${rec}: ${am.length} protocolos · ${nM} msgs · mensagens ${(bM / am.length).toFixed(0)} B/protocolo · índice ${(bI / am.length).toFixed(0)} B/protocolo`);
    console.log(`  projeção ${rec} (${todos.length} protocolos): mensagens ${(bM * f / 1e6).toFixed(1)} MB (~${Math.ceil(bM * f / LOTE_ALVO)} lotes de 1,5 MB) · índice ${(bI * f / 1e6).toFixed(1)} MB`);
  }
  process.exit(0);
}

// ----- geração completa
fs.rmSync(OUT, { recursive: true, force: true }); fs.mkdirSync(path.join(OUT, "m"), { recursive: true });
const arquivos = []; const grava = (rel, txt) => { txt = limpo(txt); fs.writeFileSync(path.join(OUT, rel), txt); arquivos.push({ rel: "data/" + rel, bytes: bytes(txt) }); };
const meta = { v: 1, extraido_em: EXTRAIDO_EM, gerado_em: new Date().toISOString(), janela: null, fuso: "relógio de parede de Brasília gravado como ms UTC", rec: {}, notas: [] };
let jMin = Infinity, jMax = -Infinity, divergencias = 0;

for (const rec of ["A", "B"]) {
  const Pr = P.filter(p => p.rec === rec).sort((a, b) => a.inicio - b.inicio || (a.id < b.id ? -1 : 1));
  const Cr = C.filter(c => c.rec === rec).sort((a, b) => a.id < b.id ? -1 : 1);
  const ats = ATS.filter(a => a.rec === rec).sort((a, b) => a.nome.localeCompare(b.nome, "pt-BR") || (a.id < b.id ? -1 : 1));
  const atIdx = new Map(ats.map((a, i) => [a.id, i])), cliIdx = new Map(Cr.map((c, i) => [c.id, i]));
  const dDepto = dicio(), dNome = dicio(), dFonte = dicio();
  const porCli = new Map(); for (const p of Pr) { let a = porCli.get(p.cliente); if (!a) porCli.set(p.cliente, a = []); a.push(p); }

  // lotes de mensagens: clientes em ordem de id, enchendo até ~1,5 MB
  const loteDe = new Array(Cr.length).fill(0); const iaCont = {}; let nMsgs = 0, nAudioNT = 0;
  let lote = 0, tam = 0, nomes = dicio(), partes = [];
  const fecha = () => { if (!partes.length) return; grava(`m/${rec}_${String(lote).padStart(3, "0")}.json`, `{"v":1,"n":${JSON.stringify(nomes.l)},"c":{\n${partes.join(",\n")}\n}}`); lote++; tam = 0; nomes = dicio(); partes = []; };
  Cr.forEach((c, ci) => {
    const chats = [];
    for (const p of porCli.get(c.id) || []) {
      const msgs = lerMsgs(p.id); nMsgs += msgs.length;
      for (const m of msgs) if (m.autor === "ia") iaCont[m.atendente] = (iaCont[m.atendente] || 0) + 1;
      const comp = compactar(msgs, nomes);
      // prova: mensagens decodificadas + índice decodificado reproduzem as métricas do índice
      const back = expandir(comp, nomes.l), m1 = metricas({ msgs: back, transf: p.transf });
      const m2 = fechaMet(turnosExpandidos(turnosCompactos(p), p.inicio), p.met.assumir ? p.met.assumir.cor : null, p.transf);
      if (!igual(m1, semAt(p.met)) || !igual(m2, semAt(p.met))) divergencias++;
      if (msgs.some(m => m.texto.includes("não transcrito")) !== !!p.audioNT) divergencias++;
      if (p.audioNT) nAudioNT++;
      chats.push(JSON.stringify(p.id) + ":" + JSON.stringify(comp));
    }
    const txt = JSON.stringify(c.id) + ":{" + chats.join(",") + "}", b = bytes(txt);
    if (tam && tam + b > LOTE_ALVO) fecha();
    loteDe[ci] = lote; partes.push(txt); tam += b;
  });
  fecha();

  // índice
  const cliLin = Cr.map((c, i) => JSON.stringify([c.id, c.telefone, c.cnpjs, c.ambiguo ? 1 : 0, c.nome, loteDe[i]]));
  const protLin = Pr.map(p => {
    if (p.inicio < jMin) jMin = p.inicio; if (p.inicio > jMax) jMax = p.inicio;
    const flags = (p.aberto ? 1 : 0) | (p.broadcast ? 2 : 0) | (p.receptivo ? 4 : 0) | (p.outlier ? 8 : 0) | (p.audioNT ? 16 : 0);
    const ai = p.atId != null && atIdx.has(p.atId) ? atIdx.get(p.atId) : -1;
    return JSON.stringify([p.id, p.protocol, cliIdx.get(p.cliente), TIPO_P.indexOf(p.tipo), dDepto.i(p.depto), p.atendentes.map(n => dNome.i(n)), ai, p.inicio,
      p.transf == null ? null : p.transf - p.inicio, dFonte.i(p.fonte), flags, p.met.assumir ? Math.round(p.met.assumir.cor * MIN) : null, turnosCompactos(p)]);
  });
  const cab = `"v":1,"rec":"${rec}","dic":${JSON.stringify({ depto: dDepto.l, nome: dNome.l, fonte: dFonte.l, tipo: TIPO_P })}`;
  const idxArqs = []; let parte = [], pt = 0, k = 0;
  const fechaIdx = ult => { const nome = `idx_${rec}${idxArqs.length || !ult ? "_" + (idxArqs.length + 1) : ""}.json`;
    grava(nome, `{${cab},${idxArqs.length ? "" : `"cli":[\n${cliLin.join(",\n")}\n],`}"prot":[\n${parte.join(",\n")}\n]}`); idxArqs.push("data/" + nome); parte = []; pt = 0; };
  const cliB = bytes(cliLin.join(",\n"));
  for (const l of protLin) { const b = bytes(l) + 2; if (parte.length && pt + b + (idxArqs.length ? 0 : cliB) > IDX_MAX) fechaIdx(false); parte.push(l); pt += b; k++; }
  fechaIdx(true);

  // rótulo da IA: famílias de agente com fala no recorte (pela contagem de mensagens da IA)
  const fam = {}; for (const [n, v] of Object.entries(iaCont)) { const f = (n || "IA").split(" · ")[0]; fam[f] = (fam[f] || 0) + v; }
  const tot = Object.values(fam).reduce((a, b) => a + b, 0), rel = Object.entries(fam).filter(([, v]) => v / tot >= 0.01).sort((a, b) => b[1] - a[1]);
  // agentes com nome (Esperanza, Valentina, Clara) entram pelo nome; falas rotuladas só pelo departamento de IA viram "filas de IA"
  const ehFila = f => f === "IA" || f.startsWith("IA -");
  const nomeados = rel.filter(([f]) => !ehFila(f)).map(([f]) => f), temFila = rel.some(([f]) => ehFila(f));
  const rotIA = nomeados.length ? `IA (${nomeados.join(" / ")}${temFila ? " e filas de IA" : ""})` : "IA";
  const comT = Pr.filter(p => p.met.turnos.length);
  const cont = (arr, f) => arr.reduce((o, x) => (o[f(x)] = (o[f(x)] || 0) + 1, o), {});
  const S = resumo[rec];
  meta.rec[rec] = { nome: rec === "A" ? "FINZA" : "BLIPS · Cobrança", protocolos: Pr.length, clientes: Cr.length, com_turno: comT.length, sem_resposta: comT.filter(p => p.met.semResposta).length,
    encerramento: Pr.filter(p => p.met.encerramento).length, tipos: cont(Pr, p => p.tipo), fonte: cont(Pr, p => p.fonte), faixaCom: cont(comT, p => p.met.faixaCom), faixaCor: cont(comT, p => p.met.faixaCor),
    mensagens: nMsgs, audio_cliente: S.audio_cli, audio_transcrito: S.audio_transcrito, protocolos_com_audio_nt: nAudioNT, pct_chats_com_cnpj: +(100 * S.com_cnpj_chats / S.chats).toFixed(1), sem_mensagem_do_cliente: Pr.length - comT.length, mediana_msgs_por_fonte: Object.fromEntries(Object.entries(Pr.reduce((o, p) => ((o[p.fonte] ??= []).push(p.nMsgs), o), {})).map(([f, a]) => [f, median(a)])),
    turnos_ia_medidos: Pr.reduce((s, p) => s + p.met.turnos.filter(t => t.por === "ia" && !t.rap).length, 0), turnos_ia_fora_da_medicao: Pr.reduce((s, p) => s + p.met.turnos.filter(t => t.rap).length, 0),
    ia_rotulo: rotIA, ia_familias: fam, ats: ats.map(a => ({ id: a.id, nome: a.nome, depto: a.depto })), idx: idxArqs, lotes: lote, lote_prefixo: `data/m/${rec}_` };
}
const d2 = ms => { const d = new Date(ms); return `${String(d.getUTCDate()).padStart(2, "0")}/${String(d.getUTCMonth() + 1).padStart(2, "0")}/${d.getUTCFullYear()}`; };
meta.janela = { ini: jMin, fim: jMax, rotulo: `${d2(jMin).slice(0, 5)} a ${d2(jMax)}` };
meta.notas = [
  "Todas as conversas vêm do BigQuery. A avaliação por IA (score de qualidade, assunto, frustração) ainda não rodou: aguarda a conversa completa pelo Desk.",
  "FINZA: conversa reconstruída (cerca de metade das mensagens). BLIPS · Cobrança: histórico completo em 34% dos chats; o restante é amostra.",
  "Áudio do cliente quase todo sem transcrição.",
  "CNPJ vem do CRM pelo telefone; telefone ligado a mais de um CNPJ aparece como ambíguo.",
  "Encerramento do cliente: último bloco só com cortesia curta, depois de um turno respondido, não conta como sem resposta.",
  "Resposta da IA: medida entre a mensagem real do cliente e a resposta da IA. Resposta em menos de 3 s fica fora da medição. No FINZA, o lado do cliente vem da reconstrução; sem a mensagem do cliente não há turno.",
  "A maior parte das conversas aparece incompleta ou só com o disparo. A conversa completa depende da carga pelo Desk, ainda pendente."
];
grava("meta.json", JSON.stringify(meta, null, 1));

// ----- relatório (só contagens)
const tot = arquivos.reduce((s, a) => s + a.bytes, 0), maior = arquivos.reduce((a, b) => b.bytes > a.bytes ? b : a);
console.log(JSON.stringify({ arquivos: arquivos.length, mb_total: +(tot / 1e6).toFixed(2), maior: { arquivo: maior.rel, mb: +(maior.bytes / 1e6).toFixed(2) },
  indices: arquivos.filter(a => a.rel.includes("idx_")).map(a => ({ arquivo: a.rel, mb: +(a.bytes / 1e6).toFixed(2) })),
  lotes: Object.fromEntries(["A", "B"].map(r => [r, { n: meta.rec[r].lotes, mb: +(arquivos.filter(a => a.rel.includes(`/m/${r}_`)).reduce((s, a) => s + a.bytes, 0) / 1e6).toFixed(2) }])),
  janela: meta.janela.rotulo, divergencias_metricas: divergencias,
  recortes: Object.fromEntries(["A", "B"].map(r => { const { ats, ia_familias, ...x } = meta.rec[r]; return [r, { ...x, atendentes: ats.length }]; })) }, null, 1));
fs.writeFileSync(path.join(BASE, "dados", "artefato", "_arquivos.json"), JSON.stringify(arquivos, null, 1));
if (divergencias) { console.error("ERRO: métricas recalculadas divergem do índice em " + divergencias + " protocolos"); process.exit(1); }
