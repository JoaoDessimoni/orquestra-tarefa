// Diagnóstico (só contagens): autoria das mensagens "out" por estágio (com/sem atendente atribuído), por fonte.
import fs from "node:fs";
const ler=n=>JSON.parse(fs.readFileSync("dados/brutos/"+n+".json","utf8"));
const dep=new Map(ler("ref_deptos").map(d=>[d.department_id,String(d.is_ia_dpto)==="1"]));
const w=s=>s?Date.parse(s):null;
const chats=new Map(); for(const f of ["chats_A","chats_B"]) for(const c of ler(f)) chats.set(c.chat_id,{rec:c.rec,est:(c.jornada||[]).map(j=>({d:j.d,a:j.a||null,t:w(j.t||j.q)})).filter(j=>j.t!=null).sort((x,y)=>x.t-y.t)});
const prot=new Map(); for(const f of ["chats_A","chats_B"]) for(const c of ler(f)) prot.set(c.rec+"|"+c.protocol,c.chat_id);
const g={};
const run=(f,rec)=>{for(const r of ler(f)){ if(r.direction!=="out") continue; const c=chats.get(r.chat_id)||chats.get(prot.get(rec+"|"+r.protocol)); if(!c) continue; const ts=w(r.mensagem_em); let s=null; for(const e of c.est){if(e.t<=ts+1000)s=e;else break}
  const est=!s?"sem_estagio":dep.get(s.d)?"depto_IA":s.a?"humano_atribuido":"fila_sem_agente";
  const mt=["text","hsm","audio","image","file"].includes(r.message_type)?r.message_type:"outro";
  const k=[rec,r.fonte,est,r.sender_kind,mt].join(" | "); g[k]=(g[k]||0)+1; }};
run("msgs_A","A"); for(const m of ["2026-08","2026-09","2026-10","2026-11"]) run("msgs_B_"+m,"B");
for(const k of Object.keys(g).sort()) if(g[k]>=150) console.log(String(g[k]).padStart(7),k);
