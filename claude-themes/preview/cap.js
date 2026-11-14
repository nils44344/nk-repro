const puppeteer=require('puppeteer-core');const fs=require('fs');
const EXE=process.env.CHROME||'C:/Users/NIR/AppData/Local/ms-playwright/chromium_headless_shell-1223/chrome-headless-shell-win64/chrome-headless-shell.exe';
(async()=>{
 const mode=process.argv[2];const b=await puppeteer.launch({executablePath:EXE,args:['--no-sandbox','--font-render-hinting=none'],defaultViewport:{width:1080,height:1920,deviceScaleFactor:1}});
 const p=await b.newPage();await p.goto('file://'+require('path').resolve(__dirname,'index.html')+'');await p.evaluate(()=>document.fonts.ready);
 if(mode==='test'){for(const t of process.argv.slice(3).map(Number)){await p.evaluate(t=>render(t),t);await p.screenshot({path:`test-${t}.png`});}}
 else{const fps=24;const END=await p.evaluate(()=>END);const n=Math.round(END*fps);fs.mkdirSync('frames',{recursive:true});
  for(let i=0;i<n;i++){await p.evaluate(t=>render(t),i/fps);await p.screenshot({path:`frames/f${String(i).padStart(4,'0')}.jpg`,type:'jpeg',quality:92});}
  console.log('frames',n);}
 await b.close();
})();
