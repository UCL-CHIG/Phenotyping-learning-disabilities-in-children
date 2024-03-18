****CONCATENATE HES AND ONS VARIABLES RESPECTIVELY - THIS REQUIRES FEWER LOOPS

gen diag_concat=diag_01 + "."+diag_02 + "." + diag_03 + "."+ diag_04 + "."+ diag_05 + "."+ diag_06 + "."+ diag_07 + "."+ diag_08 + "."+ diag_09 + "."+ diag_10 + "."+ diag_11 + "."+ diag_12 + "."+ diag_13 + "."+ diag_14 + "."+ diag_15 + "."+ diag_16 + "."+ diag_17 + "."+ diag_18 + "."+ diag_19 + "."+ diag_20

timer clear 3

timer on 3


set more off
/* 1) Identify qualifying admissions through diagnosis codes */

//Mental health/behavioural disorders
local icd1 "E244 F000 F001 F002 F009 F010 F011 F012 F013 F018 F019 F028 F03 F04 F050 F051 F058 F059 F060 F061 F062 F063 F064 F065 F066 F067 F068 F069 F070 F071 F072 F078 F079 F09 F100 F101 F102 F103 F104 F105 F106 F107 F108 F109 F110 F111 F112 F113 F114 F115 F116 F117 F118 F119 F120 F121 F122 F123 F124 F125 F126 F127 F128 F129 F130 F131 F132 F133 F134 F135 F136 F137 F138 F139 F140 F141 F142 F143 F144 F145 F146 F147 F148 F149 F150 F151 F152 F153 F154 F155 F156 F157 F158 F159 F160 F161 F162 F163 F164 F165 F166 F167 F168 F169 F170 F171 F172 F173 F174 F175 F176 F177 F178 F179 F180 F181 F182 F183 F184 F185 F186 F187 F188 F189 F190 F191 F192 F193 F194 F195 F196 F197 F198 F199 F200 F201 F202 F203 F204 F205 F206 F208 F209 F21 F220 F228 F229 F230 F231 F232 F233 F238 F239 F24 F250 F251 F252 F258 F259 F28 F29 F300 F301 F302 F308 F309 F310 F311 F312 F313 F314 F315 F316 F317 F318 F319 F320 F321 F322 F323 F328 F329 F330 F331 F332 F333 F334 F338 F339 F340 F341 F348 F349 F380 F381 F388 F39 F400 F401 F402 F408 F409 F410 F411 F412 F413 F418 F419 F420 F421 F422 F428 F429 F430 F431 F432 F438 F439 F440 F441 F442 F443 F444 F445 F446 F447 F448 F449 F450 F451 F452 F453 F454 F458 F459 F480 F481 F488 F489 F500 F501 F502 F503 F504 F505 F508 F509 F530 F531 F538 F539 F54 F600 F601 F602 F603 F604 F605 F606 F607 F608 F609 F61 F620 F621 F628 F629 F630 F631 F632 F633 F638 F639 F640 F641 F642 F648 F649 F650 F651 F652 F653 F654 F655 F656 F658 F659 F660 F661 F662 F668 F669 F680 F681 F688 F69 F700 F701 F708 F709 F710 F711 F718 F719 F720 F721 F728 F729 F730 F731 F738 F739 F780 F781 F788 F789 F790 F791 F798 F799 F800 F801 F802 F808 F809 F810 F811 F812 F813 F818 F819 F82 F83 F840 F841 F842 F843 F844 F845 F848 F849 F88 F89 F900 F901 F908 F909 F910 F911 F912 F913 F918 F919 F920 F928 F929 F930 F931 F932 F933 F938 F939 F940 F941 F942 F948 F949 F950 F951 F952 F958 F959 F980 F981 F982 F983 F984 F985 F986 F988 F989 G312 G405 G621 G720 G721 I426 K292 K700 K701 K702 K703 K704 K709 K852 K853 K860 O354 X60 X61 X62 X63 X64 X65 X66 X67 X68 X69 X70 X71 X72 X73 X74 X75 X76 X77 X78 X79 X80 X81 X82 X83 X84 Y470 Y471 Y472 Y473 Y474 Y475 Y478 Y479 Y490 Y491 Y492 Y493 Y494 Y495 Y496 Y497 Y498 Y499 Y870 Z502 Z503 Z714 Z715 Z864 Z865 Z915"
local icd1_sev "F55 F59 F99 G240 R781 R782 R783 R784 R785 Z093 Z504 Z722 Z914" 
local icd1_sev2 "Y10 Y11 Y12 Y13 Y14 Y15 Y16 Y17 Y18 Y19 Y20 Y21 Y22 Y23 Y24 Y25 Y26 Y27 Y28 Y29 Y30 Y31 Y32 Y33 Y34 Y872"

