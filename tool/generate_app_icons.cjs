// 재생성: NODE_PATH에 기존 sharp 설치 경로를 지정한 뒤 node tool/generate_app_icons.cjs
// 앱 dependency를 추가하지 않는다. SVG가 유일한 geometry 원본이다.
// 검토용 PNG·목록은 Git 제외 build/icon-review에 저장한다.
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '..');
const brand = 'assets/branding';
const review = 'build/icon-review';
const sizes = [1024, 512, 256, 192, 128, 64, 48, 32, 16];
const inventory = [];
const cache = new Map();
const nodePositions = [[627,366], [315,833], [939,833]];
// 원·문자 core는 Android 66/108 원형 안전영역, Web 반지름 40% 안에 배치한다.
const androidScale = 0.57;
const webScale = 0.77;
const network = (color, width) => `<g id="network" fill="none" stroke="${color}" stroke-linecap="round"><use xlink:href="#connectors" stroke-width="40" mask="url(#outside-nodes)"/><use xlink:href="#rings" stroke-width="${width}"/></g>`;
const stripEffects = svg => svg.replace(/    <(?:radialGradient|linearGradient|filter)\b[\s\S]*?<\/(?:radialGradient|linearGradient|filter)>\n/g, '');
const replaceNetwork = (svg, replacement) => svg.replace(/    <g id="network"[\s\S]*?\n    <\/g>\n  <\/defs>/, `    ${replacement}\n  </defs>`);
const replaceArt = (svg, body) => svg.replace(/  <g id="artwork">[\s\S]*?<\/svg>/, `  <g id="artwork">${body}</g>\n</svg>`);
const foreground = svg => svg.replace(/  <rect id="canvas-background"[^>]*\/>\n/, '');
const fit = (svg, scale) => svg.replace('<g id="artwork">', `<g id="artwork" transform="translate(627 627) scale(${scale}) translate(-627 -627)">`);
const rounded = svg => svg.replace('</defs>', '<clipPath id="platform-corner"><rect x="39" y="35" width="1176" height="1180" rx="220"/></clipPath></defs><g clip-path="url(#platform-corner)">').replace('</svg>', '</g></svg>');
async function write(file, data) {
  await fs.mkdir(path.dirname(path.join(root,file)), {recursive:true});
  await fs.writeFile(path.join(root,file), data);
}
async function render(svg, size) {
  const key = `${size}:${svg}`;
  if (!cache.has(key)) {
    // 각 목표 크기를 SVG에서 직접 렌더링. 1024 raster 일괄 축소 금지.
    const sample = size < 256 ? size * 4 : size < 1024 ? size * 2 : size;
    const source = svg.replace('width="1254" height="1254"', `width="${sample}" height="${sample}"`);
    cache.set(key, sharp(Buffer.from(source)).resize(size,size).png().toBuffer());
  }
  return cache.get(key);
}
async function png(file, svg, size, variant, opaque=false) {
  let buffer = await render(svg,size);
  if(opaque) buffer = await sharp(buffer).removeAlpha().png().toBuffer();
  await write(file,buffer);
  inventory.push({file,size,variant,alpha:!opaque,bytes:buffer.length});
  return buffer;
}
(async () => {
  const master = await fs.readFile(path.join(root,brand,'reshet_icon_master.svg'),'utf8').then(s => s.replace(/\r\n/g, '\n'));
  let small = stripEffects(master);
  small = replaceNetwork(small, network('#62f4ff',32));
  small = small.replace('fill="url(#background)"','fill="#031631"');
  small = replaceArt(small, '<use xlink:href="#network"/><use xlink:href="#glyphs" fill="#b5ffff" stroke="#b5ffff" stroke-width="3" stroke-linejoin="round"/>');
  small = small.replace('Reshet 승인 아이콘 벡터 마스터','Reshet 작은 크기용 아이콘 — master에서 생성');
  let mono = replaceNetwork(stripEffects(master), network('#ffffff',30));
  mono = foreground(mono);
  mono = replaceArt(mono, '<use xlink:href="#network"/><use xlink:href="#glyphs" fill="#ffffff"/>');
  mono = mono.replace('Reshet 승인 아이콘 벡터 마스터','Reshet 단색 아이콘 — master에서 생성');
  await write(`${brand}/reshet_icon_small.svg`,small);
  await write(`${brand}/reshet_icon_monochrome.svg`,mono);
  const selected = n => n <=48 ? small:master;
  const icoFrames=[];
  for(const n of [16,32,48,64,128,256]) icoFrames.push({n,buffer:await render(rounded(selected(n)),n)});
  // PNG 압축 32-bit RGBA ICO. 각 frame은 독립 SVG 렌더링 결과다.
  let offset=6+16*icoFrames.length;
  const header=Buffer.alloc(offset); header.writeUInt16LE(1,2);header.writeUInt16LE(icoFrames.length,4);
  icoFrames.forEach(({n,buffer},i)=>{const j=6+i*16;header[j]=n===256?0:n;header[j+1]=header[j];header.writeUInt16LE(1,j+4);header.writeUInt16LE(32,j+6);header.writeUInt32LE(buffer.length,j+8);header.writeUInt32LE(offset,j+12);offset+=buffer.length;});
  await write('windows/runner/resources/app_icon.ico',Buffer.concat([header,...icoFrames.map(x=>x.buffer)]));
  for(const [density,n] of [['mdpi',48],['hdpi',72],['xhdpi',96],['xxhdpi',144],['xxxhdpi',192]]) {
    await png(`android/app/src/main/res/mipmap-${density}/ic_launcher.png`,rounded(selected(n)),n,n<=48?'small':'full');
  }
  // 108dp × 4 (xxxhdpi). nodpi로 두어 drawable bounds에 의해 일관되게 scale.
  await png('android/app/src/main/res/drawable-nodpi/reshet_icon_foreground.png',fit(foreground(master),androidScale),432,'adaptive foreground');
  await png('android/app/src/main/res/drawable-nodpi/reshet_icon_monochrome.png',fit(mono,androidScale),432,'monochrome adaptive');
  const adaptive = monochrome => `<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@drawable/reshet_icon_background"/>\n    <foreground android:drawable="@drawable/reshet_icon_foreground"/>${monochrome?'\n    <monochrome android:drawable="@drawable/reshet_icon_monochrome"/>':''}\n</adaptive-icon>\n`;
  await write('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',adaptive(false));
  await write('android/app/src/main/res/mipmap-anydpi-v33/ic_launcher.xml',adaptive(true));
  await write('android/app/src/main/res/drawable/reshet_icon_background.xml','<?xml version="1.0" encoding="utf-8"?>\n<shape xmlns:android="http://schemas.android.com/apk/res/android" android:shape="rectangle">\n    <solid android:color="#031b40"/>\n</shape>\n');
  for(const platform of ['ios','macos']) {
    const dir=`${platform}/Runner/Assets.xcassets/AppIcon.appiconset`;
    const catalog=JSON.parse(await fs.readFile(path.join(root,dir,'Contents.json'),'utf8'));
    const seen=new Set();
    for(const entry of catalog.images) {
      if(seen.has(entry.filename)) continue;
      seen.add(entry.filename);
      const n=Number(entry.size.split('x')[0])*Number(entry.scale.replace('x',''));
      await png(`${dir}/${entry.filename}`,platform==='macos'?rounded(selected(n)):selected(n),n,n<=48?'small':'full',platform==='ios');
    }
  }
  for(const n of [16,32,48,64,128,256,512]) await png(`${brand}/linux/reshet_${n}.png`,rounded(selected(n)),n,n<=48?'small':'full');
  await png('web/favicon.png',rounded(small),16,'small');
  for(const n of [192,512]) {
    await png(`web/icons/Icon-${n}.png`,master,n,'full',true);
    await png(`web/icons/Icon-maskable-${n}.png`,fit(master,webScale),n,'maskable',true);
  }
  for(const n of sizes) {
    await png(`${review}/full-${n}.png`,master,n,'full');
    await png(`${review}/small-${n}.png`,small,n,'small');
  }
  await png(`${review}/monochrome-512.png`,mono,512,'monochrome');
  await png(`${review}/desktop-1024.png`,rounded(master),1024,'full rounded');
  await png(`${review}/android-512.png`,fit(master,androidScale),512,'adaptive');
  await png(`${review}/web-maskable-512.png`,fit(master,webScale),512,'maskable');
  const maxCoreRadius=Math.max(...nodePositions.map(([x,y])=>Math.hypot(x-627,y-627)+216));
  const safe={maxCoreRadius,android:{scale:androidScale,coreRadius:maxCoreRadius*androidScale,limit:1254*33/108},web:{scale:webScale,coreRadius:maxCoreRadius*webScale,limit:1254*0.4}};
  if(safe.android.coreRadius>safe.android.limit || safe.web.coreRadius>safe.web.limit) throw new Error('안전영역 초과');
  await write(`${review}/assets.json`,JSON.stringify({renderer:sharp.versions,safe,assets:inventory},null,2)+'\n');
  console.log(JSON.stringify({pngs:inventory.length,icoFrames:icoFrames.map(x=>x.n),safe},null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
