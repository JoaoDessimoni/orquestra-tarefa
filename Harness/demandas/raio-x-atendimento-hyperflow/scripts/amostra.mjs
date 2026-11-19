// Etapa 4 — sorteio estratificado da amostra do avaliador (spec 04 §7). Seed fixa 20261119. Só contagens na saída.
import fs from "node:fs"; import path from "node:path";
const SEED=20261119, TETO_RED=800, POR_AT=30, MIN_AT=10, ALVO=1500;
function rng(seed){return function(){seed|=0;seed=seed+0x6D2B79F5|0;let t=Math.imul(seed^seed>>>15,1|seed);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
const R=rng(SEED); const shuf=a=>{a=[...a];for(let i=a.length-1;i>0;i--){const j=Math.floor(R()*(i+1));[a[i],a[j]]=[a[j],a[i]]}return a};
const P=fs.readFileSync("dados/metricas/protocolos.jsonl","utf8").split("\n").filter(Boolean).map(l=>JSON.parse(l)).sort((a,b)=>a.id<b.id?-1:1);
const prop=(items,key,n)=>{ if(items.length<=n) return [...items]; const g=new Map(); for(const x of items){const k=key(x); if(!g.has(k)) g.set(k,[]); g.get(k).push(x)}
  const out=[], resto=[]; for(const k of [...g.keys()].sort()){const arr=shuf(g.get(k)), q=Math.floor(n*arr.length/items.length); out.push(...arr.slice(0,q)); resto.push(...arr.slice(q))}
  return out.concat(shuf(resto).slice(0,n-out.length)); };
const res={seed:SEED,parametros:{TETO_RED,POR_AT,MIN_AT,ALVO},gerado_em:new Date().toISOString(),recortes:{}}; const lista=[]; const fx={};
for(const rec of ["A","B"]){
  const todos=P.filter(p=>p.rec===rec), E=todos.filter(p=>p.met.turnos.length>0);
  for(const p of E){const k=rec+" | "+p.fonte; const s=fx[k]??={n:0}; s.n++; s[p.met.faixaCom]=(s[p.met.faixaCom]||0)+1;}
  const pref=p=>rec==="B"?(p.fonte==="BQ completa"?0:1):0;   // B: prioriza conversa completa (viés declarado)
  const pool=E.filter(p=>pref(p)===0).length>=ALVO?E.filter(p=>pref(p)===0):E;
  const isRed=p=>p.met.semResposta||p.met.faixaCom==="f60p";
  const sel=new Map(); const put=(p,e)=>{if(!sel.has(p.id)) sel.set(p.id,{id:p.id,rec,estrato:e,fonte:p.fonte,red:isRed(p)})};
  const reds=pool.filter(isRed); for(const p of prop(reds,p=>p.semana,TETO_RED)) put(p,"a_red_flag_sem_resposta");
  const porAt=new Map(); for(const p of E) if(p.atId&&p.tipo!=="so_ia"){ if(!porAt.has(p.atId)) porAt.set(p.atId,[]); porAt.get(p.atId).push(p) }
  let nAt=0; for(const k of [...porAt.keys()].sort()){ const arr=porAt.get(k); if(arr.length<MIN_AT) continue; nAt++; const ord=shuf(arr).sort((x,y)=>pref(x)-pref(y)); let c=ord.filter(p=>sel.has(p.id)).length; for(const p of ord){ if(c>=POR_AT) break; if(!sel.has(p.id)){put(p,"b_por_atendente"); c++} } }
  const falta=Math.max(0,ALVO-sel.size); const rest=pool.filter(p=>!sel.has(p.id)); for(const p of prop(rest,p=>p.semana+"|"+p.depto+"|"+p.tipo,falta)) put(p,"c_proporcional");
  const S=[...sel.values()]; const Nred=E.filter(isRed).length, Nok=E.length-Nred, nred=S.filter(x=>x.red).length, nok=S.length-nred;
  for(const x of S){ x.peso=+(x.red?Nred/nred:Nok/Math.max(1,nok)).toFixed(4); lista.push(x); }
  let bytes=0,msgs=0; for(const x of S){ const f=path.join("dados/protocolos",x.id+".json"); bytes+=fs.statSync(f).size; }
  const idx=new Map(E.map(p=>[p.id,p])); msgs=S.reduce((s,x)=>s+idx.get(x.id).nMsgs,0);
  res.recortes[rec]={universo:todos.length,elegiveis:E.length,elegiveis_red_sem:Nred,atendentes_com_10mais:nAt,amostra:S.length,
    por_estrato:S.reduce((o,x)=>(o[x.estrato]=(o[x.estrato]||0)+1,o),{}),por_fonte:S.reduce((o,x)=>(o[x.fonte]=(o[x.fonte]||0)+1,o),{}),
    msgs_media:+(msgs/S.length).toFixed(1),bytes_total:bytes,tokens_entrada_aprox:Math.round(bytes/3.3),peso_red:+(Nred/nred).toFixed(2),peso_demais:+(Nok/Math.max(1,nok)).toFixed(2)};
}
fs.mkdirSync("dados/amostra",{recursive:true}); fs.writeFileSync("dados/amostra/amostra.json",JSON.stringify({...res,lista}));
console.log(JSON.stringify(res.recortes,null,1)); console.log("FAIXAS (relógio comercial) por fonte, só protocolos com turno:"); for(const k of Object.keys(fx).sort()) console.log(k,JSON.stringify(fx[k]));
