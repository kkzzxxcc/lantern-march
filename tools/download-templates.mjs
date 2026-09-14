import fs from 'node:fs';
import zlib from 'node:zlib';
const url='https://github.com/godotengine/godot-builds/releases/download/4.6-stable/Godot_v4.6-stable_export_templates.tpz';
const head=await fetch(url,{method:'HEAD'}); if(!head.ok)throw Error(head.status);
const size=Number(head.headers.get('content-length'));
async function range(a,b){const r=await fetch(head.url,{headers:{Range:`bytes=${a}-${b}`}});if(r.status!==206)throw Error(`Range refused ${r.status}`);return Buffer.from(await r.arrayBuffer());}
const tail=await range(size-65536,size-1); const end=tail.lastIndexOf(Buffer.from([0x50,0x4b,0x05,0x06]));
const directory=await range(tail.readUInt32LE(end+16),tail.readUInt32LE(end+16)+tail.readUInt32LE(end+12)-1);
fs.mkdirSync('.tools/templates',{recursive:true});
for(let p=0;p<directory.length;){if(directory.readUInt32LE(p)!==0x02014b50)break;const n=directory.readUInt16LE(p+28),extra=directory.readUInt16LE(p+30),comment=directory.readUInt16LE(p+32);const name=directory.toString('utf8',p+46,p+46+n);if(/web_nothreads_(release|debug)\.zip$/.test(name)){const offset=directory.readUInt32LE(p+42),length=directory.readUInt32LE(p+20),method=directory.readUInt16LE(p+10);const local=await range(offset,offset+29);const start=offset+30+local.readUInt16LE(26)+local.readUInt16LE(28);const packed=await range(start,start+length-1);const bytes=method===8?zlib.inflateRawSync(packed):packed;const target='.tools/templates/'+name.split('/').pop();fs.writeFileSync(target,bytes);console.log(target,bytes.length);}p+=46+n+extra+comment;}