//Cancer/blood disorders
local icd2 "C000 C001 C002 C003 C004 C005 C006 C008 C009 C01 C020 C021 C022 C023 C024 C028 C029 C030 C031 C039 C040 C041 C048 C049 C050 C051 C052 C058 C059 C060 C061 C062 C068 C069 C07 C080 C081 C088 C089 C090 C091 C098 C099 C100 C101 C102 C103 C104 C108 C109 C110 C111 C112 C113 C118 C119 C12 C130 C131 C132 C138 C139 C140 C142 C148 C150 C151 C152 C153 C154 C155 C158 C159 C160 C161 C162 C163 C164 C165 C166 C168 C169 C170 C171 C172 C173 C178 C179 C180 C181 C182 C183 C184 C185 C186 C187 C188 C189 C19 C20 C210 C211 C212 C218 C220 C221 C222 C223 C224 C227 C229 C23 C240 C241 C248 C249 C250 C251 C252 C253 C254 C257 C258 C259 C260 C261 C268 C269 C300 C301 C310 C311 C312 C313 C318 C319 C320 C321 C322 C323 C328 C329 C33 C340 C341 C342 C343 C348 C349 C37 C380 C381 C382 C383 C384 C388 C390 C398 C399 C400 C401 C402 C403 C408 C409 C410 C411 C412 C413 C414 C418 C419 C430 C431 C432 C433 C434 C435 C436 C437 C438 C439 C440 C441 C442 C443 C444 C445 C446 C447 C448 C449 C450 C451 C452 C457 C459 C460 C461 C462 C463 C467 C468 C469 C470 C471 C472 C473 C474 C475 C476 C478 C479 C480 C481 C482 C488 C490 C491 C492 C493 C494 C495 C496 C498 C499 C500 C501 C502 C503 C504 C505 C506 C508 C509 C510 C511 C512 C518 C519 C52 C530 C531 C538 C539 C540 C541 C542 C543 C548 C549 C55 C56 C570 C571 C572 C573 C574 C577 C578 C579 C58 C600 C601 C602 C608 C609 C61 C620 C621 C629 C630 C631 C632 C637 C638 C639 C64 C65 C66 C670 C671 C672 C673 C674 C675 C676 C677 C678 C679 C680 C681 C688 C689 C690 C691 C692 C693 C694 C695 C696 C698 C699 C700 C701 C709 C710 C711 C712 C713 C714 C715 C716 C717 C718 C719 C720 C721 C722 C723 C724 C725 C728 C729 C73 C740 C741 C749 C750 C751 C752 C753 C754 C755 C758 C759 C760 C761 C762 C763 C764 C765 C767 C768 C770 C771 C772 C773 C774 C775 C778 C779 C780 C781 C782 C783 C784 C785 C786 C787 C788 C790 C791 C792 C793 C794 C795 C796 C797 C798 C80 C810 C811 C812 C813 C817 C819 C820 C821 C822 C827 C829 C830 C831 C832 C833 C834 C835 C836 C837 C838 C839 C840 C841 C842 C843 C844 C845 C850 C851 C857 C859 C860 C861 C862 C863 C864 C865 C866 C880 C881 C882 C883 C887 C889 C900 C901 C902 C903 C910 C911 C912 C913 C914 C915 C917 C919 C920 C921 C922 C923 C924 C925 C927 C929 C930 C931 C932 C937 C939 C940 C941 C942 C943 C944 C945 C947 C950 C951 C952 C957 C959 C960 C961 C962 C963 C967 C969 C97 D000 D001 D002 D010 D011 D012 D013 D014 D015 D017 D019 D020 D021 D022 D023 D024 D050 D051 D057 D059 D060 D061 D067 D069 D070 D071 D072 D073 D074 D075 D076 D090 D091 D092 D093 D097 D099 D120 D121 D122 D123 D124 D125 D126 D127 D128 D129 D130 D131 D132 D133 D134 D135 D136 D137 D139 D141 D142 D143 D144 D150 D151 D152 D157 D159 D200 D201 D320 D321 D329 D330 D331 D332 D333 D334 D337 D339 D34 D350 D351 D352 D353 D354 D355 D356 D357 D358 D359 D370 D371 D372 D373 D374 D375 D376 D377 D379 D380 D381 D382 D383 D384 D385 D386 D390 D391 D392 D397 D399 D400 D401 D407 D409 D41 D410 D411 D412 D413 D414 D417 D419 D420 D421 D429 D430 D431 D432 D433 D434 D437 D439 D440 D441 D442 D443 D444 D445 D446 D447 D448 D449 D45 D460 D461 D462 D463 D464 D467 D469 D470 D471 D472 D473 D477 D479 D480 D481 D482 D483 D484 D485 D486 D487 D489 D560 D561 D562 D564 D568 D569 D570 D571 D572 D578 D580 D581 D582 D588 D589 D610 D619 D630 D66 D67 D680 D681 D682 D684 D685 D686 D688 D689 D690 D691 D692 D693 D694 D695 D696 D698 D699 D70 D71 D720 D721 D728 D729 D730 D731 D732 D733 D734 D735 D738 D739 D740 D748 D749 D750 D751 D752 D758 D759 D760 D761 D762 D763 D800 D801 D802 D803 D804 D805 D806 D807 D808 D809 D810 D811 D812 D813 D814 D815 D816 D817 D818 D819 D820 D821 D822 D823 D824 D828 D829 D830 D831 D832 D838 D839 D840 D841 D848 D849 E340 E883 G130 G131 G532 G533 G550 G631 G731 G732 G941 M360 M361 M362 M363 M364 M495 M820 M904 M906 M907 N081 N082 N161 Q890 Y431 Y432 Y433 Y842 Z080 Z081 Z082 Z087 Z088 Z089 Z510 Z511 Z512 Z541 Z542 Z850 Z851 Z852 Z853 Z854 Z855 Z856 Z857 Z858 Z859 Z860 Z862 Z923"
local icd2_sev "D500 D501 D508 D509 D640 D641 D642 D643 D644 D648 D649"

