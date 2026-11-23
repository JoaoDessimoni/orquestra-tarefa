// node update-qmirror.js <live.html> <fetch.json> <out.html> <syncISO>
// Reconciles posteriores ao v7: a página já tem qoverlay/qmeta. Só mescla o fetch no qmirror e regrava o qmeta.
const fs = require('fs');
const [,, LIVE, FETCH, OUT, AT] = process.argv;
const lines = fs.readFileSync(LIVE, 'utf8').split('\n');
const DEV = { '857575b1': 'Leandro', '409661f3': 'Marcos', 'f403707d': 'João Pedro', 'b90f482e': 'Joao Lucas', '34a15ef4': 'João Vinícius' };

const qi = lines.findIndex(l => l.startsWith('<script type="application/json" id="qmirror">'));
const mi = lines.findIndex(l => l.startsWith('<script type="application/json" id="qmeta">'));
if (qi < 0 || mi < 0) throw new Error('qmirror/qmeta não encontrado');
const q = JSON.parse(lines[qi].replace(/^<script[^>]*>/, '').replace(/<\/script>$/, ''));
const f = JSON.parse(fs.readFileSync(FETCH, 'utf8'));
for (const [k, t] of Object.entries(f)) {
  const m = q[k] || {};
  const oldC = {}; (m.c || []).forEach(c => { if (c.a) oldC[c.dt] = c.a; });
  const oldH = {}; (m.h || []).forEach(x => { if (x.por) oldH[x.dt] = x.por; });
  (t.c || []).forEach(c => { if (!c.a && oldC[c.dt]) c.a = oldC[c.dt]; if (!c.a) c.a = 'Solicitante'; delete c.uid; if (!c.e) delete c.e; });
  (t.h || []).forEach(x => { if (!x.por && oldH[x.dt]) x.por = oldH[x.dt]; delete x.uid; });
  const dv = t.asg ? DEV[String(t.asg).slice(0, 8)] : null;
  q[k] = Object.assign(m, { t: t.t, s: t.s, d: t.d != null ? t.d : m.d, edd: t.edd || null, c: (t.c && t.c.length) ? t.c : (m.c || []), h: (t.h && t.h.length) ? t.h : (m.h || []) });
  if (t.res) q[k].res = t.res; else delete q[k].res;
  if (dv) q[k].dv = dv;
  if (t.sp != null) q[k].sp = t.sp;
}
lines[qi] = '<script type="application/json" id="qmirror">' + JSON.stringify(q).replace(/<\//g, '<\\/') + '</script>';
lines[mi] = '<script type="application/json" id="qmeta">' + JSON.stringify({ at: AT, janela: { de: '2026-10-01', ate: AT.slice(0, 10) } }) + '</script>';
fs.writeFileSync(OUT, lines.join('\n'));
console.log('ok', OUT, 'qmirror', Object.keys(q).length);
