// node build.js <live.html> <fetch.json> <out.html> <syncISO>
// Remove o botão "Sincronizar com Quimera", aplica o espelho do Quimera automaticamente na leitura
// e atualiza o qmirror com o fetch do dia.
const fs = require('fs');
const [,, LIVE, FETCH, OUT, AT] = process.argv;
let h = fs.readFileSync(LIVE, 'utf8');
const lines = h.split('\n');
const DEV = { '857575b1': 'Leandro', '409661f3': 'Marcos', 'f403707d': 'João Pedro', 'b90f482e': 'Joao Lucas', '34a15ef4': 'João Vinícius' };

// 1) qmirror
const qi = lines.findIndex(l => l.startsWith('<script type="application/json" id="qmirror">'));
const q = JSON.parse(lines[qi].replace(/^<script[^>]*>/, '').replace(/<\/script>$/, ''));
const f = JSON.parse(fs.readFileSync(FETCH, 'utf8'));
for (const [k, t] of Object.entries(f)) {
  const m = q[k] || {};
  // nomes ausentes no fetch: reaproveita os do espelho anterior (mesmo timestamp)
  const oldC = {}; (m.c || []).forEach(c => { if (c.a) oldC[c.dt] = c.a; });
  const oldH = {}; (m.h || []).forEach(x => { if (x.por) oldH[x.dt] = x.por; });
  (t.c || []).forEach(c => { if (!c.a && oldC[c.dt]) c.a = oldC[c.dt]; if (!c.a) c.a = 'Solicitante'; delete c.uid; });
  (t.h || []).forEach(x => { if (!x.por && oldH[x.dt]) x.por = oldH[x.dt]; delete x.uid; });
  const dv = t.asg ? DEV[String(t.asg).slice(0, 8)] : null;
  q[k] = Object.assign(m, { t: t.t, s: t.s, d: t.d != null ? t.d : m.d, edd: t.edd || null, c: t.c || m.c || [], h: (t.h && t.h.length) ? t.h : (m.h || []) });
  if (t.res) q[k].res = t.res; else delete q[k].res;
  if (dv) q[k].dv = dv;
  if (t.sp != null) q[k].sp = t.sp;
}
lines[qi] = '<script type="application/json" id="qmirror">' + JSON.stringify(q).replace(/<\//g, '<\\/') + '</script>';

// 2) qmig -> qmeta
const gi = lines.findIndex(l => l.startsWith('<script type="application/json" id="qmig">'));
if (gi < 0) throw new Error('qmig não encontrado');
lines[gi] = '<script type="application/json" id="qmeta">' + JSON.stringify({ at: AT, janela: { de: '2026-10-01', ate: AT.slice(0, 10) } }) + '</script>';
h = lines.join('\n');

const rep = (a, b) => { if (!h.includes(a)) throw new Error('não achei: ' + a.slice(0, 80)); h = h.split(a).join(b); };

// 3) botão -> carimbo de sincronização
rep(`<button class="btn sm" id="qsync" hidden style="width:100%;justify-content:center">Sincronizar com Quimera</button><span class="svst" id="qsync-st" style="display:block;margin-top:4px;line-height:1.35"></span>`,
    `<span class="svst" id="qsync-st" style="display:block;line-height:1.35"></span>`);

// 4) QMIG -> QMETA
h = h.replace(/const QMIG=\(\(\)=>\{.*\}\)\(\);/, `const QMETA=(()=>{try{return JSON.parse(document.getElementById('qmeta').textContent||'{}')}catch(e){return{}}})();`);
if (h.includes('QMIG=')) throw new Error('QMIG ainda presente');

// 5) remove qcompute/qsync (de "let qShown" até o fim de qsync)
const a = h.indexOf('let qShown=false,qReset=null;');
const bMark = `}catch(e){setSt('#qsync-st',failMsg(e),'err')}}`;
const b = h.indexOf(bMark, a);
if (a < 0 || b < 0) throw new Error('bloco qsync não encontrado');
h = h.slice(0, a) + `/* Quimera → roadmap: aplicado automaticamente na leitura (qoverlay). Sem botão. */
function qoverlay(c){if(c.key==null)return c;const m=QMIRROR[String(c.key)];if(!m||m.missing)return c;
  if(m.s)c.qs=m.s;
  if(m.edd){c.fp=m.edd;c.df='quimera';c.fpq=true}
  if(m.s==='finalizado'&&m.res)c.fr=String(m.res).slice(0,10);
  if(m.dv)c.dev=m.dv;if(m.sp!=null)c.sp=m.sp;return c}
function paintSync(){const el=$('#qsync-st');if(!el||!QMETA.at)return;const d=new Date(QMETA.at);el.textContent='Quimera sincronizado em '+d.toLocaleDateString('pt-BR')+' às '+d.toLocaleTimeString('pt-BR',{hour:'2-digit',minute:'2-digit'})+'.'}
` + h.slice(b + bMark.length);

// 6) handler e visibilidade do botão
rep(`  if(t.id==='qsync'){qsync();return}\n`, '');
rep(`const qsb=$('#qsync');if(qsb)qsb.hidden=!S.canAdmin;`, '');

// 7) overlay na leitura do db
rep(`if(!c.desc&&c.key!=null){const m=QMIRROR[String(c.key)];if(m&&m.d){c.desc=m.d;S.hy.add(k)}}}catch(e){}its[k]=c});`,
    `if(!c.desc&&c.key!=null){const m=QMIRROR[String(c.key)];if(m&&m.d){c.desc=m.d;S.hy.add(k)}}qoverlay(c)}catch(e){}its[k]=c});`);

// 8) aviso no planejamento: data prevista vem do Quimera
rep("${d.df==='sugerida'?`<div class=\"note\">${ic('info')}<span>Datas sugeridas pelo supervisor. O time técnico confirma ao puxar a demanda.</span></div>`:''}</div>",
    "${d.fpq?`<p class=\"src\">Entrega prevista = data do Quimera (#${esc(d.key)}). Para mudar, altere no Quimera.</p>`:d.df==='sugerida'?`<div class=\"note\">${ic('info')}<span>Datas sugeridas pelo supervisor. O time técnico confirma ao puxar a demanda.</span></div>`:''}</div>");

// 9) carimbo ao iniciar
rep(`const slow=setTimeout(`, `try{paintSync()}catch(e){}\nconst slow=setTimeout(`);

fs.writeFileSync(OUT, h);
console.log('ok', OUT, h.length, 'qmirror', Object.keys(q).length);
