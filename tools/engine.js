// Toguz Korgool engine: rules + new evaluation + search with transposition table.
// Same rules as the game (apply/legal copied from index.html).
const clone=s=>({b:s.b.slice(),k:s.k.slice(),t:s.t.slice(),turn:s.turn,over:s.over});
function legal(s){const o=s.turn*9,r=[];for(let i=o;i<o+9;i++)if(s.b[i]>0)r.push(i);return r}
function drop(s,pos){if(s.t[0]===pos)s.k[0]++;else if(s.t[1]===pos)s.k[1]++;else s.b[pos]++}
function apply(s,i,frames){
  const p=s.turn,n=s.b[i];s.b[i]=0;let pos=i,ev=null;
  const snap=q=>frames&&frames.push({s:clone(s),q});
  if(n===1){pos=(i+1)%18;drop(s,pos);snap(pos)}
  else{drop(s,i);snap(i);for(let j=1;j<n;j++){pos=(pos+1)%18;drop(s,pos);snap(pos)}}
  const side=pos>=9?1:0;
  if(side!==p&&s.t[0]!==pos&&s.t[1]!==pos){
    const c=s.b[pos];
    if(c%2===0){s.k[p]+=c;s.b[pos]=0;ev={type:'cap',n:c}}
    else if(c===3&&s.t[p]<0&&pos%9!==8&&!(s.t[1-p]>=0&&s.t[1-p]%9===pos%9)){
      s.t[p]=pos;s.k[p]+=3;s.b[pos]=0;ev={type:'tuz',h:pos%9+1}}
  }
  s.turn=1-p;
  if(s.k[p]>81)s.over={w:p};
  else if(legal(s).length===0){
    const o=p*9;for(let j=o;j<o+9;j++){s.k[p]+=s.b[j];s.b[j]=0}
    s.over={w:s.k[0]>s.k[1]?0:s.k[1]>s.k[0]?1:-1};
  }
  snap(pos);
  return ev;
}

// ---- old evaluation (what the game uses today) ----
function evalOld(s,me){return s.k[me]-s.k[1-me]+(s.t[me]>=0?8:0)-(s.t[1-me]>=0?8:0)}

// ---- new evaluation: weighted features ----
// best stones side X could capture with one move right now (cheap estimate)
function threat(s,X){let best=0;const o=X*9;
  for(let i=o;i<o+9;i++){const n=s.b[i];if(!n)continue;
    const land=n===1?(i+1)%18:(i+n-1)%18;if((land>=9?1:0)===X||s.t[0]===land||s.t[1]===land)continue;
    const c=s.b[land]+1+Math.floor((n-1)/18);
    if(c%2===0){if(c>best)best=c}
    else if(c===3&&s.t[X]<0&&land%9!==8&&!(s.t[1-X]>=0&&s.t[1-X]%9===land%9)){if(6>best)best=6}}
  return best}
const W0=[1,14,0.04,0.35,0.55,0.35];
function threatSum(s,X){let sum=0;const o=X*9;
  for(let i=o;i<o+9;i++){const n=s.b[i];if(!n)continue;
    const land=n===1?(i+1)%18:(i+n-1)%18;if((land>=9?1:0)===X||s.t[0]===land||s.t[1]===land)continue;
    const c=s.b[land]+1+Math.floor((n-1)/18);if(c%2===0)sum+=c}
  return sum}
function evalNew(s,me,W){const op=1-me,b=s.b;let bm=0,bo=0,mm=0,mo=0;
  for(let i=0;i<9;i++){const x=b[me*9+i],y=b[op*9+i];bm+=x;bo+=y;if(x)mm++;if(y)mo++}
  const left=(bm+bo)/162,tz=((s.t[me]>=0)-(s.t[op]>=0))*left;
  const mover=s.turn,tMove=threat(s,mover),tWait=threat(s,1-mover),sg=mover===me?1:-1;
  let v=W[0]*(s.k[me]-s.k[op])+W[1]*tz+W[2]*(bm-bo)+W[3]*(mm-mo)+sg*(W[4]*tMove-W[5]*tWait);
  if(W.length>6){let hm=0,ho=0;for(let i=0;i<9;i++){if(b[me*9+i]>hm)hm=b[me*9+i];if(b[op*9+i]>ho)ho=b[op*9+i]}
    v+=sg*(W[6]*threatSum(s,mover)-W[7]*threatSum(s,1-mover))+W[8]*(hm-ho)}
  return v}

