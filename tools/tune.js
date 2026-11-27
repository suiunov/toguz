const E=require('./engine');const seed=+process.argv[2]||1,iters=+process.argv[3]||80;
let r=seed*99991;const rnd=()=>{r=(r*16807)%2147483647;return r/2147483647};
const gauss=()=>{let u=rnd()||1e-9,v=rnd();return Math.sqrt(-2*Math.log(u))*Math.cos(2*Math.PI*v)};
let champ=E.W0.slice(),acc=0;
for(let it=0;it<iters;it++){
  const cand=champ.map((w,i)=>i===0?1:Math.max(0,w*Math.exp(gauss()*.3)+(rnd()<.15?gauss()*.1:0)));
  const sc=E.match({depth:4,W:cand,tt:true},{depth:4,W:champ,tt:true},50,seed*1000+it*131,2+Math.floor(rnd()*4));
  if(sc>0.56){const conf=E.match({depth:4,W:cand,tt:true},{depth:4,W:champ,tt:true},50,seed*5000+it*977,3);
    if((sc+conf)/2>0.55){champ=cand;acc++;console.log(`it ${it} ACCEPT ${sc.toFixed(2)}/${conf.toFixed(2)} W=[${champ.map(x=>x.toFixed(3)).join(',')}]`)}}
  if(it%10===9)console.log(`it ${it} vsW0=${E.match({depth:4,W:champ,tt:true},{depth:4,W:E.W0,tt:true},40,777).toFixed(3)}`)}
console.log('FINAL',JSON.stringify(champ.map(x=>+x.toFixed(4))));