//Chronic infections
local icd3 "A150 A151 A152 A153 A154 A155 A156 A157 A158 A159 A160 A161 A162 A163 A164 A165 A167 A168 A169 A170 A171 A178 A179 A180 A181 A182 A183 A184 A185 A186 A187 A188 A190 A191 A192 A198 A199 A500 A501 A502 A503 A504 A505 A506 A507 A509 A810 A811 A812 A818 A819 B180 B181 B182 B188 B189 B200 B201 B202 B203 B204 B205 B206 B207 B208 B209 B210 B211 B212 B213 B217 B218 B219 B220 B221 B222 B227 B230 B231 B232 B238 B24 B371 B375 B376 B377 B381 B391 B401 B440 B447 B450 B451 B452 B453 B457 B458 B459 B460 B461 B462 B463 B464 B465 B468 B469 B487 B500 B510 B520 B550 B551 B552 B559 B572 B573 B574 B575 B580 B59 B670 B671 B672 B673 B674 B675 B676 B677 B678 B679 B690 B691 B698 B699 B73 B740 B741 B742 B743 B744 B748 B749 B787 B900 B901 B902 B908 B909 B91 B92 B940 B941 B942 B948 B949 E350 F021 F024 K230 K231 K673 K930 K931 M000 M001 M002 M008 M009 M011 M490 N330 P350 P351 P352 P358 P359 P370 P371 R75 Z21"
local icd3_sev "B508 B518 B528"
 
//Respiratory disoders
local icd4 "E840 E841 E848 E849 G473 J410 J411 J418 J42 J430 J431 J432 J438 J439 J440 J441 J448 J449 J450 J451 J458 J459 J46 J47 J60 J61 J620 J628 J630 J631 J632 J633 J634 J635 J638 J64 J65 J660 J661 J662 J668 J670 J671 J672 J673 J674 J675 J676 J677 J678 J679 J680 J681 J682 J683 J684 J688 J689 J690 J691 J698 J700 J701 J702 J703 J704 J708 J709 J80 J81 J82 J840 J841 J848 J849 J850 J851 J852 J853 J860 J869 J961 J980 J981 J982 J983 J984 J985 J986 J988 J989 P270 P271 P278 P279 P75 Q300 Q301 Q302 Q303 Q308 Q309 Q310 Q311 Q312 Q313 Q314 Q315 Q318 Q319 Q320 Q321 Q322 Q323 Q324 Q330 Q331 Q332 Q333 Q334 Q335 Q336 Q338 Q339 Q340 Q341 Q348 Q349 Q351 Q353 Q355 Q356 Q357 Q359 Q360 Q361 Q369 Q370 Q371 Q372 Q373 Q374 Q375 Q378 Q379 Q790 Y556 Z430 Z930 Z942"
*local icd4_sev "S170 S178 S179 S270 S271 S272 S273 S274 S275 S276 S277 S278 S279 S280 S281 T270 T271 T272 T273 T274 T275 T276 T277 T914"

