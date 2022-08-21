extensions [gis] ; GIS extension provides GIS support

globals [; global variables
  agent-dataset ; the shapefile of the agents (in point feature)
  beijing-dataset ; the shapefile of the Beijing, divided by 16 administrative regions
  number
  m
  n
  year
  year1 ; the simulation year
]

patches-own [; The Patches on the NetLogo Environment
  random-n
  centroid
  ID
]

; Setting the attributes of the agents
turtles-own [ ; The attributes of the agents
  gender ; if female then 0; if male then 1
  age ;if <18, then 1 ; if 18-24 then 2, if 25-34, then 3; if 35-44 then 4; if 45-54 then 5; if 55-65 then 6; if >65 then 7
  income ;if xxxx
  Education ; if xxxx
  License ; if no driving license then 0; if have a driving license then 1
  expendiure ; xxxx
  household
  vehicle ;if no car then 0; if own a car then 1
  mfriends ;an agent will adopt MaaS when his/her friend(s) using MaaS, then 1; if not, then 0
  mneighbour ;an agent will adopt MaaS when his/her neighbour(s) using MaaS then 1; if not, then 0
  mAdv ;an agent will adopt MaaS when he/she is influenced by MaaS adverstisment, then 1; if not, then 0
  MaaS-familiarity ;if not familar, then 1; if know a little bit, then 2, if familiar with MaaS, then 3
  MaaS ;MaaS Interest; if not interested, then 1; if not very interest, then 2; if interested, then 3; if very interested, then 4
  MaaS-payment ;Characteristics of MaaS; if concerned about one-off payment, then 1
  MaaS-interface ;Characteristics of MaaS; if concerned about single interface, then 1
  MaaS-personalization ;Characteristics of MaaS; if concerned about personalization, then 1
  MaaS-subscription ;Characteristics of MaaS; if concerned about subscription plan, then 1
  MaaS-traffic ;Characteristics of MaaS; if concerned about MaaS traffic improvement, then 1
  MaaS-environment ;Characteristics of MaaS; if concerned about environmental benefits, then 1
  MaaS-privacy ;Characteristics of MaaS; if concerned about privacy concerns, then 1
  MaaS-influence ;qualifying the social influence (friends, neighbours and advertisment)
  MaaS-friends ;if an agent's friend(s) using MaaS, then 1
  MaaS-neighbour ;if an agent's neighbour(s)using MaaS then 1
  MaaS-advertisment ;if an agents is influenced by MaaS advertisment, then 1
  MaaS-Payasyougo ;the preferred discount for MaaS Pay-as-you-go
  adopt-maas-payasyougo ;if the preferred discount >= provided discount, then 1
  MaaS-Monthly ;the preferred discount for MaaS Monthly Subscription Plan
  adopt-maas-monthly1 ;if the preferred discount >= provided discount, then 1
  MaaS-Seasonal ;the preferred discount for MaaS Season Subscription Plan
  adopt-maas-seasonal1 ;if the preferred discount >= provided discount, then 1
  MaaS-Yearly ;the preferred discount for MaaS Yearly Subscription Plan
  adopt-maas-yearly1 ;if the preferred discount >= provided discount, then 1

  MaaS-informed   ;;1 if the agent knows Maas (can be informed by advertisement, friends, and neighbors), 0 if not
  MaaS-adopter  ;; 1 if is a adopter, 0 if not
  MaaS-intention ;; a score to describe the agent's intention to adopt MaaS, from 1 to 20

  ;; the probability calculated by ordered logit model
  prob-yearLY
  prob-seasonal
  prob-monthLY
  prob-onetime

  MaaSadopter-yearly
  MaaSadopter-Monthly
  MaaSadopter-Seasonal
  MaaSadopter-Onetime
 line1
 line2

]

