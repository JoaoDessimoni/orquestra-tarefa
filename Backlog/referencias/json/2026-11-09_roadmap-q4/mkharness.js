const fs=require('fs'),path=require('path');
const [src,dir,hash]=process.argv.slice(2);
const page=fs.readFileSync(src,'utf8');
// Uso: node mkharness.js <pagina.html> <pasta-de-saida> [painel|cronograma|gantt|quadro|demanda-<id>]
// Gera h_<visao>.html com um window.claude falso (db em memória) para testar a página no navegador local.
const SEED=__dirname;
const dem=fs.readFileSync(path.join(SEED,'demandas.seed.json'),'utf8');
const cfg=fs.readFileSync(path.join(SEED,'config.json'),'utf8');
const fake=`<script>
window.__D={demandas:${dem},config:${cfg}};
(function(){const snap=(d,id)=>({id,exists:!!d,data:()=>d,metadata:{fromCache:false,hasPendingWrites:false}});
const coll=(p)=>({where(){return this},orderBy(){return this},limit(){return this},onSnapshot(n){setTimeout(()=>n({docs:[],size:0,empty:true,docChanges:()=>[],metadata:{fromCache:false}}),10);return()=>{}},doc(id){return doc(p+'/'+id)},add(){return Promise.resolve()}});
const doc=(p)=>({onSnapshot(n){const k=p.split('/')[1];setTimeout(()=>n(snap(window.__D[k],k)),10);return()=>{}},set(){return Promise.resolve()},update(){return Promise.resolve()},get(){}});
const db={doc,collection:coll};
const user={me:async()=>({id:'u1',name:'João Vinícius',avatarUrl:'data:image/gif;base64,R0lGODlhAQABAAAAACw=',color:'#1A1AFF',isOwner:true,canEdit:true}),canEdit:async()=>true,can:async()=>true,profiles:async(ids)=>Object.fromEntries(ids.map(i=>[i,{id:i,name:'João'}]))};
window.claude={use:async n=>n==='db'?db:n==='user'?user:null};
var H=${JSON.stringify(hash||'')};if(H==='gantt'){try{localStorage.setItem('rq4_cron','"gantt"')}catch(e){}H='cronograma'}else if(H==='cronograma'){try{localStorage.setItem('rq4_cron','"calendario"')}catch(e){}}if(H)location.hash=H;})();
</script>`;
const out=`<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><style>body{margin:0}[hidden]{display:none!important}</style></head><body>${fake}${page}</body></html>`;
fs.writeFileSync(path.join(dir,'h_'+(hash||'painel')+'.html'),out);