//Metabolic/endocrine/digestive/renal/genitourinary disorders
local icd5 "D550 D551 D552 D553 D558 D559 D638 E000 E001 E002 E009 E030 E031 E071 E100 E101 E102 E103 E104 E105 E106 E107 E108 E109 E110 E111 E112 E113 E114 E115 E116 E117 E118 E119 E120 E121 E122 E123 E124 E125 E126 E127 E128 E129 E130 E131 E132 E133 E134 E135 E136 E137 E138 E139 E140 E141 E142 E143 E144 E145 E146 E147 E148 E149 E220 E230 E250 E258 E259 E268 E291 E310 E311 E318 E319 E341 E342 E345 E348 E660 E661 E662 E668 E669 E700 E701 E702 E703 E708 E709 E710 E711 E712 E713 E720 E721 E722 E723 E724 E725 E728 E729 E740 E741 E742 E743 E744 E748 E749 E750 E751 E752 E753 E754 E755 E756 E760 E761 E762 E763 E768 E769 E770 E771 E778 E779 E780 E781 E782 E783 E784 E785 E786 E788 E789 E791 E798 E799 E800 E801 E802 E803 E805 E807 E830 E831 E832 E833 E834 E835 E838 E839 E850 E851 E852 E853 E854 E858 E859 E880 E881 E888 E889 G132 G590 G632 G633 G638 G730 G735 G736 G990 G998 I688 I792 K20 K210 K220 K221 K222 K223 K224 K225 K226 K228 K229 K238 K250 K251 K252 K253 K254 K255 K256 K257 K259 K260 K261 K262 K263 K264 K265 K266 K267 K269 K270 K271 K272 K273 K274 K275 K276 K277 K279 K280 K281 K282 K283 K284 K285 K286 K287 K289 K290 K291 K293 K294 K295 K296 K297 K298 K299 K310 K311 K312 K313 K314 K315 K316 K317 K318 K319 K500 K501 K508 K509 K510 K511 K512 K513 K514 K515 K518 K519 K520 K521 K522 K528 K529 K550 K551 K552 K558 K559 K570 K571 K572 K573 K574 K575 K578 K579 K592 K630 K631 K632 K633 K660 K661 K668 K669 K720 K721 K729 K730 K731 K732 K738 K739 K740 K741 K742 K743 K744 K745 K746 K750 K751 K752 K753 K754 K758 K759 K760 K761 K762 K763 K764 K765 K766 K767 K768 K769 K800 K801 K802 K803 K804 K805 K808 K810 K811 K818 K819 K820 K821 K822 K823 K824 K828 K829 K830 K831 K832 K833 K834 K835 K838 K839 K850 K851 K858 K859 K861 K862 K863 K868 K869 K870 K900 K901 K902 K903 K904 K908 K909 L990 M074 M075 M091 M092 M142 M143 M144 M145 M908 N000 N001 N002 N003 N004 N005 N006 N007 N008 N009 N010 N011 N012 N013 N014 N015 N016 N017 N018 N019 N020 N021 N022 N023 N024 N025 N026 N027 N028 N029 N030 N031 N032 N033 N034 N035 N036 N037 N038 N039 N040 N041 N042 N043 N044 N045 N046 N047 N048 N049 N050 N051 N052 N053 N054 N055 N056 N057 N058 N059 N070 N071 N072 N073 N074 N075 N076 N077 N078 N079 N083 N084 N110 N111 N118 N119 N12 N130 N131 N132 N133 N134 N135 N136 N137 N138 N139 N140 N141 N142 N143 N144 N150 N151 N158 N159 N160 N162 N163 N164 N165 N168 N180 N188 N189 N19 N200 N201 N202 N209 N210 N211 N218 N219 N220 N228 N23 N250 N251 N258 N259 N26 N280 N281 N288 N289 N290 N291 N298 N310 N311 N312 N318 N319 N320 N321 N322 N323 N324 N328 N329 N338 N350 N351 N358 N359 N360 N361 N362 N363 N368 N369 N391 N393 N394 N40 N410 N411 N412 N413 N418 N419 N420 N421 N422 N428 N429 N700 N701 N709 N710 N711 N719 N72 N730 N731 N732 N733 N734 N735 N736 N738 N739 N740 N741 N742 N743 N744 N748 N800 N801 N802 N803 N804 N805 N806 N808 N809 N810 N811 N812 N813 N814 N815 N816 N818 N819 N820 N821 N822 N823 N824 N825 N828 N829 N850 N851 N852 N853 N854 N855 N856 N857 N858 N859 N870 N871 N872 N879 N880 N881 N882 N883 N884 N888 N889 O240 O241 O242 O243 O244 O249 P960 Q380 Q383 Q384 Q386 Q387 Q388 Q390 Q391 Q392 Q393 Q394 Q395 Q396 Q398 Q399 Q402 Q403 Q408 Q409 Q410 Q411 Q412 Q418 Q419 Q420 Q421 Q422 Q423 Q428 Q429 Q431 Q433 Q434 Q435 Q436 Q437 Q439 Q440 Q441 Q442 Q443 Q444 Q445 Q446 Q447 Q450 Q451 Q452 Q453 Q458 Q459 Q500 Q510 Q511 Q512 Q513 Q514 Q515 Q516 Q517 Q518 Q519 Q520 Q521 Q522 Q524 Q540 Q541 Q542 Q543 Q548 Q549 Q550 Q555 Q560 Q561 Q562 Q563 Q564 Q601 Q602 Q604 Q605 Q606 Q610 Q611 Q612 Q613 Q614 Q615 Q618 Q619 Q620 Q621 Q622 Q623 Q624 Q625 Q626 Q628 Q630 Q631 Q632 Q638 Q639 Q640 Q641 Q642 Q643 Q644 Q645 Q646 Q647 Q648 Q649 Q792 Q793 Q794 Q795 Q878 Q891 Q892 T824 T831 T832 T834 T835 T836 T838 T839 T855 T861 T864 Y421 Y423 Y602 Y612 Y622 Y841 Z432 Z433 Z434 Z465 Z490 Z491 Z492 Z863 Z903 Z904 Z932 Z933 Z934 Z935 Z936 Z938 Z940 Z992"
local icd5_sev "E882 N86 N920 N921 N922 N923 N924 N925 N926"
*S361 S362 S363 S364 S365 S366 S367 S368 S369 S370 S371 S372 S373 S374 S375 S376 S377 S378 S379 S380 S381 S382 S383 S396 S397 S360 T065 T280 T281 T282 T283 T284 T285 T286 T287 T288 T289 T915