; Add the Beijing shapefile on NetLogo
to setup-map
  show "Loading Beijing Map......"
  set beijing-dataset gis:load-dataset "Beijing.shp"
  gis:set-world-envelope (gis:envelope-of beijing-dataset)
  let i 1
  foreach gis:feature-list-of beijing-dataset [ feature ->
    ask patches gis:intersecting feature [
      set centroid gis:location-of gis:centroid-of feature
      ask patch item 0 centroid item 1 centroid [
        set ID 1
      ]
     ]
      set i i + 1
  ]

;  gis:apply-coverage beijing-dataset "FID_2" ID
  gis:set-drawing-color magenta
  gis:draw beijing-dataset 1

; ask patches [
;    ifelse (ID > 0)
;      [ set pcolor pink ]
;      [ set pcolor blue ]
;  ]
end

to setup-rasterbackground
 ask patches
 [ set pcolor white ]
end

 to setup
  ; Exceuate the setup the following steps
  clear-all
  reset-ticks
  set year 2022
  set year1 2022
  setup-map
  setup-agents
  change-color
  setup-spatially-clustered-network
  ask links [hide-link]
end

to set-baseyear
  count-MaaS-influence
  MaaSLine
end

to count-maas-influence ; compute the social influence of MaaS
 ask turtles [set maas-friends 0 set maas-neighbour 0 set maas-advertisment 0] ; intitially set agents' social circsumstance

  ask turtles[
    let n1 count in-link-neighbors with [MaaS-adopter = 1] ; friendship effect
 if n1 > 0
 [set maas-friends 1 set MaaS-informed 1]
    let n2 sum [count turtles-here with [MaaS-adopter = 1] ] of neighbors in-radius 2; neighborhood effect
 if n2 > 0
 [set maas-neighbour 1 set MaaS-informed 1]
  ]
 let n3 global-influence-advertising-MaaS * 21536  ; MaaS advertisement
 ask n-of n3 turtles [set MaaS-advertisment 1 set MaaS-informed 1]
 ask turtles [set MaaS-influence (Mfriends * 2 * maas-friends + Mneighbour * 1 * maas-neighbour + MAdv * 1 * maas-advertisment)]
end

to setup-agents
  set agent-dataset gis:load-dataset "LSGI4502_ALL_Data_UPDATED_July_v4.shp"
  foreach gis:feature-list-of agent-dataset [
    vector-feature ->
    let coord-tuple gis:location-of (first (first (gis:vertex-lists-of vector-feature)))
    let gender1 gis:property-value vector-feature "Gender"
    let age1 gis:property-value vector-feature "Age"
    let income1 gis:property-value vector-feature "Income"
    let education1 gis:property-value vector-feature "EducationL"
    let drivinglicense1 gis:property-value vector-feature "Drivinglic"
    let expenditure1 gis:property-value vector-feature "Travelexpe"
    let MaaS-interest1 gis:property-value vector-feature "MInterest"
    let MaaS-familiarity1 gis:property-value vector-feature "MFam"
    let MaaS-payment1 gis:property-value vector-feature "Benefit_1"
    let MaaS-interface1 gis:property-value vector-feature "Benefit_2"
    let MaaS-personalization1 gis:property-value vector-feature "Benefit_3"
    let MaaS-subscription1 gis:property-value vector-feature "Benefit_4"
    let MaaS-traffic1 gis:property-value vector-feature "Benefit_5"
    let MaaS-environment1 gis:property-value vector-feature "Benefit_6"
    let MaaS-privacy1 gis:property-value vector-feature "Benefit_7"
    let mfriends1 gis:property-value vector-feature "MFriends"
    let mneighbour1 gis:property-value vector-feature "MNeigh"
    let madvertisment1 gis:property-value vector-feature "MAdv"
    let MaaS-payasyougo1 gis:property-value vector-feature "Sub_1"
    let MaaS-monthly1 gis:property-value vector-feature "Sub_2"
    let MaaS-seasonal1 gis:property-value vector-feature "Sub_3"
    let MaaS-yearly1 gis:property-value vector-feature "Sub_4"
    let household1 gis:property-value vector-feature "Househol"
    let probmaas1 gis:property-value vector-feature "Pay"
    let probmaas2 gis:property-value vector-feature "Month"
    let probmaas3 gis:property-value vector-feature "Season"
    let probmaas4 gis:property-value vector-feature "Yearly"
    let long-coord item 0 coord-tuple
    let lat-coord item 1 coord-tuple

 set-default-shape turtles "person"
    create-turtles 1 [
    setxy long-coord lat-coord
    set Age age1
    set Gender gender1
    set Income income1
    set Education education1
    set License drivinglicense1
    set expendiure expenditure1
    set maas MaaS-interest1
    set MaaS-payment MaaS-payment1
    set MaaS-interface MaaS-interface1
    set MaaS-personalization MaaS-personalization1
    set MaaS-subscription MaaS-subscription1
    set MaaS-traffic MaaS-traffic1
    set MaaS-environment MaaS-environment1
    set MaaS-privacy MaaS-privacy1
    set MFriends mfriends1
    set Mneighbour mneighbour1
    set Madv madvertisment1
    set MaaS-payasyougo MaaS-payasyougo1
    set MaaS-monthly MaaS-monthly1
    set MaaS-seasonal MaaS-seasonal1
    set MaaS-yearly MaaS-yearly1
    set household household1
    set prob-onetime probmaas1
    set prob-monthLY probmaas2
    set prob-seasonal probmaas3
    set prob-yearLY probmaas4
    set line1 9999
    set line2 9999
  ]
]
  ask turtles [set size 0.5
    set color white]
