'use strict';
const fs=require('fs'), path=require('path'), os=require('os'), vm=require('vm');
const {chromium}=require('playwright-core');
function root(name){for(const base of require.resolve.paths(name)||[]){const candidate=path.join(base,name,'package.json');if(fs.existsSync(candidate))return path.dirname(candidate);}throw new Error('Missing '+name);}
(async()=>{
  const args=process.argv.slice(2);
  if(args.length>1 || (args.length===1 && args[0]!=='--dependencies-only'))
    throw new Error('Usage: design-smoke.cjs [--dependencies-only]');
  const executablePath=process.env.CHROME_BIN||'/usr/bin/chromium';
  fs.accessSync(executablePath,fs.constants.X_OK);
  const assets={
    katex:path.join(root('katex'),'dist/katex.min.js'),
    mermaid:path.join(root('mermaid'),'dist/mermaid.min.js'),
    pagedjs:path.join(root('pagedjs'),'dist/paged.polyfill.js'),
  };
  for(const filename of Object.values(assets)){
    const content=fs.readFileSync(filename,'utf8');
    if(!content.trim())throw new Error('Empty browser asset: '+filename);
    new vm.Script(content,{filename});
  }
  const katexCss=path.join(root('katex'),'dist/katex.min.css');
  if(!fs.statSync(katexCss).size || !fs.readdirSync(path.join(root('katex'),'dist/fonts')).some(name=>name.endsWith('.woff2')))
    throw new Error('Missing KaTeX CSS or fonts');
  if(!require('katex').renderToString('E=mc^2',{throwOnError:true,trust:false}).includes('katex'))
    throw new Error('KaTeX formula check failed');
  if(args[0]==='--dependencies-only'){
    console.log(JSON.stringify({dependencies:'passed',browser_rendering:'not_run',mode:'dependencies-only'}));
    return;
  }
  const browser=await chromium.launch({headless:true,executablePath,args:['--no-sandbox','--disable-dev-shm-usage','--disable-gpu']});
  const folder=fs.mkdtempSync(path.join(os.tmpdir(),'pdf-runtime-'));
  try{
    const page=await browser.newPage();
    await page.route('**/*',route=>route.abort());
    await page.setContent('<!doctype html><html><head><meta charset="utf-8"><style>@page{size:A4;margin:24mm}body{font:12pt "Noto Sans CJK SC",sans-serif}</style></head><body><h1>中文 PDF Runtime 123</h1><p id="math"></p><div class="mermaid">flowchart LR\n A[OCR] --> B[Review]</div></body></html>');
    await page.addScriptTag({path:assets.katex});
    await page.evaluate(()=>katex.render('E=mc^2',document.getElementById('math'),{throwOnError:true,trust:false}));
    await page.addScriptTag({path:assets.mermaid});
    await page.evaluate(async()=>{mermaid.initialize({startOnLoad:false,securityLevel:'strict',theme:'neutral'});await mermaid.run();});
    await page.evaluate(()=>{window.PagedConfig={auto:false};});
    await page.addScriptTag({path:assets.pagedjs});
    const pages=await page.evaluate(async()=>{await document.fonts.ready;return (await window.PagedPolyfill.preview()).total;});
    if(pages!==1)throw new Error('Unexpected pagination: '+pages);
    const output=path.join(folder,'smoke.pdf');
    await page.pdf({path:output,preferCSSPageSize:true,printBackground:true,scale:1});
    if(fs.statSync(output).size<1000)throw new Error('Empty PDF');
    console.log(JSON.stringify({dependencies:'passed',browser_rendering:'passed',page_count:pages}));
  }finally{await browser.close();fs.rmSync(folder,{recursive:true,force:true});}
})().catch(error=>{console.error(error.message);process.exitCode=1;});
