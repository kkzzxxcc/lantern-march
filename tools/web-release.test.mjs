import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import {spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const project=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const scratch=path.join(project,'.tools','web-release-tests');
fs.mkdirSync(scratch,{recursive:true});
function fixture(t, changes={}) {
 const dir=fs.mkdtempSync(path.join(scratch,'case-'));
 t.after(()=>fs.rmSync(dir,{recursive:true,force:true}));
 const root=path.join(dir,'build','web');
 fs.mkdirSync(root,{recursive:true});
 const files={
  'index.html':'<html><head><meta name="viewport" content="initial-scale=1.0"><link href="index.manifest.json"></head><body><script src="index.js"></script><script>const config={"executable":"index","fileSizes":{"index.pck":4,"index.wasm":4}};</script></body></html>',
  'index.manifest.json':JSON.stringify({name:'Lantern March',icons:[{src:'index.icon.png',sizes:'192x192'}]}),
  'index.service.worker.js':'// Godot worker',
  'index.js':'engine', 'index.wasm':'wasm', 'index.pck':'data', 'index.icon.png':'icon',
  ...changes
 };
 for(const [name,bytes] of Object.entries(files)) fs.writeFileSync(path.join(root,name),bytes);
 const run=()=>spawnSync(process.execPath,[path.join(project,'tools','finalize-web.mjs')],{cwd:dir,encoding:'utf8'});
 return {root,run};
}
function build(t,changes) {
 const f=fixture(t,changes), result=f.run();
 assert.equal(result.status,0,result.stderr);
 return {...f,release:JSON.parse(fs.readFileSync(path.join(f.root,'release.json'),'utf8'))};
}
function worker(root,options={}) {
 const scope='https://example.test/game/';
 const listeners={}, deleted=[], requested=[], added=[];
 const current={match:async key=>key==='index.html'?'cached-shell':undefined,addAll:async assets=>{
  added.push(...assets);
  if(options.installFails) throw Error('asset unavailable');
 }};
 const caches={open:async()=>current,keys:async()=>options.keys||[],delete:async key=>{deleted.push(key);return true;}};
 const context=vm.createContext({self:{registration:{scope},location:{origin:'https://example.test'},addEventListener:(name,fn)=>listeners[name]=fn},caches,URL,encodeURIComponent,fetch:async req=>{requested.push(req);return 'network';}});
 vm.runInContext(fs.readFileSync(path.join(root,'service-worker.js'),'utf8'),context);
 return {listeners,deleted,requested,added,context};
}

test('all asset references exist and fresh export finalizes reproducibly',t=>{
 const a=build(t),b=build(t);
 assert.equal(a.release.version,b.release.version);
 for(const asset of a.release.assets) assert.ok(fs.existsSync(path.join(a.root,asset)),asset);
 const html=fs.readFileSync(path.join(a.root,'index.html'),'utf8');
 assert.ok(html.includes('viewport-fit=cover'));
 assert.ok(html.includes('"executable":"lm-'+a.release.version+'"'));
 const manifest=JSON.parse(fs.readFileSync(path.join(a.root,'manifest.webmanifest'),'utf8'));
 assert.ok(fs.existsSync(path.join(a.root,manifest.icons[0].src)));
 const before=fs.readFileSync(path.join(a.root,'index.html'),'utf8');
 assert.notEqual(a.run().status,0,'reject already-finalized output');
 assert.equal(fs.readFileSync(path.join(a.root,'index.html'),'utf8'),before);
});
test('Korean shell, offline page and manifest are included in hashed release',t=>{
 const f=build(t,{
  'index.html':'<html lang="en"><head></head><body>Your browser does not support JavaScript.<script>setStatusNotice(err.message);</script></body></html>',
  'index.offline.html':'<html lang="en"><title>You are offline</title><p>This application requires an Internet connection to run for the first time.</p><p>Press the button below to try reloading:</p><button>Reload</button></html>'
 });
 const html=fs.readFileSync(path.join(f.root,'index.html'),'utf8');
 assert.ok(html.includes('lang="ko"'));
 assert.ok(html.includes('자바스크립트'));
 assert.ok(!html.includes('setStatusNotice(err.message)'));
 const offline=fs.readFileSync(path.join(f.root,'lm-'+f.release.version+'.offline.html'),'utf8');
 assert.ok(offline.includes('다시 불러오기'));
 assert.ok(!offline.includes('You are offline'));
 const manifest=JSON.parse(fs.readFileSync(path.join(f.root,'manifest.webmanifest'),'utf8'));
 assert.equal(manifest.lang,'ko');
 assert.equal(manifest.name,'등불의 전선');
});
test('HTML, manifest and icon-only changes each produce a new release',t=>{
 const baseline=build(t).release.version;
 for(const changes of [
  {'index.html':'<html><head></head><body>New shell</body></html>'},
  {'index.manifest.json':JSON.stringify({name:'New title',icons:[]})},
  {'index.icon.png':'new-icon'}
 ]) assert.notEqual(build(t,changes).release.version,baseline);
});
test('malformed manifest is rejected before export files are renamed',t=>{
 const f=fixture(t,{'index.manifest.json':'{'});
 assert.notEqual(f.run().status,0);
 assert.ok(fs.existsSync(path.join(f.root,'index.js')));
});
test('activation deletes only obsolete caches belonging to its scope',async t=>{
 const f=build(t);
 const own='lantern-march-v2:'+encodeURIComponent('https://example.test/game/')+':';
 const old=own+'old', current=own+f.release.version;
 const foreign='lantern-march-v2:'+encodeURIComponent('https://example.test/other/')+':old';
 const w=worker(f.root,{keys:[old,current,foreign,'lantern-march-legacy','unrelated']});
 let done;
 w.listeners.activate({waitUntil:p=>done=p}); await done;
 assert.deepEqual(w.deleted,[old]);
});
test('failed asset download rejects installation; no forced worker activation',async t=>{
 const f=build(t),w=worker(f.root,{installFails:true});
 let done;
 w.listeners.install({waitUntil:p=>done=p});
 await assert.rejects(done,/asset unavailable/);
 assert.deepEqual(w.added,f.release.assets);
 // Any skipWaiting/clients.claim call would fail in this intentionally minimal host.
});
test('navigation keeps active release shell; foreign scope requests are untouched',async t=>{
 const f=build(t),w=worker(f.root);
 let response;
 w.listeners.fetch({request:{url:'https://example.test/game/index.html',method:'GET',mode:'navigate'},respondWith:p=>response=p});
 assert.equal(await response,'cached-shell');
 assert.equal(w.requested.length,0);
 for(const url of ['https://example.test/other/file','https://elsewhere.test/game/']) {
  w.listeners.fetch({request:{url,method:'GET',mode:'navigate'},respondWith:()=>assert.fail('foreign request intercepted')});
 }
 w.listeners.fetch({request:{url:'https://example.test/game/save',method:'POST'},respondWith:()=>assert.fail('POST intercepted')});
});