end

to setup-spatially-clustered-network
  let num-links ( 12 * 21536) / 2
  while [count links < num-links ]
  [
    ask one-of turtles
    [
      let choice one-of (other turtles with [not link-neighbor? myself])

      if choice != nobody [ create-link-with choice ]
    ]
  ]
end

to go
  set year year + 1
  set year1 year1 + 1
  count-MaaS-influence
  MaaSLine
  count-MaaS-Intention  ;;count adopting intention of agents
  adopt-MaaS
  change-color
  tick
end

to count-MaaS-Advertisment
  ask turtles [ set MaaS-Advertisment 0 ]
  ask n-of (21536 * global-influence-advertising-MaaS) turtles [ set MaaS-Advertisment 1 ]
end


to MaaSLine
  ask turtles with [ MaaS = 3 and MaaS-influence >= 2 and line1 = 9999 ]
  [set MaaS 4]
  ask turtles with [MaaS = 2 and MaaS-influence >= 2 and line1 = 9999]  ; n-of (n5 * 0.75)
  [set MaaS 3]
end

to change-color
  ask turtles with [ MaaS >= 3 ] [ set color yellow ]
end

to adopt-maas-Onetime
   ask turtles with [ MaaS >= 3] ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo >= discount-payasyougo ; if the preferred discount >= given discount (scenario)
      [ set adopt-maas-payasyougo 1 ]
  ]
  ask turtles with [ MaaS >= 3 ] ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo <  discount-payasyougo
  [set adopt-maas-payasyougo 0]
  ]
end

to adopt-maas-monthly
   ask turtles with [ MaaS >= 3] ; if a person is very interested/ interested in MaaS
  [
  if maas-monthly >= discount-monthly ; if the preferred discount >= given discount (scenario)
      [ set adopt-maas-monthly1 1 ]
  ]
  ask turtles with [ MaaS >= 3 ] ; if a person is very interested/ interested in MaaS
  [
  if maas-monthly <  discount-monthly
  [set adopt-maas-monthly1 0]
  ]
end

to adopt-maas-seasonal
   ask turtles with [ MaaS >= 3]
  [
  if maas-seasonal >= discount-seasonal ; if the preferred discount >= given discount (scenario)
      [ set adopt-maas-seasonal1 1 ]
  ]

  ask turtles with [ MaaS >= 3 ] ; if a person is very interested/ interested in MaaS
  [
  if maas-seasonal <  discount-seasonal
  [set adopt-maas-seasonal1 0]
  ]
end

