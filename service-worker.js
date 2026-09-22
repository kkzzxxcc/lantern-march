// Atomic install; no skipWaiting: active sessions keep their release cache.
// CacheStorage is origin-wide, so only clean caches owned by this registration.
const CACHE_PREFIX='lantern-march-v2:'+encodeURIComponent(self.registration.scope)+':';
const CACHE=CACHE_PREFIX+'5c1f6b23b9fdfbdc';
const ASSETS=["index.html","manifest.webmanifest","lm-5c1f6b23b9fdfbdc.144x144.png","lm-5c1f6b23b9fdfbdc.180x180.png","lm-5c1f6b23b9fdfbdc.512x512.png","lm-5c1f6b23b9fdfbdc.apple-touch-icon.png","lm-5c1f6b23b9fdfbdc.audio.position.worklet.js","lm-5c1f6b23b9fdfbdc.audio.worklet.js","lm-5c1f6b23b9fdfbdc.icon.png","lm-5c1f6b23b9fdfbdc.js","lm-5c1f6b23b9fdfbdc.offline.html","lm-5c1f6b23b9fdfbdc.pck","lm-5c1f6b23b9fdfbdc.png","lm-5c1f6b23b9fdfbdc.wasm"];
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
