import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';
const root=path.resolve('build/web');
// Include presentation and worker policy, not just executable/data. A metadata-only
// release must install a new cache too. Bump this when generated worker policy changes.
const digest=crypto.createHash('sha256').update('lantern-march-web-v2\0');
const originals=fs.readdirSync(root).filter(f=>f.startsWith('index.')&&!['index.html','index.service.worker.js','index.manifest.json'].includes(f)).sort();
const inputs=['index.html','index.manifest.json',...originals].sort();
for(const required of ['index.js','index.wasm','index.pck']) {
 if(!originals.includes(required)) throw Error('Fresh Godot Web export required: missing '+required);
}
// Parse and validate all inputs before mutating the export.
let html=fs.readFileSync(path.join(root,'index.html'),'utf8');
const manifest=JSON.parse(fs.readFileSync(path.join(root,'index.manifest.json'),'utf8'));
if(!Array.isArray(manifest.icons)) throw Error('Web manifest icons must be an array');
for(const f of inputs) {
 const bytes=fs.readFileSync(path.join(root,f));
 digest.update(f+'\0'+bytes.length+'\0').update(bytes);
}
const version=digest.digest('hex').slice(0,16), prefix='lm-'+version;
for(const f of originals) fs.renameSync(path.join(root,f),path.join(root,f.replace(/^index/,prefix)));
html=html.replaceAll('index.',prefix+'.').replace('"executable":"index"','"executable":"'+prefix+'"').replaceAll(prefix+'.service.worker.js','service-worker.js').replaceAll(prefix+'.manifest.json','manifest.webmanifest').replace('initial-scale=1.0','initial-scale=1.0, viewport-fit=cover');
html=html.replace('</head>','<meta name="theme-color" content="#0d252e">\n</head>');
html=html.replace('</body>',`<script>if('serviceWorker' in navigator) window.addEventListener('load',()=>navigator.serviceWorker.register('service-worker.js').catch(console.warn));</script></body>`);
fs.writeFileSync(path.join(root,'index.html'),html);
Object.assign(manifest,{id:'./',scope:'./',start_url:'./index.html',short_name:'Lantern March',theme_color:'#0d252e',background_color:'#0d252e'});
for(const icon of manifest.icons)icon.src=icon.src.replace(/^index/,prefix);
fs.writeFileSync(path.join(root,'manifest.webmanifest'),JSON.stringify(manifest,null,2));
for(const f of ['index.service.worker.js','index.manifest.json']) fs.unlinkSync(path.join(root,f));
const assets=['index.html','manifest.webmanifest',...originals.map(f=>f.replace(/^index/,prefix))];
fs.writeFileSync(path.join(root,'service-worker.js'),`// Atomic install; no skipWaiting: active sessions keep their release cache.
// CacheStorage is origin-wide, so only clean caches owned by this registration.
const CACHE_PREFIX='lantern-march-v2:'+encodeURIComponent(self.registration.scope)+':';
const CACHE=CACHE_PREFIX+'${version}';
const ASSETS=${JSON.stringify(assets)};
self.addEventListener('install',e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS))));
self.addEventListener('activate',e=>e.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith(CACHE_PREFIX)&&k!==CACHE).map(k=>caches.delete(k))))));
self.addEventListener('fetch',e=>{
 const url=new URL(e.request.url);
 if(e.request.method!=='GET'||url.origin!==self.location.origin||!url.href.startsWith(self.registration.scope))return;
 // Keep the shell and hashed assets on the active worker's release until all
 // clients close. Network-first navigation could expose a half-published build.
 if(e.request.mode==='navigate')e.respondWith(caches.open(CACHE).then(c=>c.match('index.html')).then(r=>r||fetch(e.request)));
 else e.respondWith(caches.open(CACHE).then(c=>c.match(e.request)).then(r=>r||fetch(e.request)));
});
`);
fs.writeFileSync(path.join(root,'release.json'),JSON.stringify({version,engine:'4.6-stable',build:'release',threaded:false,assets},null,2));
fs.writeFileSync(path.join(root,'.gdignore'),'Generated Web build.\n');
console.log('Versioned Web release '+version+'; atomic cache install, scoped cache ownership, hashed asset URLs.');