to adopt-maas-yearly
   ask turtles with [ MaaS >= 3] ; if a person is very interested/ interested in MaaS
  [
  if maas-yearly >= discount-yearly ; if the preferred discount >= given discount (scenario)
      [ set adopt-maas-yearly1 1 ]
  ]

  ask turtles with [ MaaS >= 3 ] ; if a person is very interested/ interested in MaaS
  [
  if maas-yearly <  discount-yearly
  [set adopt-maas-yearly1 0]
  ]
end



to adopt-maas-Onetime-xmonthly
  ask turtles with [adopt-maas-monthly1 = 0]  ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo >= discount-payasyougo ; if the preferred discount >= given discount (scenario)
      [ set adopt-maas-payasyougo 1 ] ; adopt maas pay-as-you-go
  ]

  ask turtles with [ MaaS >= 3 ] ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo <  discount-payasyougo
  [set adopt-maas-payasyougo 0]
  ]
end

to adopt-maas-Onetime-xseason
  ask turtles with [adopt-maas-seasonal1 = 0] ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo >= discount-payasyougo ; if the preferred discount >= given discount (scenario)
      [ set adopt-maas-payasyougo 1 ] ; adopt maas pay-as-you-go
  ]

  ask turtles with [ MaaS >= 3 ] ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo <  discount-payasyougo
  [set adopt-maas-payasyougo 0]
  ]
end

to adopt-maas-Onetime-xyearly
  ask turtles with [adopt-maas-yearly1 = 0] ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo >= discount-payasyougo ; if the preferred discount >= given discount (scenario)
      [ set adopt-maas-payasyougo 1 ] ; adopt maas pay-as-you-go
  ]
  ask turtles with [ MaaS >= 3 ] ; if a person is very interested/ interested in MaaS
  [
  if maas-payasyougo <  discount-payasyougo
  [set adopt-maas-payasyougo 0]
  ]
end

to count-MaaS-Neighbour
;  ask turtles with [ mneighbour = 1 ] [
;    let n1 sum [ count turtles-here with [ MaaS >= 3 ] ] of neighbors in-radius 2;
;    if n1 >= 1
;    [set MaaS-neighbour 1 ]
;    ]
  ask turtles with [ mneighbour = 1 ] [
    let n1 sum [ count turtles-here with [ MaaS-adopter = 1 ] ] of neighbors in-radius 2
    if n1 > 0
    [set MaaS-neighbour 1 set MaaS-informed 1]
  ]
end

to count-MaaS-Friends
  ask turtles with [ mfriends = 1 ] [
    let n1 count in-link-neighbors with [ MaaS >= 3 ];
    if n1 >= 1
    [ set MaaS-Friends 1  set MaaS-informed 1]
  ]
end

to count-MaaS-Intention
 ask turtles [set MaaS-Intention ((MaaS - 1 ) * 5 + ( MaaS-Influence + 1 ))]
end

to adopt-MaaS
  ask turtles with [MaaS-intention >= MaaS-threshold and MaaS-adopter = 0 and MaaS-informed = 1]
  [
    if (maas-payasyougo < discount-payasyougo) [set prob-onetime 0]
    if (maas-monthly < discount-monthly) [set prob-monthly 0]
    if (maas-seasonal < discount-seasonal) [set prob-seasonal 0]
    if (maas-yearly < discount-yearly) [set prob-yearly 0]

    if (prob-yearly > prob-onetime and prob-yearly > prob-monthly and prob-yearly > prob-seasonal) [set MaaSadopter-yearly 1 set MaaS-adopter 1]
    if (prob-monthly > prob-onetime and prob-monthly > prob-yearly and prob-monthly > prob-seasonal) [set MaaSadopter-monthly 1 set MaaS-adopter 1]
    if (prob-seasonal > prob-onetime and prob-seasonal > prob-yearly and prob-seasonal > prob-monthly) [set MaaSadopter-seasonal 1 set MaaS-adopter 1]
    if (prob-onetime > prob-monthly and prob-onetime > prob-yearly and prob-onetime > prob-seasonal) [set MaaSadopter-onetime 1 set MaaS-adopter 1]
  ]
end
