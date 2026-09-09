'use strict';
const fs=require('fs'), path=require('path'), os=require('os');
const {chromium}=require('playwright-core');
function root(name){for(const base of require.resolve.paths(name)||[]){const candidate=path.join(base,name,'package.json');if(fs.existsSync(candidate))return path.dirname(candidate);}throw new Error('Missing '+name);}
(async()=>{
  const browser=await chromium.launch({headless:true,executablePath:process.env.CHROME_BIN||'/usr/bin/chromium',args:['--no-sandbox','--disable-dev-shm-usage']});
  const folder=fs.mkdtempSync(path.join(os.tmpdir(),'pdf-runtime-'));
  try{
    const page=await browser.newPage();
    await page.route('**/*',route=>route.abort());
    await page.setContent('<!doctype html><html><head><meta charset="utf-8"><style>@page{size:A4;margin:24mm}body{font:12pt "Noto Sans CJK SC",sans-serif}</style></head><body><h1>中文 PDF Runtime 123</h1><p id="math"></p><div class="mermaid">flowchart LR\n A[OCR] --> B[Review]</div></body></html>');
    await page.addScriptTag({path:path.join(root('katex'),'dist/katex.min.js')});
    await page.evaluate(()=>katex.render('E=mc^2',document.getElementById('math'),{throwOnError:true,trust:false}));
    await page.addScriptTag({path:path.join(root('mermaid'),'dist/mermaid.min.js')});
    await page.evaluate(async()=>{mermaid.initialize({startOnLoad:false,securityLevel:'strict',theme:'neutral'});await mermaid.run();});
    await page.evaluate(()=>{window.PagedConfig={auto:false};});
    await page.addScriptTag({path:path.join(root('pagedjs'),'dist/paged.polyfill.js')});
    const pages=await page.evaluate(async()=>{await document.fonts.ready;return (await window.PagedPolyfill.preview()).total;});
    if(pages!==1)throw new Error('Unexpected pagination: '+pages);
    const output=path.join(folder,'smoke.pdf');
    await page.pdf({path:output,preferCSSPageSize:true,printBackground:true,scale:1});
    if(fs.statSync(output).size<1000)throw new Error('Empty PDF');
    console.log('PDF design dependencies OK');
  }finally{await browser.close();fs.rmSync(folder,{recursive:true,force:true});}
})().catch(error=>{console.error(error.message);process.exitCode=1;});