//Musculoskeletal/skin disorders
local icd6 "G551 G552 G553 G635 G636 G737 J990 J991 L100 L101 L102 L103 L104 L105 L108 L109 L110 L118 L119 L120 L121 L122 L123 L128 L129 L130 L131 L138 L139 L14 L280 L281 L282 L400 L401 L402 L403 L404 L405 L408 L409 L410 L411 L412 L413 L414 L415 L418 L419 L42 L430 L431 L432 L433 L438 L439 L440 L441 L442 L443 L444 L448 L449 L45 L570 L571 L572 L573 L574 L575 L578 L579 L581 L590 L598 L599 L620 L870 L871 L872 L878 L879 L88 L900 L901 L902 L903 L904 L905 L906 L908 L909 L920 L921 L922 L923 L928 L929 L930 L931 L932 L950 L951 L958 L959 L985 M050 M051 M052 M053 M058 M059 M060 M061 M062 M063 M064 M068 M069 M070 M071 M072 M073 M076 M080 M081 M082 M083 M084 M088 M089 M090 M098 M100 M101 M102 M103 M104 M109 M110 M111 M112 M118 M119 M120 M121 M122 M123 M124 M125 M128 M130 M131 M138 M139 M140 M146 M148 M300 M301 M302 M303 M308 M310 M311 M312 M313 M314 M315 M316 M318 M319 M320 M321 M328 M329 M330 M331 M332 M339 M340 M341 M342 M348 M349 M350 M351 M352 M353 M354 M355 M356 M357 M358 M359 M400 M401 M402 M403 M404 M405 M410 M411 M412 M413 M414 M415 M418 M419 M420 M421 M429 M430 M431 M432 M433 M434 M435 M436 M438 M439 M45 M460 M461 M462 M463 M464 M465 M468 M469 M470 M471 M472 M478 M479 M480 M481 M482 M483 M484 M485 M488 M489 M500 M501 M502 M503 M508 M509 M510 M511 M512 M513 M514 M518 M519 M530 M531 M532 M533 M538 M539 M540 M541 M542 M543 M544 M545 M546 M548 M549 M600 M601 M602 M608 M609 M610 M611 M612 M613 M614 M615 M619 M620 M621 M622 M623 M624 M625 M626 M628 M629 M638 M801 M802 M803 M804 M805 M808 M809 M811 M812 M813 M814 M815 M816 M818 M819 M821 M828 M840 M841 M842 M848 M849 M850 M851 M852 M853 M854 M855 M856 M858 M859 M863 M864 M865 M866 M890 M891 M892 M893 M894 M895 M896 M898 M899 M900 M910 M911 M912 M913 M918 M919 M920 M921 M922 M923 M924 M925 M926 M927 M928 M929 M930 M931 M932 M938 M939 M940 M941 M942 M943 M948 M949 N085 Q188 Q650 Q651 Q652 Q658 Q659 Q675 Q682 Q710 Q711 Q712 Q713 Q714 Q715 Q716 Q718 Q719 Q720 Q721 Q722 Q723 Q724 Q725 Q726 Q727 Q728 Q729 Q730 Q731 Q738 Q740 Q741 Q742 Q743 Q748 Q749 Q753 Q754 Q755 Q758 Q759 Q761 Q762 Q763 Q764 Q770 Q771 Q772 Q773 Q774 Q775 Q776 Q777 Q778 Q779 Q780 Q781 Q782 Q783 Q784 Q785 Q786 Q788 Q789 Q796 Q798 Q800 Q801 Q802 Q803 Q804 Q808 Q809 Q810 Q811 Q812 Q818 Q819 Q820 Q821 Q822 Q823 Q824 Q829 Q862 Q870 Q871 Q872 Q873 Q874 Q875 Q894 Q897 Q898 Q899 T873 T874 T875 T876 Y454 Y835 Z891 Z892 Z895 Z896 Z897 Z898 Z971"
local icd6_sev "Q683 Q684 Q685"
*S130 S131 S132 S133 S134 S135 S136 S220 S221 S222 S225 S230 S231 S232 S233 S234 S235 S320 S321 S322 S323 S324 S325 S327 S328 S330 S331 S332 S333 S334 S335 S336 S337 S683 S684 S688 S770  S771 S772 S780 S781 S789 S870 S878 S880 S881 S889 S970 S971 S978 S980 S982 S983 S984
*T020 T021 T022 T023 T024 T025 T026 T027 T028 T029 T040 T041 T042 T043 T044 T047 T048 T049 T050 T051 T052 T053 T054 T055 T056 T058 T059 T203 T207 T213 T217 T223 T227 T232 T233 T236 T237 T243 T247 T252 T253 T256 T257 T293 T297 T303 T307 T312 T313 T314 T315 T316 T317 T318 T319 T322 T323 T324 T325 T326 T327 T328 T329 T912 T918 T926 T931 T934 T936 T940 T941 T950 T951 T954 T958 T959

