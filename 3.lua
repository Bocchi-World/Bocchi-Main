--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.10.8) ~  Much Love, Ferib 

]]--

local v0=tonumber;local v1=string.byte;local v2=string.char;local v3=string.sub;local v4=string.gsub;local v5=string.rep;local v6=table.concat;local v7=table.insert;local v8=math.ldexp;local v9=getfenv or function() return _ENV;end ;local v10=setmetatable;local v11=pcall;local v12=select;local v13=unpack or table.unpack ;local v14=tonumber;local function v15(v16,v17,...) local v18=1;local v19;v16=v4(v3(v16,5),"..",function(v30) if (v1(v30,2)==81) then v19=v0(v3(v30,1,1));return "";else local v87=v2(v0(v30,16));if v19 then local v111=v5(v87,v19);v19=nil;return v111;else return v87;end end end);local function v20(v31,v32,v33) if v33 then local v88=1065 -(68 + 997) ;local v89;while true do if (v88==(0 -0)) then v89=(v31/((5 -3)^(v32-(1 -(117 -(32 + 85))))))%((4 -2)^(((v33-(620 -(555 + 64))) -(v32-(932 -(857 + 74)))) + (569 -(367 + 201)))) ;return v89-(v89%(928 -(214 + (1983 -(226 + 1044))))) ;end end else local v90=0 + 0 + 0 ;local v91;while true do if (v90==(0 + 0 + 0)) then v91=(879 -(282 + 595))^(v32-(1638 -(1523 + 114))) ;return (((v31%(v91 + v91))>=v91) and (1 + 0)) or (0 -0) ;end end end end local function v21() local v34=957 -(892 + 65) ;local v35;while true do if (v34==(2 -1)) then return v35;end if (v34==(0 -0)) then v35=v1(v16,v18,v18);v18=v18 + 1 ;v34=1 -(350 -(87 + 263)) ;end end end local function v22() local v36,v37=v1(v16,v18,v18 + (182 -(67 + 113)) );v18=v18 + 2 + 0 ;return (v37 * (628 -372)) + v36 ;end local function v23() local v38,v39,v40,v41=v1(v16,v18,v18 + 3 );v18=v18 + 3 + 1 ;return (v41 * 16777216) + (v40 * (260471 -194935)) + (v39 * (1208 -(802 + 150))) + v38 ;end local function v24() local v42=0 -0 ;local v43;local v44;local v45;local v46;local v47;local v48;while true do if (v42==(0 -0)) then v43=v23();v44=v23();v42=1 + 0 ;end if (v42==(1000 -(915 + (299 -217)))) then if (v47==(0 -0)) then if (v46==((0 -0) + (859 -(814 + 45)))) then return v48 * (0 -0) ;else v47=1188 -(1069 + 118) ;v45=0 -0 ;end elseif (v47==2047) then return ((v46==((0 -0) -0)) and (v48 * ((1 + 0)/((0 + 0) -0)))) or (v48 * NaN) ;end return v8(v48,v47-(1015 + 8) ) * (v45 + (v46/(((281 + 512) -(368 + 423))^(163 -111)))) ;end if (v42==(20 -(10 + 8))) then v47=v20(v44,80 -59 ,473 -(416 + 26) );v48=((v20(v44,102 -(955 -(261 + 624)) )==(1 + 0)) and  -(1 -0)) or (439 -((257 -112) + (1373 -(1020 + 60)))) ;v42=433 -(44 + 386) ;end if (v42==(1487 -(998 + 488))) then v45=1 + 0 ;v46=(v20(v44,1 + 0 ,792 -(201 + 571) ) * ((1140 -((1539 -(630 + 793)) + 1022))^((450 -317) -101))) + v43 ;v42=2 + 0 ;end end end local function v25(v49) local v50;if  not v49 then v49=v23();if (v49==(0 -0)) then return "";end end v50=v3(v16,v18,(v18 + v49) -(1 + 0) );v18=v18 + v49 ;local v51={};for v67=3 -2 , #v50 do v51[v67]=v2(v1(v3(v50,v67,v67)));end return v6(v51);end local v26=v23;local function v27(...) return {...},v12("#",...);end local function v28() local v52=(function() return function(v92,v93,v94,v95,v96,v97,v98,v99) local v92=(function() return 1559 -(120 + 1439) ;end)();local v93=(function() return;end)();local v95=(function() return;end)();while true do if (v92~=0) then else local v116=(function() return 1784 -(599 + 1185) ;end)();while true do if (0==v116) then v93=(function() return v94();end)();v95=(function() return nil;end)();v116=(function() return 1 + 0 ;end)();end if (v116~=(1 + 0)) then else v92=(function() return  #"/";end)();break;end end end if (v92== #"}") then if (v93== #",") then v95=(function() return v94()~=(574 -(507 + 67)) ;end)();elseif (v93==2) then v95=(function() return v96();end)();elseif (v93== #"gha") then v95=(function() return v97();end)();end v98[v99]=(function() return v95;end)();break;end end return v92,v93,v94,v95,v96,v97,v98,v99;end;end)();local v53=(function() return function(v100,v101,v102) local v103=(function() return 0;end)();local v104=(function() return;end)();while true do if (v103~=(1749 -(1013 + 736))) then else v104=(function() return 0;end)();while true do if (v104~=(0 + 0)) then else local v124=(function() return 0;end)();while true do if (0==v124) then v100[v101-#"|" ]=(function() return v102();end)();return v100,v101,v102;end end end end break;end end end;end)();local v54=(function() return {};end)();local v55=(function() return {};end)();local v56=(function() return {};end)();local v57=(function() return {v54,v55,nil,v56};end)();local v58=(function() return v23();end)();local v59=(function() return {};end)();for v69= #"|",v58 do FlatIdent_25011,Type,v21,Cons,v24,v25,v59,v69=(function() return v52(FlatIdent_25011,Type,v21,Cons,v24,v25,v59,v69);end)();end v57[ #"xxx"]=(function() return v21();end)();for v70= #"\\",v23() do local v71=(function() return v21();end)();if (v20(v71, #"|", #"]")==(0 -0)) then local v107=(function() return 0;end)();local v108=(function() return;end)();local v109=(function() return;end)();local v110=(function() return;end)();while true do if (v107==2) then if (v20(v109, #"]", #"[")== #"{") then v110[7 -5 ]=(function() return v59[v110[869 -(550 + 317) ]];end)();end if (v20(v109,2 -0 ,2 -0 )== #"{") then v110[ #"xxx"]=(function() return v59[v110[ #"nil"]];end)();end v107=(function() return 3;end)();end if (v107==(2 -1)) then local v120=(function() return 0;end)();local v121=(function() return;end)();while true do if (v120==(285 -(134 + 151))) then v121=(function() return 0;end)();while true do if (v121~=0) then else local v130=(function() return 1665 -(970 + 695) ;end)();while true do if (v130~=0) then else v110=(function() return {v22(),v22(),nil,nil};end)();if (v108==0) then local v216=(function() return 0;end)();local v217=(function() return;end)();while true do if (0==v216) then v217=(function() return 1990 -(582 + 1408) ;end)();while true do if (v217~=0) then else v110[ #"91("]=(function() return v22();end)();v110[ #"xnxx"]=(function() return v22();end)();break;end end break;end end elseif (v108== #"|") then v110[ #"xxx"]=(function() return v23();end)();elseif (v108==2) then v110[ #"gha"]=(function() return v23() -((6 -4)^(19 -3)) ;end)();elseif (v108~= #"nil") then else local v549=(function() return 0;end)();local v550=(function() return;end)();while true do if (v549==(0 -0)) then v550=(function() return 0;end)();while true do if (v550~=(1824 -(1195 + 629))) then else v110[ #"xnx"]=(function() return v23() -(2^16) ;end)();v110[ #"http"]=(function() return v22();end)();break;end end break;end end end v130=(function() return 1 -0 ;end)();end if (v130~=(242 -(187 + 54))) then else v121=(function() return 781 -(162 + 618) ;end)();break;end end end if (v121==(1 + 0)) then v107=(function() return 2;end)();break;end end break;end end end if ((0 + 0)==v107) then local v122=(function() return 0;end)();while true do if (v122==(1 -0)) then v107=(function() return 1 -0 ;end)();break;end if (v122==0) then local v128=(function() return 0 + 0 ;end)();while true do if (0==v128) then v108=(function() return v20(v71,1638 -(1373 + 263) , #"xnx");end)();v109=(function() return v20(v71, #"?id=",1006 -(451 + 549) );end)();v128=(function() return 1;end)();end if (v128==1) then v122=(function() return 1;end)();break;end end end end end if (v107==3) then if (v20(v109, #"-19", #"xnx")~= #"~") then else v110[ #"?id="]=(function() return v59[v110[ #"http"]];end)();end v54[v70]=(function() return v110;end)();break;end end end end for v72= #"[",v23() do v55,v72,v28=(function() return v53(v55,v72,v28);end)();end return v57;end local function v29(v61,v62,v63) local v64=v61[1 + 0 ];local v65=v61[2 -(605 -(316 + 289)) ];local v66=v61[4 -1 ];return function(...) local v73=v64;local v74=v65;local v75=v66;local v76=v27;local v77=1385 -(746 + 638) ;local v78= -1;local v79={};local v80={...};local v81=v12("#",...) -(1 -(0 -0)) ;local v82={};local v83={};for v105=0,v81 do if (v105>=v75) then v79[v105-v75 ]=v80[v105 + (342 -(218 + 123)) ];else v83[v105]=v80[v105 + 1 ];end end local v84=(v81-v75) + 1 ;local v85;local v86;while true do local v106=0;while true do if ((3891<4141) and (v106==((74 + 1507) -(1535 + 46)))) then v85=v73[v77];v86=v85[1 + 0 ];v106=1;end if (v106==(1 + 0)) then if (v86<=(583 -(306 + 254))) then if ((v86<=(1 + 10)) or (2011>=3155)) then if (v86<=(9 -4)) then if ((553<1543) and (v86<=(1469 -(899 + (2021 -(666 + 787)))))) then if ((2015==2015) and (v86<=0)) then local v131=v85[2 + 0 ];local v132=v83[v85[7 -4 ]];v83[v131 + (604 -(268 + 335)) ]=v132;v83[v131]=v132[v85[294 -(60 + 230) ]];elseif ((v86==1) or (4241<=2332)) then local v218;local v219;local v218,v220;local v221;local v222;v83[v85[2]]=v63[v85[575 -(426 + (571 -(360 + 65))) ]];v77=v77 + 1 + 0 + 0 ;v85=v73[v77];v83[v85[2]]=v83[v85[1459 -(282 + 1174) ]][v85[815 -(569 + 242) ]];v77=v77 + 1 ;v85=v73[v77];v222=v85[5 -3 ];v221=v83[v85[1 + 2 ]];v83[v222 + (1025 -(706 + 318)) ]=v221;v83[v222]=v221[v85[1255 -(721 + 530) ]];v77=v77 + (1272 -((1199 -(79 + 175)) + 326)) ;v85=v73[v77];v222=v85[4 -2 ];v218,v220=v76(v83[v222](v83[v222 + 1 + 0 ]));v78=(v220 + v222) -(701 -(271 + 429)) ;v219=0 + 0 ;for v404=v222,v78 do v219=v219 + (1501 -(1408 + 92)) ;v83[v404]=v218[v219];end v77=v77 + (1087 -(461 + 625)) ;v85=v73[v77];v222=v85[1290 -(993 + 295) ];v218={v83[v222](v13(v83,v222 + (1172 -(418 + 753)) ,v78))};v219=0 + (0 -0) ;for v407=v222,v85[1 + 3 + 0 ] do local v408=0 + 0 ;while true do if (v408==((0 -0) + 0)) then v219=v219 + (530 -(406 + 123)) ;v83[v407]=v218[v219];break;end end end v77=v77 + (1770 -((3367 -1618) + 20)) ;v85=v73[v77];v77=v85[3];else local v235;local v236;local v237;v83[v85[1 + 1 ]]={};v77=v77 + (1323 -((2148 -(503 + 396)) + 73)) ;v85=v73[v77];v83[v85[1 + 1 ]]=v85[1148 -(466 + 679) ];v77=v77 + (2 -1) ;v85=v73[v77];v83[v85[(186 -(92 + 89)) -3 ]]= #v83[v85[(3690 -1787) -(106 + 921 + 873) ]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[1 + 1 ]]=v85[8 -5 ];v77=v77 + (2 -1) ;v85=v73[v77];v237=v85[116 -(4 + 110) ];v236=v83[v237];v235=v83[v237 + (586 -(57 + 527)) ];if (v235>(1427 -(41 + 1386))) then if ((v236>v83[v237 + ((62 + 42) -(17 + (336 -250))) ]) or (2364<1157)) then v77=v85[3 + 0 + 0 ];else v83[v237 + (6 -3) ]=v236;end elseif (v236<v83[v237 + (2 -1) ]) then v77=v85[169 -(122 + 44) ];else v83[v237 + (5 -2) ]=v236;end end elseif (v86<=(9 -6)) then local v136=0 + 0 ;local v137;while true do if ((v136==0) or (1167>1278)) then v137=v85[1 + 1 ];v83[v137]=v83[v137](v83[v137 + ((2 -1) -0) ]);break;end end elseif (v86==(69 -(30 + 31 + 4))) then v83[v85[2 + 0 ]]=v83[v85[1260 -(1043 + 214) ]]%v85[15 -11 ] ;else v83[v85[1214 -(323 + 889) ]]=v83[v85[7 -4 ]] + v85[584 -(361 + 219) ] ;end elseif (v86<=(328 -(53 + 128 + 139))) then if (v86<=(2 + 4)) then local v138;local v139;local v140;v140=v85[2];v83[v140](v83[v140 + (414 -(15 + 398)) ]);v77=v77 + (983 -(18 + 964)) ;v85=v73[v77];v83[v85[2]]=v63[v85[11 -8 ]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[2 + 0 ]]=v62[v85[853 -(20 + 830) ]];v77=v77 + 1 ;v85=v73[v77];v83[v85[2 + 0 ]]=v83[v85[3]][v85[130 -(116 + 10) ]];v77=v77 + 1 + 0 ;v85=v73[v77];v140=v85[740 -(542 + 196) ];v139=v83[v85[6 -3 ]];v83[v140 + 1 + 0 ]=v139;v83[v140]=v139[v85[3 + 1 ]];v77=v77 + 1 + 0 ;v85=v73[v77];v140=v85[2];v83[v140]=v83[v140](v83[v140 + (2 -1) ]);v77=v77 + (2 -1) ;v85=v73[v77];v139=v85[1554 -(1126 + 425) ];v138=v83[v139];for v201=v139 + 1 ,v85[4] do v138=v138   .. v83[v201] ;end v83[v85[(1239 -832) -(118 + 287) ]]=v138;v77=v77 + 1 ;v85=v73[v77];v140=v85[7 -5 ];v83[v140](v83[v140 + (1122 -(118 + 1003)) ]);v77=v77 + 1 ;v85=v73[v77];v77=v85[8 -5 ];elseif (v86>(384 -(142 + 235))) then local v248=v85[9 -7 ];v83[v248]=v83[v248](v13(v83,v248 + 1 + 0 + 0 ,v85[(1494 -514) -(553 + 424) ]));else local v250=v85[2];local v251={v83[v250](v13(v83,v250 + 1 + 0 ,v78))};local v252=0 + 0 ;for v411=v250,v85[3 + 1 ] do v252=v252 + (1245 -(485 + 759)) + 0 ;v83[v411]=v251[v252];end end elseif ((v86<=9) or (1145<=1082)) then local v158=0 + 0 ;local v159;while true do if (v158==(0 -0)) then v159=v85[5 -3 ];v83[v159](v13(v83,v159 + 1 ,v78));break;end end elseif (v86>(22 -(27 -15))) then local v253;local v254;local v255;v255=v85[2];v83[v255](v83[v255 + 1 + 0 ]);v77=v77 + (4 -3) ;v85=v73[v77];v83[v85[755 -(239 + 514) ]]=v63[v85[2 + 1 ]];v77=v77 + ((2519 -(442 + 747)) -(797 + 532)) ;v85=v73[v77];v83[v85[2]]=v62[v85[3]];v77=v77 + (1136 -(832 + 303)) + 0 ;v85=v73[v77];v83[v85[1 + 1 ]]=v83[v85[3]][v85[9 -(951 -(88 + 858)) ]];v77=v77 + (1203 -(373 + 253 + 576)) ;v85=v73[v77];v255=v85[2];v254=v83[v85[3]];v83[v255 + 1 ]=v254;v83[v255]=v254[v85[(609 + 126) -(476 + 255) ]];v77=v77 + (1131 -(369 + 32 + 729)) ;v85=v73[v77];v255=v85[2 + 0 ];v83[v255]=v83[v255](v83[v255 + 1 ]);v77=v77 + (1 -0) ;v85=v73[v77];v254=v85[5 -2 ];v253=v83[v254];for v415=v254 + (239 -(64 + 174)) ,v85[793 -(766 + 23) ] do v253=v253   .. v83[v415] ;end v83[v85[(4 -3) + 1 ]]=v253;v77=v77 + 1 ;v85=v73[v77];v255=v85[2 -0 ];v83[v255](v83[v255 + (337 -(144 + 192)) ]);v77=v77 + (217 -(42 + 174)) ;v85=v73[v77];v77=v85[3];else v77=v85[3 + 0 ];end elseif (v86<=(15 + 2)) then if ((v86<=((7 -1) + 8)) or (3105==4881)) then if (v86<=(1516 -(363 + 1141))) then v83[v85[2]]= #v83[v85[1583 -(1183 + (1045 -648)) ]];elseif (v86==(39 -26)) then v83[v85[2 + 0 ]]();else v83[v85[2 + 0 ]]=v83[v85[1978 -((6492 -4579) + 62) ]]%v83[v85[3 + 1 ]] ;end elseif ((v86<=15) or (1887>4878)) then local v161=v85[2];local v162=v83[v161];local v163=v83[v161 + (5 -3) ];if (v163>(1933 -(565 + 1368))) then if (v162>v83[v161 + (3 -2) ]) then v77=v85[1664 -(1477 + 184) ];else v83[v161 + (3 -(1073 -(1036 + 37))) ]=v162;end elseif (v162<v83[v161 + 1 + 0 ]) then v77=v85[859 -(564 + 292) ];else v83[v161 + 3 ]=v162;end elseif (v86>(26 -10)) then v83[v85[5 -3 ]][v85[307 -(244 + 60) ]]=v83[v85[4 + 0 ]];else local v278;local v279;local v278,v280;local v281;local v282;v83[v85[(339 + 139) -(41 + 435) ]]=v63[v85[5 -2 ]];v77=v77 + (1002 -(938 + 63)) ;v85=v73[v77];v83[v85[2 + 0 + 0 ]]=v83[v85[1128 -(936 + 189) ]][v85[2 + (1482 -(641 + 839)) ]];v77=v77 + 1 ;v85=v73[v77];v282=v85[2];v281=v83[v85[3]];v83[v282 + (1614 -(1565 + 48)) ]=v281;v83[v282]=v281[v85[3 + 1 ]];v77=v77 + (1139 -(782 + 356)) ;v85=v73[v77];v282=v85[2];v278,v280=v76(v83[v282](v83[v282 + (268 -(176 + 91)) ]));v78=(v280 + v282) -(2 -1) ;v279=0 -0 ;for v416=v282,v78 do v279=v279 + (1093 -(975 + 117)) ;v83[v416]=v278[v279];end v77=v77 + (914 -(910 + 3)) ;v85=v73[v77];v282=v85[1877 -(157 + 1718) ];v278={v83[v282](v13(v83,v282 + (3 -2) ,v78))};v279=(0 -0) -0 ;for v419=v282,v85[1022 -(697 + 321) ] do v279=v279 + 1 ;v83[v419]=v278[v279];end v77=v77 + 1 ;v85=v73[v77];v77=v85[7 -4 ];end elseif ((v86<=20) or (4087>4116)) then if (v86<=(37 -19)) then v83[v85[4 -2 ]]=v85[3] + v83[v85[4]] ;elseif ((1106<=1266) and (v86>((1692 -(1466 + 218)) + 11))) then local v295=v85[3 -1 ];local v296=v83[v295 + (5 -3) ];local v297=v83[v295] + v296 ;v83[v295]=v297;if ((3155<4650) and (v296>(1227 -(322 + 905)))) then if (v297<=v83[v295 + (612 -(602 + 9)) ]) then local v537=1189 -(449 + 740) ;while true do if ((3774>=1839) and (v537==(872 -(826 + 22 + 24)))) then v77=v85[950 -(245 + 702) ];v83[v295 + (9 -6) ]=v297;break;end end end elseif (v297>=v83[v295 + 1 + 0 ]) then local v538=0;while true do if ((2811==2811) and (v538==0)) then v77=v85[3];v83[v295 + (1901 -(260 + 1638)) ]=v297;break;end end end else local v299;local v300,v301;local v302;v83[v85[442 -(382 + 58) ]]=v83[v85[9 -6 ]];v77=v77 + 1 ;v85=v73[v77];v83[v85[(1150 -(556 + 592)) + 0 ]]=v62[v85[5 -2 ]];v77=v77 + (2 -1) ;v85=v73[v77];v83[v85[2]]=v62[v85[1208 -(321 + 581 + 303) ]];v77=v77 + (1 -0) ;v85=v73[v77];v83[v85[4 -2 ]]=v62[v85[1 + 2 ]];v77=v77 + (809 -(329 + 479)) ;v85=v73[v77];v83[v85[2]]=v62[v85[1693 -(1121 + 569) ]];v77=v77 + (215 -(22 + 192)) ;v85=v73[v77];v83[v85[(1539 -(174 + 680)) -(483 + 200) ]]=v83[v85[1466 -(1404 + (202 -143)) ]];v77=v77 + ((3 -1) -1) ;v85=v73[v77];v83[v85[2 -0 ]]=v83[v85[(549 + 219) -(468 + 297) ]];v77=v77 + (563 -((1073 -(396 + 343)) + 228)) ;v85=v73[v77];v83[v85[6 -4 ]]=v83[v85[6 -(1 + 2) ]] + v85[6 -2 ] ;v77=v77 + 1 + (1477 -(29 + 1448)) ;v85=v73[v77];v302=v85[(1627 -(135 + 1254)) -(141 + 95) ];v300,v301=v76(v83[v302](v13(v83,v302 + 1 + 0 ,v85[3])));v78=(v301 + v302) -(2 -1) ;v299=0 -(0 -0) ;for v422=v302,v78 do v299=v299 + 1 + 0 ;v83[v422]=v300[v299];end v77=v77 + 1 ;v85=v73[v77];v302=v85[5 -3 ];v83[v302]=v83[v302](v13(v83,v302 + 1 + 0 ,v78));v77=v77 + 1 ;v85=v73[v77];v83[v85[2 + 0 ]]=v62[v85[4 -1 ]];v77=v77 + 1 ;v85=v73[v77];v83[v85[2 + 0 ]]=v62[v85[166 -(92 + 71) ]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[2 -0 ]]=v83[v85[768 -(574 + 191) ]];v77=v77 + 1 + (0 -0) ;v85=v73[v77];v83[v85[4 -2 ]]= #v83[v85[3]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[(568 + 283) -(254 + 595) ]]=v83[v85[3]]%v83[v85[130 -(55 + 71) ]] ;v77=v77 + (1 -0) ;v85=v73[v77];v83[v85[(3319 -(389 + 1138)) -((1147 -(102 + 472)) + 1217) ]]=v85[8 -5 ] + v83[v85[1 + 0 + 3 ]] ;v77=v77 + (1 -(0 + 0)) ;v85=v73[v77];v83[v85[941 -(714 + 225) ]]= #v83[v85[8 -5 ]];v77=v77 + (1 -(0 + 0)) ;v85=v73[v77];v83[v85[1 + 1 ]]=v83[v85[3 -0 ]]%v83[v85[4]] ;v77=v77 + (807 -((1663 -(320 + 1225)) + 688)) ;v85=v73[v77];v83[v85[50 -(25 + (40 -17)) ]]=v85[3] + v83[v85[1 + 0 + 3 ]] ;v77=v77 + (1887 -(927 + 959)) ;v85=v73[v77];v83[v85[6 -4 ]]=v83[v85[735 -((1480 -(157 + 1307)) + 716) ]] + v85[7 -3 ] ;v77=v77 + ((1957 -(821 + 1038)) -(11 + 86)) ;v85=v73[v77];v302=v85[4 -2 ];v300,v301=v76(v83[v302](v13(v83,v302 + (2 -1) ,v85[288 -(175 + 110) ])));v78=(v301 + v302) -(2 -1) ;v299=0;for v425=v302,v78 do v299=v299 + ((1 + 3) -3) ;v83[v425]=v300[v299];end v77=v77 + (1797 -(503 + 1293)) ;v85=v73[v77];v302=v85[2];v300,v301=v76(v83[v302](v13(v83,v302 + (2 -1) ,v78)));v78=(v301 + v302) -((1 -0) + 0 + 0) ;v299=1061 -(810 + 251) ;for v428=v302,v78 do v299=v299 + 1 + 0 ;v83[v428]=v300[v299];end v77=v77 + 1 + 0 ;v85=v73[v77];v302=v85[2 + 0 ];v83[v302]=v83[v302](v13(v83,v302 + (534 -(43 + 490)) ,v78));v77=v77 + (734 -((1762 -1051) + 22)) ;v85=v73[v77];v83[v85[2]]=v83[v85[(1037 -(834 + 192)) -8 ]]%v85[863 -(240 + 40 + 579) ] ;v77=v77 + 1 ;v85=v73[v77];v302=v85[1 + 0 + 1 + 0 ];v300,v301=v76(v83[v302](v83[v302 + 1 ]));v78=(v301 + v302) -1 ;v299=0;for v431=v302,v78 do v299=v299 + (1 -0) ;v83[v431]=v300[v299];end v77=v77 + 1 + 0 ;v85=v73[v77];v302=v85[2 -0 ];v83[v302](v13(v83,v302 + (305 -(300 + 4)) ,v78));end elseif ((2146>1122) and (v86<=((472 + 1293) -(1344 + 400)))) then local v165=v85[407 -(255 + 150) ];local v166,v167=v76(v83[v165](v83[v165 + 1 + (0 -0) ]));v78=(v167 + v165) -(1 + 0) ;local v168=0;for v202=v165,v78 do v168=v168 + ((366 -(112 + 250)) -3) ;v83[v202]=v166[v168];end elseif (v86==(70 -(20 + 28))) then local v335=v85[1741 -(404 + 1335) ];v83[v335]=v83[v335](v13(v83,v335 + (407 -(183 + 223)) ,v78));else v83[v85[2]]=v85[3 -0 ];end elseif (v86<=(24 + 11)) then if (v86<=29) then if (v86<=26) then if (v86<=(9 + 15)) then local v169=v74[v85[3]];local v170;local v171={};v170=v10({},{__index=function(v205,v206) local v207=v171[v206];return v207[338 -(10 + 327) ][v207[2 + 0 ]];end,__newindex=function(v208,v209,v210) local v211=v171[v209];v211[339 -(118 + 220) ][v211[2]]=v210;end});for v213=1 + 0 ,v85[453 -(108 + 341) ] do v77=v77 + 1 + 0 ;local v214=v73[v77];if (v214[4 -(7 -4) ]==(1531 -(711 + 782))) then v171[v213-1 ]={v83,v214[3]};else v171[v213-(470 -(270 + 199)) ]={v62,v214[1822 -(580 + 1239) ]};end v82[ #v82 + (2 -1) ]=v171;end v83[v85[2 + 0 ]]=v29(v169,v170,v63);elseif (v86==(1 + 24)) then v83[v85[1 + 1 + 0 ]]=v83[v85[7 -4 ]][v85[4]];else local v341=v85[2 + 0 ];local v342=v85[4];local v343=v341 + (1169 -(645 + 522)) ;local v344={v83[v341](v83[v341 + 1 ],v83[v343])};for v436=1 + 0 ,v342 do v83[v343 + v436 ]=v344[v436];end local v345=v344[4 -3 ];if (v345 or (56==3616)) then v83[v343]=v345;v77=v85[8 -5 ];else v77=v77 + (1837 -(1045 + 791)) ;end end elseif (v86<=(68 -41)) then v83[v85[2 -0 ]]={};elseif (v86==28) then local v346=v85[(380 + 127) -(351 + 154) ];v83[v346](v83[v346 + (1575 -(1281 + 293)) ]);else local v347=266 -(28 + 238) ;local v348;while true do if (v347==(10 -5)) then v83[v85[1561 -(1381 + 178) ]]=v85[3];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[2 + 0 ]]=v85[1 + 1 + 1 + 0 ];v347=20 -14 ;end if (v347==0) then v348=nil;v83[v85[2 + 0 ]]=v83[v85[473 -(381 + (1503 -(1001 + 413))) ]];v77=v77 + (2 -1) ;v85=v73[v77];v347=883 -(244 + 638) ;end if (v347==(7 + 0)) then v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[2 -0 ]][v85[(1852 -(627 + 66)) -(1074 + 82) ]]=v83[v85[8 -(11 -7) ]];break;end if (v347==(1787 -(214 + 1570))) then v77=v77 + (1456 -(990 + 465)) ;v85=v73[v77];v83[v85[(603 -(512 + 90)) + 1 ]][v85[2 + 1 ]]=v83[v85[4]];v77=v77 + 1 + 0 ;v347=15 -(1917 -(1665 + 241)) ;end if (v347==((2449 -(373 + 344)) -(1668 + 58))) then v77=v77 + 1 ;v85=v73[v77];v348=v85[628 -(512 + 114) ];v83[v348]=v83[v348](v13(v83,v348 + (2 -1) ,v85[(3 + 2) -2 ]));v347=24 -17 ;end if (v347==(2 + 2)) then v85=v73[v77];v83[v85[1 + 1 ]]=v83[v85[3 + 0 ]];v77=v77 + ((1 + 2) -2) ;v85=v73[v77];v347=(5272 -3273) -(109 + (3189 -1304)) ;end if (v347==(1470 -(1269 + 200))) then v83[v85[3 -(1100 -(35 + 1064)) ]]=v85[3];v77=v77 + ((594 + 222) -(98 + 717)) ;v85=v73[v77];v83[v85[(1771 -943) -(802 + 24) ]]=v85[3];v347=2 -0 ;end if (v347==(2 -0)) then v77=v77 + 1 + 0 ;v85=v73[v77];v348=v85[2 + 0 ];v83[v348]=v83[v348](v13(v83,v348 + 1 + 0 ,v85[1 + 2 ]));v347=8 -5 ;end end end elseif (v86<=(106 -74)) then if (v86<=30) then local v174=0;local v175;local v176;local v177;while true do if (v174==(2 + 1)) then v83[v177 + 1 + 0 ]=v176;v83[v177]=v176[v85[4]];v77=v77 + 1 + 0 + (1236 -(298 + 938)) ;v85=v73[v77];v177=v85[(1261 -(233 + 1026)) + 0 ];v83[v177]=v83[v177](v83[v177 + 1 + 0 ]);v174=1437 -(797 + 636) ;end if ((v174==0) or (2421<622)) then v175=nil;v176=nil;v177=nil;v177=v85[9 -7 ];v83[v177](v83[v177 + (1620 -(1427 + 192)) ]);v77=v77 + 1 ;v174=1 + 0 ;end if ((1009<=1130) and (v174==(8 -4))) then v77=v77 + 1 ;v85=v73[v77];v176=v85[3 + 0 ];v175=v83[v176];for v477=v176 + 1 + 0 ,v85[330 -(192 + (1800 -(636 + 1030))) ] do v175=v175   .. v83[v477] ;end v83[v85[1278 -(316 + 960) ]]=v175;v174=5;end if ((4 + 2)==v174) then v77=v85[2 + 1 + 0 ];break;end if (v174==(2 + 0)) then v85=v73[v77];v83[v85[2 + 0 ]]=v83[v85[3]][v85[(5 + 10) -11 ]];v77=v77 + (552 -(83 + 468)) ;v85=v73[v77];v177=v85[1808 -(1202 + 604) ];v176=v83[v85[13 -(1 + 9) ]];v174=3;end if ((2758<2980) and (v174==(7 -2))) then v77=v77 + (2 -1) ;v85=v73[v77];v177=v85[327 -(45 + 280) ];v83[v177](v83[v177 + 1 + (221 -(55 + 166)) ]);v77=v77 + 1 + 0 ;v85=v73[v77];v174=2 + 4 ;end if (v174==1) then v85=v73[v77];v83[v85[1 + 1 ]]=v63[v85[2 + 1 ]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[(1 + 2) -1 ]]=v62[v85[(7309 -5395) -(340 + 1571) ]];v77=v77 + 1 + 0 ;v174=1774 -(1733 + 39) ;end end elseif ((v86>(85 -54)) or (86>=3626)) then local v349=v85[1036 -(125 + 909) ];do return v83[v349](v13(v83,v349 + 1 ,v85[3]));end elseif (v83[v85[2]]==v85[1952 -(1096 + 852) ]) then v77=v77 + 1 ;else v77=v85[2 + 1 ];end elseif (v86<=(46 -(310 -(36 + 261)))) then local v178=0;local v179;local v180;local v181;local v182;while true do if ((2395==2395) and (v178==(2 + 0))) then for v479=v179,v78 do local v480=(894 -382) -(409 + 103) ;while true do if ((3780>2709) and (v480==((1604 -(34 + 1334)) -(46 + 190)))) then v182=v182 + 1 ;v83[v479]=v180[v182];break;end end end break;end if (v178==(96 -(20 + 31 + 44))) then v78=(v181 + v179) -1 ;v182=0;v178=1 + 1 ;end if ((v178==(1317 -(1114 + 203))) or (237>=2273)) then v179=v85[728 -(228 + 498) ];v180,v181=v76(v83[v179](v13(v83,v179 + 1 + 0 + 0 ,v78)));v178=1 + (1283 -(1035 + 248)) ;end end elseif ((v86>34) or (2040<=703)) then local v350;v83[v85[2]]=v85[666 -(174 + (510 -(20 + 1))) ];v77=v77 + (2 -1) ;v85=v73[v77];v83[v85[1907 -(830 + 1075) ]]=v85[3];v77=v77 + (525 -(303 + 221)) ;v85=v73[v77];v350=v85[2];v83[v350]=v83[v350](v13(v83,v350 + (1270 -(231 + 1038)) ,v85[3 + 0 ]));v77=v77 + (1163 -(171 + 991)) ;v85=v73[v77];v83[v85[8 -6 ]][v85[3]]=v83[v85[4]];v77=v77 + (2 -1) ;v85=v73[v77];v83[v85[2]]=v83[v85[7 -4 ]];v77=v77 + 1 ;v85=v73[v77];v83[v85[2 + 0 + 0 ]]=v85[(329 -(134 + 185)) -7 ];v77=v77 + (2 -1) ;v85=v73[v77];v83[v85[2 -(1133 -(549 + 584)) ]]=v85[9 -6 ];v77=v77 + (1249 -(111 + 1137)) ;v85=v73[v77];v350=v85[160 -(91 + 67) ];v83[v350]=v83[v350](v13(v83,v350 + (2 -1) ,v85[1 + 2 ]));v77=v77 + (524 -(423 + 100)) ;v85=v73[v77];v83[v85[1 + 1 ]][v85[7 -4 ]]=v83[v85[3 + 1 ]];v77=v77 + (772 -(326 + 445)) ;v85=v73[v77];v83[v85[8 -6 ]]=v83[v85[6 -3 ]];else local v370=0 -0 ;local v371;local v372;while true do if (v370==(712 -((1215 -(314 + 371)) + 181))) then for v539=v371 + ((3027 -2145) -(614 + 267)) ,v85[4] do v372=v372   .. v83[v539] ;end v83[v85[(1002 -(478 + 490)) -(19 + 13) ]]=v372;break;end if (v370==(0 -0)) then v371=v85[6 -3 ];v372=v83[v371];v370=2 -(1 + 0) ;end end end elseif (v86<=41) then if (v86<=(10 + (1200 -(786 + 386)))) then if (v86<=36) then local v183=v85[3 -1 ];do return v13(v83,v183,v78);end elseif ((3279<=3967) and (v86>(76 -39))) then v83[v85[2]]=v83[v85[1815 -(1293 + 519) ]];elseif  not v83[v85[3 -1 ]] then v77=v77 + (2 -1) ;else v77=v85[3];end elseif ((v86<=39) or (1988==877)) then do return;end elseif (v86==(76 -36)) then for v463=v85[8 -6 ],v85[3] do v83[v463]=nil;end else v83[v85[4 -(6 -4) ]]=v63[v85[2 + 1 ]];end elseif (v86<=(9 + 35)) then if (v86<=42) then v83[v85[2]]={};v77=v77 + (2 -1) ;v85=v73[v77];v83[v85[1 + 1 ]]=v63[v85[1 + 2 ]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[1098 -(709 + 387) ]]=v83[v85[3]][v85[1862 -((2052 -(1055 + 324)) + (2525 -(1093 + 247))) ]];v77=v77 + 1 ;v85=v73[v77];v83[v85[5 -3 ]]=v63[v85[3]];v77=v77 + (3 -2) ;v85=v73[v77];v83[v85[2 -0 ]]=v83[v85[3 + 0 ]][v85[3 + 1 ]];v77=v77 + 1 ;v85=v73[v77];v83[v85[2 + 0 ]]=v63[v85[3 -0 ]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[3 -1 ]]=v83[v85[5 -2 ]][v85[1884 -(446 + 1434) ]];v77=v77 + (1284 -(1040 + 243)) ;v85=v73[v77];v83[v85[5 -3 ]]=v63[v85[1850 -(559 + 1288) ]];v77=v77 + (1932 -(609 + 1322)) ;v85=v73[v77];if  not v83[v85[456 -(13 + 441) ]] then v77=v77 + (3 -2) ;else v77=v85[7 -4 ];end elseif (v86==43) then local v378;v83[v85[9 -7 ]]=v85[3];v77=v77 + 1 ;v85=v73[v77];v378=v85[1 + 1 ];v83[v378]=v83[v378](v13(v83,v378 + 1 ,v85[10 -7 ]));v77=v77 + 1 + 0 + 0 ;v85=v73[v77];v83[v85[1 + 1 ]][v85[8 -5 ]]=v83[v85[3 + 1 ]];v77=v77 + ((3 -2) -0) ;v85=v73[v77];v83[v85[2 + 0 ]]=v83[v85[9 -6 ]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[2 + 0 ]]=v85[(8 -5) + 0 ];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[(1093 -658) -(55 + 98 + 280) ]]=v85[8 -5 ];v77=v77 + 1 + 0 ;v85=v73[v77];v378=v85[1 + 1 ];v83[v378]=v83[v378](v13(v83,v378 + (3 -2) ,v85[2 + 1 ]));v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[2 + 0 ]][v85[4 -1 ]]=v83[v85[4]];v77=v77 + 1 + 0 ;v85=v73[v77];v83[v85[2]]=v85[3];v77=v77 + 1 ;v85=v73[v77];for v465=v85[669 -(89 + 578) ],v85[3 + 0 ] do v83[v465]=nil;end else local v394=0 -0 ;local v395;local v396;local v397;local v398;local v399;while true do if ((4291>1912) and (v394==4)) then v396=1049 -(572 + 477) ;for v540=v399,v78 do local v541=0 + 0 ;while true do if (v541==(0 + 0)) then v396=v396 + (3 -2) + 0 ;v83[v540]=v395[v396];break;end end end v77=v77 + (87 -(84 + 2)) ;v85=v73[v77];v399=v85[2 -0 ];v394=4 + 1 ;end if ((2003<2339) and (3==v394)) then v77=v77 + (843 -(375 + 122 + 345)) ;v85=v73[v77];v399=v85[(2 -1) + 1 ];v395,v397=v76(v83[v399](v83[v399 + 1 + (688 -(364 + 324)) ]));v78=(v397 + v399) -1 ;v394=1337 -((1658 -1053) + 728) ;end if (v394==(1 + 0)) then v83[v85[3 -1 ]]=v63[v85[1 + 2 ]];v77=v77 + 1 ;v85=v73[v77];v83[v85[2]]=v83[v85[3]][v85[14 -10 ]];v77=v77 + 1 ;v394=4 -2 ;end if (v394==(5 + 0)) then v395={v83[v399](v13(v83,v399 + (2 -1) ,v78))};v396=0;for v542=v399,v85[4 + 0 ] do v396=v396 + ((163 + 327) -(457 + 32)) ;v83[v542]=v395[v396];end v77=v77 + 1 + 0 ;v85=v73[v77];v394=6;end if (v394==0) then v395=nil;v396=nil;v395,v397=nil;v398=nil;v399=nil;v394=1;end if ((1404 -(832 + 570))==v394) then v85=v73[v77];v399=v85[2 + 0 ];v398=v83[v85[1 + 2 ]];v83[v399 + (3 -2) ]=v398;v83[v399]=v398[v85[4]];v394=2 + 1 ;end if ((432==432) and (v394==6)) then v77=v85[799 -((2460 -1872) + (332 -124)) ];break;end end end elseif (v86<=45) then v83[v85[2]]=v62[v85[8 -5 ]];elseif (v86>(1846 -(884 + 916))) then if v83[v85[3 -(2 -1) ]] then v77=v77 + 1 + (1268 -(1249 + 19)) ;else v77=v85[656 -(232 + 421) ];end else local v400=v85[1891 -(1569 + 320) ];local v401,v402=v76(v83[v400](v13(v83,v400 + 1 ,v85[1 + 2 ])));v78=(v402 + v400) -1 ;local v403=0 + 0 ;for v467=v400,v78 do v403=v403 + 1 ;v83[v467]=v401[v403];end end v77=v77 + (3 -2) ;break;end end end end;end return v29(v28(),{},v17)(...);end return v15("LOL!1E3Q0003063Q00737472696E6703043Q006368617203043Q00627974652Q033Q0073756203053Q0062697433322Q033Q0062697403043Q0062786F7203053Q007461626C6503063Q00636F6E63617403063Q00696E73657274026Q003340030F3Q00F3BE5BC697C4BF16DA8ED4B55293C103053Q00E1A1DB36A9026Q00314003053Q000716AADFDB03073Q00BC5479DFB1BFED026Q002840031A3Q001A1679733E16703C3812666821107879681679753C07716E725303043Q001C487314026Q002440030F3Q00B542BAB38C40A4A2A04EA1B39146BA03043Q00C7E523C8026Q001440030F3Q004F43F1EA6B43F8A57943FFE4711CBC03043Q00851D269C026Q00084003053Q0012F943DC3A03043Q00BD569C20028Q00026Q00F03F004D4Q002A7Q00122Q000100013Q00202Q00010001000200122Q000200013Q00202Q00020002000300122Q000300013Q00202Q00030003000400122Q000400053Q00062Q0004000B0001000100040A3Q000B0001001229000400063Q002019000500040007001229000600083Q002019000600060009001229000700083Q00201900070007000A00061800083Q000100062Q00263Q00074Q00263Q00014Q00263Q00054Q00263Q00024Q00263Q00034Q00263Q00064Q001D000900083Q00122Q000A000C3Q00122Q000B000D6Q0009000B000200104Q000B00094Q000900083Q00122Q000A000F3Q00122Q000B00106Q0009000B000200104Q000E00092Q001D000900083Q00122Q000A00123Q00122Q000B00136Q0009000B000200104Q001100094Q000900083Q00122Q000A00153Q00122Q000B00166Q0009000B000200104Q001400092Q001D000900083Q00122Q000A00183Q00122Q000B00196Q0009000B000200104Q001700094Q000900083Q00122Q000A001B3Q00122Q000B001C6Q0009000B000200104Q001A00090012170009001D4Q0028000A000B3Q00261F000900460001001E00040A3Q0046000100261F000A003E0001001E00040A3Q003E00012Q0026000C000B4Q000D000C0001000100040A3Q004C000100261F000A00390001001D00040A3Q003900012Q0028000B000B3Q000618000B0001000100012Q00267Q001217000A001E3Q00040A3Q0039000100040A3Q004C000100261F000900370001001D00040A3Q00370001001217000A001D4Q0028000B000B3Q0012170009001E3Q00040A3Q003700012Q00273Q00013Q00023Q00023Q00026Q00F03F026Q00704002264Q000200025Q00122Q000300016Q00045Q00122Q000500013Q00042Q0003002100012Q002D00076Q0013000800026Q000900016Q000A00026Q000B00036Q000C00046Q000D8Q000E00063Q00202Q000F000600014Q000C000F6Q000B3Q00024Q000C00036Q000D00046Q000E00016Q000F00016Q000F0006000F00102Q000F0001000F4Q001000016Q00100006001000102Q00100001001000202Q0010001000014Q000D00106Q000C8Q000A3Q000200202Q000A000A00024Q0009000A6Q00073Q00010004140003000500012Q002D000300054Q0026000400024Q0020000300044Q002400036Q00273Q00017Q00103Q00028Q00026Q00F03F03053Q00706169727303043Q0067616D6503093Q00576F726B7370616365030E3Q0047657444657363656E64616E74732Q033Q00497341026Q00084003073Q0044657374726F7903053Q007072696E74026Q001440030B3Q0047657446752Q6C4E616D65026Q002440026Q002840026Q003140026Q00334000603Q0012173Q00013Q00261F3Q00210001000200040A3Q00210001001229000100033Q001201000200043Q00202Q00020002000500202Q0002000200064Q000200036Q00013Q000300044Q001E000100202Q0006000500072Q002D00085Q0020190008000800082Q000800060008000200062F0006001E00013Q00040A3Q001E0001001217000600013Q00261F000600110001000100040A3Q0011000100202Q0007000500092Q001E00070002000100122Q0007000A6Q00085Q00202Q00080008000B00202Q00090005000C4Q0009000200024Q0008000800094Q00070002000100044Q001E000100040A3Q0011000100061A0001000A0001000200040A3Q000A000100040A3Q005F000100261F3Q00010001000100040A3Q00010001001229000100033Q001201000200043Q00202Q00020002000500202Q0002000200064Q000200036Q00013Q000300044Q003E000100202Q0006000500072Q002D00085Q00201900080008000D2Q000800060008000200062F0006003E00013Q00040A3Q003E0001001217000600013Q00261F000600310001000100040A3Q0031000100202Q0007000500092Q001E00070002000100122Q0007000A6Q00085Q00202Q00080008000E00202Q00090005000C4Q0009000200024Q0008000800094Q00070002000100044Q003E000100040A3Q0031000100061A0001002A0001000200040A3Q002A0001001229000100033Q001201000200043Q00202Q00020002000500202Q0002000200064Q000200036Q00013Q000300044Q005B000100202Q0006000500072Q002D00085Q00201900080008000F2Q000800060008000200062F0006005B00013Q00040A3Q005B0001001217000600013Q00261F0006004E0001000100040A3Q004E000100202Q0007000500092Q001E00070002000100122Q0007000A6Q00085Q00202Q00080008001000202Q00090005000C4Q0009000200024Q0008000800094Q00070002000100044Q005B000100040A3Q004E000100061A000100470001000200040A3Q004700010012173Q00023Q00040A3Q000100012Q00273Q00017Q00",v9(),...);