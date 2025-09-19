"use strict";(self.webpackChunkdocumentation=self.webpackChunkdocumentation||[]).push([["26450"],{17802:function(e,t,a){function i(e,t){e.accDescr&&t.setAccDescription?.(e.accDescr),e.accTitle&&t.setAccTitle?.(e.accTitle),e.title&&t.setDiagramTitle?.(e.title)}a.d(t,{A:()=>i}),(0,a(4171).eW)(i,"populateCommonDb")},93595:function(e,t,a){a.d(t,{diagram:()=>C});var i=a(17802),l=a(72216),r=a(33417),s=a(4171),n=a(3194),o=a(33476),c=s.vZ.pie,p={sections:new Map,showData:!1,config:c},d=p.sections,u=p.showData,g=structuredClone(c),f=(0,s.eW)(()=>structuredClone(g),"getConfig"),h=(0,s.eW)(()=>{d=new Map,u=p.showData,(0,s.ZH)()},"clear"),m=(0,s.eW)(({label:e,value:t})=>{if(t<0)throw Error(`"${e}" has invalid value: ${t}. Negative values are not allowed in pie charts. All slice values must be >= 0.`);d.has(e)||(d.set(e,t),s.cM.debug(`added new section: ${e}, with value: ${t}`))},"addSection"),x=(0,s.eW)(()=>d,"getSections"),w=(0,s.eW)(e=>{u=e},"setShowData"),$=(0,s.eW)(()=>u,"getShowData"),S={getConfig:f,clear:h,setDiagramTitle:s.g2,getDiagramTitle:s.Kr,setAccTitle:s.GN,getAccTitle:s.eu,setAccDescription:s.U$,getAccDescription:s.Mx,addSection:m,getSections:x,setShowData:w,getShowData:$},T=(0,s.eW)((e,t)=>{(0,i.A)(e,t),t.setShowData(e.showData),e.sections.map(t.addSection)},"populateDb"),v={parse:(0,s.eW)(async e=>{let t=await (0,n.Qc)("pie",e);s.cM.debug(t),T(t,S)},"parse")},y=(0,s.eW)(e=>`
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
`,"getStyles"),D=(0,s.eW)(e=>{let t=[...e.values()].reduce((e,t)=>e+t,0),a=[...e.entries()].map(([e,t])=>({label:e,value:t})).filter(e=>e.value/t*100>=1).sort((e,t)=>t.value-e.value);return(0,o.ve8)().value(e=>e.value)(a)},"createPieArcs"),C={parser:v,db:S,renderer:{draw:(0,s.eW)((e,t,a,i)=>{s.cM.debug("rendering pie chart\n"+e);let n=i.db,c=(0,s.nV)(),p=(0,l.Rb)(n.getConfig(),c.pie),d=(0,r.P)(t),u=d.append("g");u.attr("transform","translate(225,225)");let{themeVariables:g}=c,[f]=(0,l.VG)(g.pieOuterStrokeWidth);f??=2;let h=p.textPosition,m=(0,o.Nb1)().innerRadius(0).outerRadius(185),x=(0,o.Nb1)().innerRadius(185*h).outerRadius(185*h);u.append("circle").attr("cx",0).attr("cy",0).attr("r",185+f/2).attr("class","pieOuterCircle");let w=n.getSections(),$=D(w),S=[g.pie1,g.pie2,g.pie3,g.pie4,g.pie5,g.pie6,g.pie7,g.pie8,g.pie9,g.pie10,g.pie11,g.pie12],T=0;w.forEach(e=>{T+=e});let v=$.filter(e=>"0"!==(e.data.value/T*100).toFixed(0)),y=(0,o.PKp)(S);u.selectAll("mySlices").data(v).enter().append("path").attr("d",m).attr("fill",e=>y(e.data.label)).attr("class","pieCircle"),u.selectAll("mySlices").data(v).enter().append("text").text(e=>(e.data.value/T*100).toFixed(0)+"%").attr("transform",e=>"translate("+x.centroid(e)+")").style("text-anchor","middle").attr("class","slice"),u.append("text").text(n.getDiagramTitle()).attr("x",0).attr("y",-200).attr("class","pieTitleText");let C=[...w.entries()].map(([e,t])=>({label:e,value:t})),b=u.selectAll(".legend").data(C).enter().append("g").attr("class","legend").attr("transform",(e,t)=>"translate(216,"+(22*t-22*C.length/2)+")");b.append("rect").attr("width",18).attr("height",18).style("fill",e=>y(e.label)).style("stroke",e=>y(e.label)),b.append("text").attr("x",22).attr("y",14).text(e=>n.getShowData()?`${e.label} [${e.value}]`:e.label);let W=512+Math.max(...b.selectAll("text").nodes().map(e=>e?.getBoundingClientRect().width??0));d.attr("viewBox",`0 0 ${W} 450`),(0,s.v2)(d,450,W,p.useMaxWidth)},"draw")},styles:y}}}]);