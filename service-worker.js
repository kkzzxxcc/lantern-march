// Atomic install; no skipWaiting: active sessions keep their release cache.
// CacheStorage is origin-wide, so only clean caches owned by this registration.
const CACHE_PREFIX='lantern-march-v2:'+encodeURIComponent(self.registration.scope)+':';
const CACHE=CACHE_PREFIX+'0d67ff167e3ab7dd';
const ASSETS=["index.html","manifest.webmanifest","lm-0d67ff167e3ab7dd.144x144.png","lm-0d67ff167e3ab7dd.180x180.png","lm-0d67ff167e3ab7dd.512x512.png","lm-0d67ff167e3ab7dd.apple-touch-icon.png","lm-0d67ff167e3ab7dd.audio.position.worklet.js","lm-0d67ff167e3ab7dd.audio.worklet.js","lm-0d67ff167e3ab7dd.icon.png","lm-0d67ff167e3ab7dd.js","lm-0d67ff167e3ab7dd.offline.html","lm-0d67ff167e3ab7dd.pck","lm-0d67ff167e3ab7dd.png","lm-0d67ff167e3ab7dd.wasm"];
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