//Neurological disorders
local icd7 "F022 F023 F803 G000 G001 G002 G003 G008 G009 G01 G020 G021 G028 G030 G031 G032 G038 G039 G040 G041 G042 G048 G049 G050 G051 G052 G058 G060 G061 G062 G07 G08 G09 G10 G110 G111 G112 G113 G114 G118 G119 G120 G121 G122 G128 G129 G138 G14 G20 G210 G211 G212 G213 G218 G219 G22 G230 G231 G232 G238 G239 G241 G242 G243 G244 G245 G248 G249 G250 G251 G252 G253 G254 G255 G256 G258 G259 G26 G300 G301 G308 G309 G310 G311 G318 G319 G320 G328 G35 G360 G361 G368 G369 G370 G371 G372 G373 G374 G375 G378 G379 G400 G401 G402 G403 G404 G406 G407 G408 G409 G410 G411 G412 G418 G419 G430 G431 G432 G433 G438 G439 G440 G441 G442 G443 G444 G448 G450 G451 G452 G453 G454 G458 G459 G460 G461 G462 G463 G464 G465 G466 G467 G468 G470 G471 G472 G474 G478 G479 G500 G501 G508 G509 G510 G511 G512 G513 G514 G518 G519 G520 G521 G522 G523 G527 G528 G529 G530 G531 G538 G540 G541 G542 G543 G544 G545 G546 G547 G548 G549 G558 G560 G561 G562 G563 G564 G568 G569 G570 G571 G572 G573 G574 G575 G576 G578 G579 G580 G587 G588 G589 G598 G600 G601 G602 G603 G608 G609 G610 G611 G618 G619 G620 G622 G628 G629 G64 G700 G701 G702 G708 G709 G710 G711 G712 G713 G718 G719 G722 G723 G724 G728 G729 G733 G800 G801 G802 G803 G804 G808 G809 G810 G811 G819 G82 G820 G821 G822 G823 G824 G825 G830 G831 G832 G833 G834 G838 G839 G900 G901 G902 G903 G908 G909 G910 G911 G912 G913 G918 G919 G92 G930 G931 G932 G933 G934 G935 G936 G937 G938 G939 G942 G948 G950 G951 G952 G958 G959 G960 G961 G968 G969 G98 G991 G992 H051 H052 H053 H054 H055 H058 H059 H133 H170 H171 H178 H179 H180 H181 H182 H183 H184 H185 H186 H187 H188 H189 H193 H198 H210 H211 H212 H213 H214 H215 H218 H219 H260 H261 H262 H263 H264 H268 H269 H270 H271 H278 H279 H280 H281 H282 H310 H311 H312 H313 H314 H318 H319 H328 H330 H331 H332 H333 H334 H335 H340 H341 H342 H348 H349 H350 H351 H352 H353 H354 H355 H356 H357 H358 H359 H400 H401 H402 H403 H404 H405 H406 H408 H409 H420 H430 H431 H432 H433 H438 H439 H440 H441 H442 H443 H444 H445 H446 H447 H448 H449 H470 H471 H472 H473 H474 H475 H476 H477 H540 H541 H542 H544 H602 H652 H653 H654 H661 H662 H663 H690 H701 H731 H740 H741 H742 H743 H750 H800 H801 H802 H808 H809 H810 H814 H830 H832 H900 H903 H905 H906 H910 H911 H912 H913 H918 H919 I600 I601 I602 I603 I604 I605 I606 I607 I608 I609 I610 I611 I612 I613 I614 I615 I616 I618 I619 I620 I621 I629 I630 I631 I632 I633 I634 I635 I636 I638 I639 I64 I650 I651 I652 I653 I658 I659 I660 I661 I662 I663 I664 I668 I669 I670 I671 I672 I673 I674 I675 I676 I677 I678 I679 I680 I682 I690 I691 I692 I693 I694 I698 I720 I725 P100 P101 P102 P103 P104 P108 P109 P210 P520 P521 P522 P523 P524 P525 P526 P528 P529 P570 P578 P579 P90 P911 P912 P916 Q000 Q001 Q002 Q010 Q011 Q012 Q018 Q019 Q02 Q030 Q031 Q038 Q039 Q040 Q041 Q042 Q043 Q044 Q045 Q046 Q048 Q049 Q050 Q051 Q052 Q053 Q054 Q055 Q056 Q057 Q058 Q059 Q060 Q061 Q062 Q063 Q064 Q068 Q069 Q070 Q078 Q079 Q104 Q107 Q110 Q111 Q112 Q113 Q120 Q121 Q122 Q123 Q124 Q128 Q129 Q130 Q131 Q132 Q133 Q134 Q138 Q139 Q140 Q141 Q142 Q143 Q148 Q149 Q150 Q158 Q159 Q160 Q161 Q162 Q163 Q164 Q165 Q169 Q750 Q751 Q850 Q851 Q858 Q859 Q860 Q861 Q868 Q900 Q901 Q902 Q909 Q910 Q911 Q912 Q913 Q914 Q915 Q916 Q917 Q920 Q921 Q922 Q923 Q924 Q925 Q926 Q927 Q928 Q929 Q930 Q931 Q932 Q933 Q934 Q935 Q936 Q937 Q938 Q939 Q952 Q953 Q970 Q971 Q972 Q973 Q978 Q979 Q990 Q991 Q992 Q998 Q999 R568 T850 T851 T852 T853 Y460 Y461 Y462 Y463 Y464 Y465 Y466 Y467 Y468 Z442 Z453 Z982"
*local icd7_sev "S050 S051 S052 S053 S054 S055 S056 S057 S058 S059 S060 S061 S062 S063 S064 S065 S066 S067 S068 S069 S070 S071 S078 S079 S080 S081 S088 S089 S120 S121 S122 S127 S128 S129 S140 S141 S142 S143 S144 S145 S146 S240 S241 S242 S243 S244 S245 S246 S340 S341 S342 S343 S344 S345 S346 S348 S440 S441 S442 S443 S444 S445 S447 S448 S449 S540 S541 S542 S543 S547 S548 S549 S640 S641 S642 S643 S644 S647 S648 S649 S740 S741 S742 S747 S748 S749 S840 S841 S842 S847 S848 S849 S940 S941 S942 S943 S947 S948 S949 T060 T061 T062 T260 T261 T262 T263 T264 T265 T266 T267 T268 T269 T904 T905 T911 T913 T924"

