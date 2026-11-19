// Diagnóstico (só contagens): por que há tanto "sem resposta"?
import fs from "node:fs"; import path from "node:path"; import readline from "node:readline";
const B="dados"; const rl=readline.createInterface({input:fs.createReadStream(path.join(B,"metricas","protocolos.jsonl"))});
const g={}; const cortesia=/^(ok+|obrigad[oa]|obg|valeu|vlw|blz|beleza|t[aá] bom|tudo bem|certo|perfeito|combinado|entendi|show|top|👍|🙏|bom dia|boa tarde|boa noite|amem|am[eé]m|de nada|tchau|at[eé] mais)[\s!.,👍🙏😊❤️]*$/i;
for await (const l of rl){ if(!l) continue; const p=JSON.parse(l); if(!p.met.turnos.length) continue;
  const k=p.rec+" | "+p.fonte; const s=g[k]??={com_turno:0,sem:0,sem_unico_turno:0,sem_apos_resposta:0,depois_tem_bot_sistema:0,depois_so_eventos:0,ultima_cortesia:0,ultima_midia:0,gap_ate_fim_h:[],sem_broadcast:0,sem_tipo:{},amostra:0};
  s.com_turno++; if(!p.met.semResposta) continue; s.sem++; s.sem_tipo[p.tipo]=(s.sem_tipo[p.tipo]||0)+1; if(p.broadcast) s.sem_broadcast++;
  if(p.met.turnos.length===1) s.sem_unico_turno++; else s.sem_apos_resposta++;
  if(s.amostra>=4000) continue; s.amostra++;
  const j=JSON.parse(fs.readFileSync(path.join(B,"protocolos",p.id+".json"),"utf8")); const ms=j.mensagens; const ini=new Date(p.met.turnos.at(-1).ini).toISOString().replace("Z","-03:00");
  const i0=ms.findIndex(m=>m.ts===ini&&m.autor==="cliente"); const dep=ms.slice(i0<0?0:i0); const cli=dep.filter(m=>m.autor==="cliente"); const sis=dep.filter(m=>m.autor==="sistema");
  if(sis.some(m=>m.atendente==="Automação")) s.depois_tem_bot_sistema++; else s.depois_so_eventos++;
  const ult=cli.at(-1); if(ult){ if(cli.length===1&&cortesia.test((ult.texto||"").trim())) s.ultima_cortesia++; if(/^\[/.test(ult.texto||"")) s.ultima_midia++; }
  if(p.fim!=null) s.gap_ate_fim_h.push((p.fim-p.met.turnos.at(-1).ini)/3600e3);
}
const med=a=>{if(!a.length)return null;const s=[...a].sort((x,y)=>x-y);return +s[s.length>>1].toFixed(2)};
for(const k of Object.keys(g).sort()){const s=g[k]; s.gap_ate_fim_h_mediana=med(s.gap_ate_fim_h); s.gap_p25=s.gap_ate_fim_h.length?+[...s.gap_ate_fim_h].sort((x,y)=>x-y)[s.gap_ate_fim_h.length>>2].toFixed(2):null; delete s.gap_ate_fim_h; console.log(k, JSON.stringify(s));}
