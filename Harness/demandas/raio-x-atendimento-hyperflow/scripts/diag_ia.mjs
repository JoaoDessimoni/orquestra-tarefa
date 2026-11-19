// Diagnóstico do tempo de resposta da IA (só contagens). Uso: node scripts/diag_ia.mjs [rotulo]
import fs from "node:fs";
const q=(a,p)=>{if(!a.length)return null;const s=[...a].sort((x,y)=>x-y);return +(s[Math.min(s.length-1,Math.floor(p*s.length))]*60).toFixed(1)};
const med=a=>{if(!a.length)return null;const s=[...a].sort((x,y)=>x-y),m=s.length>>1;return s.length%2?s[m]:(s[m-1]+s[m])/2};
const g={},tot={};
for(const l of fs.readFileSync("dados/metricas/protocolos.jsonl","utf8").split("\n")){if(!l)continue;const p=JSON.parse(l);
  const k=p.rec+" | "+p.fonte,o=g[k]??={ia:[],desc:0,prot:[],nMsgs:[],semTurno:0,n:0};o.n++;o.nMsgs.push(p.nMsgs);if(!p.met.turnos.length)o.semTurno++;
  for(const t of p.met.turnos)if(t.por==="ia"&&t.cor!=null){if(t.rap)o.desc++;else o.ia.push(t.cor)}
  if(p.met.respIA.cor!=null)o.prot.push(p.met.respIA.cor);
  const T=tot[p.rec]??={n:0,semTurno:0,sem:0,enc:0,red_com:0,red_cor:0,tipo:{},prot:[],comT:0};T.n++;T.tipo[p.tipo]=(T.tipo[p.tipo]||0)+1;
  if(!p.met.turnos.length)T.semTurno++;else{T.comT++;if(p.met.semResposta)T.sem++;if(p.met.faixaCom==="f60p")T.red_com++;if(p.met.faixaCor==="f60p")T.red_cor++}
  if(p.met.encerramento)T.enc++;if(p.met.respIA.cor!=null)T.prot.push(p.met.respIA.cor)}
const out={rotulo:process.argv[2]||"",por_fonte:{},por_recorte:{}};
for(const[k,o]of Object.entries(g))out.por_fonte[k]={protocolos:o.n,sem_turno:o.semTurno,mediana_msgs_por_conversa:med(o.nMsgs),turnos_ia_medidos:o.ia.length,turnos_ia_descartados:o.desc,turnos_ia_ate_2s:o.ia.filter(x=>x*60<=2).length,seg:{p25:q(o.ia,.25),mediana:q(o.ia,.5),p75:q(o.ia,.75),p90:q(o.ia,.9)}};
for(const[r,T]of Object.entries(tot)){const{prot,...x}=T;out.por_recorte[r]={...x,dashboard_resposta_ia_seg:med(prot)==null?null:+(med(prot)*60).toFixed(1),protocolos_com_resposta_ia:prot.length}}
console.log(JSON.stringify(out,null,1));