//Cardiovascular disorders
local icd8 "I431 I528 M036 N088 Q200 Q201 Q202 Q203 Q204 Q205 Q206 Q208 Q209 Q210 Q211 Q212 Q213 Q214 Q218 Q219 Q220 Q221 Q222 Q223 Q224 Q225 Q226 Q228 Q229 Q230 Q231 Q232 Q233 Q234 Q238 Q239 Q240 Q241 Q242 Q243 Q244 Q245 Q246 Q248 Q249 Q250 Q251 Q252 Q253 Q254 Q255 Q256 Q257 Q258 Q259 Q260 Q261 Q262 Q263 Q264 Q265 Q266 Q268 Q269 Q270 Q271 Q272 Q273 Q274 Q278 Q279 Q280 Q281 Q282 Q283 Q288 Q289 Q893 T820 T821 T822 T823 T825 T826 T827 T828 T829 T862 Y605 Y615 Y625 Y840 Z450 Z500 Z941 Z950 Z951 Z952 Z953 Z954 Z955 Z958 Z959"
local icd8_sev "I00 I010 I011 I012 I018 I019 I020 I029 I050 I051 I052 I058 I059 I060 I061 I062 I068 I069 I070 I071 I072 I078 I079 I080 I081 I082 I083 I088 I089 I090 I091 I092 I098 I099 I10 I110 I119 I120 I129 I130 I131 I132 I139 I15 I150 I151 I152 I158 I159 I200 I201 I208 I209 I210 I211 I212 I213 I214 I219 I220 I221 I228 I229 I230 I231 I232 I233 I234 I235 I236 I238 I240 I241 I248 I249 I250 I251 I252 I253 I254 I255 I256 I258 I259 I260 I269 I270 I271 I272 I278 I279 I280 I281 I288 I289 I310 I311 I312 I313 I318 I319 I320 I321 I328 I330 I339 I340 I341 I342 I348 I349 I350 I351 I352 I358 I359 I360 I361 I362 I368 I369 I370 I371 I372 I378 I379 I38 I390 I391 I392 I393 I394 I398 I410 I411 I412 I418 I420 I421 I422 I423 I424 I425 I427 I428 I429 I430 I432 I438 I441 I442 I443 I444 I445 I446 I447 I451 I452 I453 I454 I455 I456 I458 I459 I460 I461 I469 I470 I471 I472 I479 I48 I490 I491 I492 I493 I494 I495 I498 I499 I500 I501 I509 I510 I511 I512 I513 I514 I515 I516 I517 I518 I519 I700 I701 I702 I708 I709 I710 I711 I712 I713 I714 I715 I716 I718 I719 I721 I722 I723 I724 I728 I729 I730 I731 I738 I739 I740 I741 I742 I743 I744 I745 I748 I749 I770 I771 I772 I773 I774 I775 I776 I778 I779 I790 I791 I798 I81 I820 I821 I822 I823 I828 I829 I980 I981 I982 I983 I988 I99 S260 S268 S269"

