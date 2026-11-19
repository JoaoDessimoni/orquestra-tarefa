// Diagnóstico (só contagens): texto repetido em muitos chats = automação? Valida contra sender_kind oficial (chat_history).
import fs from "node:fs";
const ler=n=>JSON.parse(fs.readFileSync("dados/brutos/"+n+".json","utf8"));
const dep=new Map(ler("ref_deptos").map(d=>[d.department_id,String(d.is_ia_dpto)==="1"]));
const w=s=>s?Date.parse(s):null; const norm=s=>(s||"").toLowerCase().replace(/\d+/g,"#").replace(/\s+/g," ").trim().slice(0,160);
const chats=new Map(), prot=new Map();
for(const f of ["chats_A","chats_B"]) for(const c of ler(f)){ chats.set(c.chat_id,{rec:c.rec,protocol:c.protocol,est:(c.jornada||[]).map(j=>({d:j.d,a:j.a||null,t:w(j.t||j.q)})).filter(j=>j.t!=null).sort((x,y)=>x.t-y.t)}); prot.set(c.rec+"|"+c.protocol,c.chat_id); }
const ap=new Map(); for(const a of ler("ai_protocols")){const k=a.rec+"|"+a.protocol; if(!ap.has(k)) ap.set(k,{ini:w(a.started_at),tr:w(a.transferred_at),fim:w(a.finalized_at)});}
const rows=[]; const freq={A:new Map(),B:new Map()};
const run=(f,rec)=>{for(const r of ler(f)){ if(r.direction!=="out"||!r.texto||r.message_type==="hsm") continue; const id=chats.has(r.chat_id)?r.chat_id:prot.get(rec+"|"+r.protocol); const c=chats.get(id); if(!c) continue;
  const n=norm(r.texto); let s=freq[rec].get(n); if(!s) freq[rec].set(n,s=new Set()); s.add(id);
  const ts=w(r.mensagem_em); let e=null; for(const x of c.est){if(x.t<=ts+1000)e=x;else break}
  if(!e||dep.get(e.d)||!e.a) continue; const p=ap.get(rec+"|"+c.protocol); const apA=!!p&&p.ini!=null&&ts>=p.ini-60e3&&ts<=((p.tr??p.fim??Infinity)+60e3);
  rows.push([rec,r.fonte,r.sender_kind,n,apA]); }};
run("msgs_A","A"); for(const m of ["2026-08","2026-09","2026-10","2026-11"]) run("msgs_B_"+m,"B");
const g={}; for(const [rec,fonte,sk,n,apA] of rows){ const f=freq[rec].get(n).size; const b=f>=50?"50+":f>=20?"20-49":f>=10?"10-19":f>=5?"05-09":f>=2?"02-04":"01"; const k=[rec,fonte,sk,apA?"IA_ativa":"sem_IA",b].join(" | "); g[k]=(g[k]||0)+1; }
for(const k of Object.keys(g).sort()) console.log(String(g[k]).padStart(7),k);
