
async function openZip(path){const b=await readFileBinary(path);const buf=await b.arrayBuffer();const u=new Uint8Array(buf),dv=new DataView(buf);
let e=u.length-22;while(dv.getUint32(e,true)!==0x06054b50)e--;const n=dv.getUint16(e+10,true);let p=dv.getUint32(e+16,true);const ents=[],idx={};
for(let i=0;i<n;i++){const o={m:dv.getUint16(p+10,true),tm:u.slice(p+12,p+16),crc:dv.getUint32(p+16,true),cs:dv.getUint32(p+20,true),us:dv.getUint32(p+24,true),nl:dv.getUint16(p+28,true),xl:dv.getUint16(p+30,true),cl:dv.getUint16(p+32,true),off:dv.getUint32(p+42,true)};o.name=new TextDecoder().decode(u.slice(p+46,p+46+o.nl));const lnl=dv.getUint16(o.off+26,true),lxl=dv.getUint16(o.off+28,true);o.data=u.slice(o.off+30+lnl+lxl,o.off+30+lnl+lxl+o.cs);ents.push(o);idx[o.name]=o;p+=46+o.nl+o.xl+o.cl;}
const dec=new TextDecoder();
const raw=async(name)=>{const o=idx[name];if(o.m===0)return o.data;return new Uint8Array(await new Response(new Blob([o.data]).stream().pipeThrough(new DecompressionStream('deflate-raw'))).arrayBuffer());};
return {ents,idx,raw,get:async n=>dec.decode(await raw(n))};}
async function saveZip(z,mods,outPath,binMods){
const enc=new TextEncoder();const T=new Uint32Array(256);for(let i=0;i<256;i++){let c=i;for(let k=0;k<8;k++)c=c&1?0xEDB88320^(c>>>1):c>>>1;T[i]=c>>>0;}
const crc32=d=>{let c=0xFFFFFFFF;for(let i=0;i<d.length;i++)c=T[(c^d[i])&255]^(c>>>8);return (c^0xFFFFFFFF)>>>0;};
const w16=(a,v)=>a.push(v&255,(v>>8)&255),w32=(a,v)=>a.push(v&255,(v>>>8)&255,(v>>>16)&255,(v>>>24)&255);
const all=z.ents.map(o=>({name:o.name,m:o.m,crc:o.crc,cs:o.cs,us:o.us,data:o.data,tm:o.tm}));
const items=Object.entries(mods).map(([k,v])=>[k,typeof v==='string'?enc.encode(v):v]);
for(const [k,raw] of items){const c=new Uint8Array(await new Response(new Blob([raw]).stream().pipeThrough(new CompressionStream('deflate-raw'))).arrayBuffer());const ex=all.find(a=>a.name===k);const rec={name:k,m:8,crc:crc32(raw),cs:c.length,us:raw.length,data:c,tm:ex?ex.tm:new Uint8Array([0,0,33,0])};if(ex)Object.assign(ex,rec);else all.push(rec);}
const parts=[],cds=[];let offset=0;
for(const a of all){const nm=enc.encode(a.name);const h=[];w32(h,0x04034b50);w16(h,20);w16(h,0);w16(h,a.m);h.push(...a.tm);w32(h,a.crc);w32(h,a.cs);w32(h,a.us);w16(h,nm.length);w16(h,0);parts.push(new Uint8Array(h),nm,a.data);
const c=[];w32(c,0x02014b50);w16(c,20);w16(c,20);w16(c,0);w16(c,a.m);c.push(...a.tm);w32(c,a.crc);w32(c,a.cs);w32(c,a.us);w16(c,nm.length);w16(c,0);w16(c,0);w16(c,0);w16(c,0);w32(c,0);w32(c,offset);cds.push(new Uint8Array(c),nm);offset+=h.length+nm.length+a.data.length;}
const cdSize=cds.reduce((s,x)=>s+x.length,0);const eo=[];w32(eo,0x06054b50);w16(eo,0);w16(eo,0);w16(eo,all.length);w16(eo,all.length);w32(eo,cdSize);w32(eo,offset);w16(eo,0);
await saveFile(outPath,new Blob([...parts,...cds,new Uint8Array(eo)]));}