***Adverse social circumstances

*local icd9 "T73 T74 X85 X86 X87 X88 X89 X90 X91 X92 X93 X94 X95 X96 X97 X98 X99 Y01 Y02 Y03 Y04 Y05 Y06 Y07 Y08 Y09 Z33 Z34 Z35 Z36 Z39 Z55 Z56 Z59 Z60 Z61 Z62 Z63 Z65 Z74 Z81 P961 Z045 Z048 Z321 Z588 Z589 Z644 Z761 Z762 Z728 Z918"

****Indicate whether a particular episode contains the relvant code

forvalues k = 1/8 {
	***HES - by group
	capture drop ucc_group_hes`k'
	gen ucc_group_hes`k'=0
	foreach j of local icd`k' {
		replace ucc_group_hes`k'=1 if strpos(diag_concat,"`j'")>0
	} 			
}

label var ucc_group_hes1 "Mental health/behavioural disorders"
label var ucc_group_hes2 "Cancer/blood disorders"
label var ucc_group_hes3 "Chronic infections"
label var ucc_group_hes4 "Respiratory disoders"
label var ucc_group_hes5 "Metabolic/endocrine/digestive/renal/genitourinary disorders"
label var ucc_group_hes6 "Musculoskeletal/skin disorders"
label var ucc_group_hes7 "Neurological disorders"
label var ucc_group_hes8 "Cardiovascular disorders"
*label var ucc_group_hes9 "Adverse social circumstances"

/*
forvalues k = 1/8 {
	foreach j of local icd`k'_sev {		
		 replace cc_group_hes`k'=1 if strpos(diag_concat, "`j'")>0  & los>=3	
				 
	}
	}
 *replace cc_group_hes`k'=1 if strpos(diag_concat, "`j'")>0  & lastdis-disd>30 & los>=3	
 
***Include the code which has an extra severity criterion - poisoning for mental health ****
foreach j of local icd1_sev2 {	
	replace cc_group_hes1=1 if strpos(diag_concat, "`j'")>0 & startage1>=10 
	replace cc_group_hes9=1 if strpos(diag_concat, "`j'")>0 & startage1<10 	
	}
*/
timer off 3
timer list 3

*****Non-specific codes

gen nonspec_hes2 = .
local nonspec "R62 Z755 Z993 Z515 R633 Z431 Z931"
foreach j of local nonspec {
	replace nonspec_hes2=1 if strpos(diag_concat, "`j'") >0 
}
	replace nonspec_hes2=0 if nonspec_hes2==.

la var nonspec_hes2 "Nonspecific CC episode"
*/
*Summary CC variable
gen cc_total2=ucc_group_hes1+ucc_group_hes2+ucc_group_hes3+ucc_group_hes4+ucc_group_hes5+ucc_group_hes6+ucc_group_hes7+ucc_group_hes8+nonspec_hes2

bysort encrypted_hesid: egen cc_ind2=max(cc_total2)
mark cc_multi if cc_ind2>1