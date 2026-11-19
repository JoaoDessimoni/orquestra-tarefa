// Diagnóstico: intervalo entre a mensagem do cliente e a resposta seguinte da IA nas linhas brutas da Torre (só contagens).
import fs from "node:fs";
const P=s=>Date.parse(String(s).replace(" ","T").replace(/([+-]\d\d)$/,"$1:00"));
const q=(a,p)=>a.length?+( [...a].sort((x,y)=>x-y)[Math.min(a.length-1,Math.floor(p*a.length))]/1000).toFixed(1):null;
for(const rec of ["A","B"]){const rows=JSON.parse(fs.readFileSync(`dados/brutos/torre_ai_messages_${rec}.json`,"utf8"));const by=new Map();
  for(const r of rows){if(!by.has(r.protocol))by.set(r.protocol,[]);by.get(r.protocol).push({o:P(r.occurred_at),v:P(r.received_at),r:r.role,m:r.occurred_at.slice(0,7)})}
  const g={};let lag=[];
  for(const a of by.values()){a.sort((x,y)=>x.o-y.o);for(let i=1;i<a.length;i++)if(a[i].r==="assistant"&&a[i-1].r==="user"){const o=g[a[i].m]??={occ:[],rec:[]};o.occ.push(a[i].o-a[i-1].o);o.rec.push(a[i].v-a[i-1].v)}for(const x of a)lag.push(x.v-x.o)}
  console.log(rec,"atraso received−occurred (s) p50/p90:",q(lag,.5),q(lag,.9));
  for(const m of Object.keys(g).sort()){const o=g[m];console.log(" ",m,"pares",o.occ.length,"occurred: <3s",o.occ.filter(x=>x<3000).length,"p25/p50/p75",q(o.occ,.25),q(o.occ,.5),q(o.occ,.75),"| received: <3s",o.rec.filter(x=>x<3000).length,"p50",q(o.rec,.5))}}
