"use strict";(self.webpackChunkdocumentation=self.webpackChunkdocumentation||[]).push([[61825],{63933:(e,t,a)=>{function i(e,t){e.accDescr&&t.setAccDescription?.(e.accDescr),e.accTitle&&t.setAccTitle?.(e.accTitle),e.title&&t.setDiagramTitle?.(e.title)}a.d(t,{S:()=>i}),(0,a(10009).K2)(i,"populateCommonDb")},61825:(e,t,a)=>{a.d(t,{diagram:()=>k});var i=a(63933),l=a(8159),r=a(77286),n=a(10009),s=a(78731),o=a(40388),c=n.UI.pie,p={sections:new Map,showData:!1,config:c},d=p.sections,u=p.showData,g=structuredClone(c),m=(0,n.K2)(()=>structuredClone(g),"getConfig"),f=(0,n.K2)(()=>{d=new Map,u=p.showData,(0,n.IU)()},"clear"),h=(0,n.K2)(({label:e,value:t})=>{d.has(e)||(d.set(e,t),n.Rm.debug(`added new section: ${e}, with value: ${t}`))},"addSection"),x=(0,n.K2)(()=>d,"getSections"),S=(0,n.K2)(e=>{u=e},"setShowData"),w=(0,n.K2)(()=>u,"getShowData"),D={getConfig:m,clear:f,setDiagramTitle:n.ke,getDiagramTitle:n.ab,setAccTitle:n.SV,getAccTitle:n.iN,setAccDescription:n.EI,getAccDescription:n.m7,addSection:h,getSections:x,setShowData:S,getShowData:w},T=(0,n.K2)((e,t)=>{(0,i.S)(e,t),t.setShowData(e.showData),e.sections.map(t.addSection)},"populateDb"),$={parse:(0,n.K2)(async e=>{let t=await (0,s.qg)("pie",e);n.Rm.debug(t),T(t,D)},"parse")},y=(0,n.K2)(e=>`
  .pieCircle{
    stroke: ${e.pieStrokeColor};
    stroke-width : ${e.pieStrokeWidth};
    opacity : ${e.pieOpacity};
  }
  .pieOuterCircle{
    stroke: ${e.pieOuterStrokeColor};
    stroke-width: ${e.pieOuterStrokeWidth};
    fill: none;
  }
  .pieTitleText {
    text-anchor: middle;
    font-size: ${e.pieTitleTextSize};
    fill: ${e.pieTitleTextColor};
    font-family: ${e.fontFamily};
  }
  .slice {
    font-family: ${e.fontFamily};
    fill: ${e.pieSectionTextColor};
    font-size:${e.pieSectionTextSize};
    // fill: white;
  }
  .legend text {
    fill: ${e.pieLegendTextColor};
    font-family: ${e.fontFamily};
    font-size: ${e.pieLegendTextSize};
  }
`,"getStyles"),C=(0,n.K2)(e=>{let t=[...e.entries()].map(e=>({label:e[0],value:e[1]})).sort((e,t)=>t.value-e.value);return(0,o.rLf)().value(e=>e.value)(t)},"createPieArcs"),k={parser:$,db:D,renderer:{draw:(0,n.K2)((e,t,a,i)=>{n.Rm.debug("rendering pie chart\n"+e);let s=i.db,c=(0,n.D7)(),p=(0,l.$t)(s.getConfig(),c.pie),d=(0,r.D)(t),u=d.append("g");u.attr("transform","translate(225,225)");let{themeVariables:g}=c,[m]=(0,l.I5)(g.pieOuterStrokeWidth);m??=2;let f=p.textPosition,h=(0,o.JLW)().innerRadius(0).outerRadius(185),x=(0,o.JLW)().innerRadius(185*f).outerRadius(185*f);u.append("circle").attr("cx",0).attr("cy",0).attr("r",185+m/2).attr("class","pieOuterCircle");let S=s.getSections(),w=C(S),D=[g.pie1,g.pie2,g.pie3,g.pie4,g.pie5,g.pie6,g.pie7,g.pie8,g.pie9,g.pie10,g.pie11,g.pie12],T=(0,o.UMr)(D);u.selectAll("mySlices").data(w).enter().append("path").attr("d",h).attr("fill",e=>T(e.data.label)).attr("class","pieCircle");let $=0;S.forEach(e=>{$+=e}),u.selectAll("mySlices").data(w).enter().append("text").text(e=>(e.data.value/$*100).toFixed(0)+"%").attr("transform",e=>"translate("+x.centroid(e)+")").style("text-anchor","middle").attr("class","slice"),u.append("text").text(s.getDiagramTitle()).attr("x",0).attr("y",-200).attr("class","pieTitleText");let y=u.selectAll(".legend").data(T.domain()).enter().append("g").attr("class","legend").attr("transform",(e,t)=>"translate(216,"+(22*t-22*T.domain().length/2)+")");y.append("rect").attr("width",18).attr("height",18).style("fill",T).style("stroke",T),y.data(w).append("text").attr("x",22).attr("y",14).text(e=>{let{label:t,value:a}=e.data;return s.getShowData()?`${t} [${a}]`:t});let k=512+Math.max(...y.selectAll("text").nodes().map(e=>e?.getBoundingClientRect().width??0));d.attr("viewBox",`0 0 ${k} 450`),(0,n.a$)(d,450,k,p.useMaxWidth)},"draw")},styles:y}}}]);