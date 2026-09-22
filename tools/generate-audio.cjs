// Original compositions and synthesis for Lantern March. No samples or external melodies.
// Reproducible: node tools/generate-audio.cjs (Node built-ins only).
const fs = require('node:fs');
const rate = 22050, tau = Math.PI * 2;
const hz = n => 440 * 2 ** ((n - 69) / 12);
let seed = 0x1a47;
const noise = () => { seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0; return seed / 2147483648 - 1; };
function tone(out, at, duration, midi, gain, type='bell') {
 const start=Math.round(at*rate), count=Math.round(duration*rate), f=hz(midi);
 for(let i=0;i<count && start+i<out.length;i++) {
  const t=i/rate, x=i/count;
  const envelope=Math.min(1,t/.012)*Math.min(1,(duration-t)/.03)*Math.exp(-x*(type==='pad'?1:4));
  let sample;
  if(type==='drum') sample=Math.sin(tau*(65*t-35*t*t))*0.8+noise()*Math.exp(-t*35)*0.2;
  else if(type==='air') sample=noise()*.5+Math.sin(tau*f*t*(1-x*.55))*.5;
  else sample=Math.sin(tau*f*t)+Math.sin(tau*f*2*t)*.18+Math.sin(tau*f*3*t)*.05;
  out[start+i]+=sample*gain*envelope;
 }
}
function write(name,out) {
 const b=Buffer.alloc(44+out.length*2);
 b.write('RIFF');b.writeUInt32LE(b.length-8,4);b.write('WAVEfmt ',8);b.writeUInt32LE(16,16);
 b.writeUInt16LE(1,20);b.writeUInt16LE(1,22);b.writeUInt32LE(rate,24);b.writeUInt32LE(rate*2,28);
 b.writeUInt16LE(2,32);b.writeUInt16LE(16,34);b.write('data',36);b.writeUInt32LE(out.length*2,40);
 for(let i=0;i<out.length;i++) b.writeInt16LE(Math.round(Math.max(-.92,Math.min(.92,out[i]))*32767),44+i*2);
 fs.mkdirSync('assets/audio',{recursive:true});fs.writeFileSync('assets/audio/'+name+'.wav',b);
}
function phrase(name,notes,step,gain,type='bell') {
 const out=new Float64Array(Math.round((notes.length*step+.18)*rate));
 notes.forEach((n,i)=>tone(out,i*step,step+.15,n,gain,type));write(name,out);
}
phrase('click',[81],.05,.15);
phrase('summon',[60,67,72],.085,.25);
phrase('hit',[39],.07,.28,'drum');
phrase('ranged',[88,76],.07,.16,'air');
phrase('skill',[67,74,79,86],.09,.23);
phrase('heal',[72,76,79,84],.13,.19);
phrase('victory',[60,64,67,72,76,79,84],.19,.23);
phrase('defeat',[64,62,59,52],.31,.20);
// Eight bars, original C/F/Am/G progression; notes and backing differ by scene.
// Notes end at the buffer boundary; fade edges avoid loop discontinuities.
function music(name,bpm,battle) {
 const beat=60/bpm, seconds=32*beat, out=new Float64Array(Math.round(seconds*rate));
 const chords=[[48,52,55],[53,57,60],[45,48,52],[43,47,50]];
 const melody=battle?[72,67,74,76,79,76,74,67,72,76,81,79,76,74,71,67]:
 [72,76,79,74,72,69,76,74,72,67,69,76,74,71,67,62];
 for(let bar=0;bar<8;bar++) {
  const chord=chords[bar%4];
  chord.forEach(n=>tone(out,bar*4*beat,4*beat,n,.035,'pad'));
  for(let b=0;b<4;b++) {
   tone(out,(bar*4+b)*beat,beat*.9,chord[b%3]+12,.07);
   if(battle) tone(out,(bar*4+b)*beat,.16,36,b%2?.04:.10,'drum');
  }
  for(let j=0;j<2;j++) tone(out,(bar*4+j*2)*beat,beat*1.7,melody[bar*2+j],.105);
 }
 for(let i=0;i<out.length;i++) out[i]*=Math.min(1,i/(rate*.025),(out.length-1-i)/(rate*.04));
 write(name,out);
}
music('menu',88,false);
music('battle',124,true);
console.log('Generated 2 original BGM loops and 8 SFX.');