// ---- search ----
// opts: {depth} fixed depth, or {time} ms with iterative deepening; W weights (null = old eval); tt true/false
function search(s,opts){
  const me=s.turn,W=opts.W,ev=W?(x=>evalNew(x,me,W)):(x=>evalOld(x,me));
  const end=opts.time?Date.now()+opts.time:Infinity,STOP={};let nodes=0;
  const TT=opts.tt?new Map():null;
  const key=x=>x.b.join(',')+'|'+x.k[0]+'|'+x.t[0]+'|'+x.t[1]+'|'+x.turn;
  // order: captures first by immediate gain, then TT move
  function ordered(x,ttm){const ms=legal(x);if(ms.length<2)return ms;
    const sc=ms.map(m=>{const n=x.b[m],land=n===1?(m+1)%18:(m+n-1)%18;let v=0;
      if((land>=9?1:0)!==x.turn&&x.t[0]!==land&&x.t[1]!==land){const c=x.b[land]+1;if(c%2===0)v=c;else if(c===3)v=4}
      if(m===ttm)v+=1000;return [m,v]});
    sc.sort((a,b)=>b[1]-a[1]);return sc.map(z=>z[0])}
  function sr(x,d,a,bt){if(opts.time&&(++nodes&1023)===0&&Date.now()>end)throw STOP;
    if(x.over){const w=x.over.w;return w===me?1e5+d:w<0?0:-1e5-d}
    if(d===0)return ev(x);
    let k=null,ttm=-1;
    if(TT){k=key(x);const e=TT.get(k);if(e){if(e.d>=d){if(e.f===0)return e.v;if(e.f===1&&e.v>=bt)return e.v;if(e.f===2&&e.v<=a)return e.v}ttm=e.m}}
    const a0=a,b0=bt,max=x.turn===me;let v=max?-1e9:1e9,bm=-1;
    for(const m of ordered(x,ttm)){const c=clone(x);apply(c,m);const y=sr(c,d-1,a,bt);
      if(max){if(y>v){v=y;bm=m}if(v>a)a=v}else{if(y<v){v=y;bm=m}if(v<bt)bt=v}if(a>=bt)break}
    if(TT){const f=v<=a0?2:v>=b0?1:0;TT.set(k,{d,v,f,m:bm});if(TT.size>400000)TT.clear()}
    return v}
  const root=legal(s);let best=root[0];if(root.length===1)return best;
  const maxD=opts.depth||40;let order=ordered(s,-1);
  for(let d=opts.time?2:maxD;d<=maxD;d++){const sc=[];let a=-1e9,bm=order[0];
    try{for(const m of order){const c=clone(s);apply(c,m);const v=sr(c,d-1,a,1e9);sc.push([m,v]);if(v>a){a=v;bm=m}}}
    catch(e){if(e===STOP)break;throw e}
    best=bm;order=sc.sort((x,y)=>y[1]-x[1]).map(z=>z[0]);
    if(!opts.time)break;if(a>=1e5||Date.now()>end-opts.time*.55)break}
  return best}

// ---- matches ----
function rng(seed){return()=>{seed=(seed*16807)%2147483647;return seed/2147483647}}
function opening(seed,plies){const r=rng(seed);let s={b:Array(18).fill(9),k:[0,0],t:[-1,-1],turn:0,over:null};
  for(let i=0;i<plies&&!s.over;i++){const ms=legal(s);apply(s,ms[Math.floor(r()*ms.length)])}return s}
function play(start,pA,pB,aSide){let s=clone(start),n=0;
  while(!s.over&&n<300){const P=s.turn===aSide?pA:pB;apply(s,search(s,P));n++}
  if(!s.over)return {r:.5,k:s.k};const w=s.over.w;return {r:w<0?.5:w===aSide?1:0,k:s.k}}
// play pairs of games (both colours) from random openings; returns A's score 0..1
function match(pA,pB,pairs,seed0=1,plies=2){let sc=0,g=0;
  for(let i=0;i<pairs;i++){const st=opening(seed0+i*7919,plies);
    sc+=play(st,pA,pB,0).r;sc+=play(st,pA,pB,1).r;g+=2}
  return sc/g}
module.exports={apply,legal,clone,evalOld,evalNew,threat,search,match,play,opening,W0};
