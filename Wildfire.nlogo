extensions [ gis ]

globals [
  initial-trees   ;; how many trees (green patches) we started with
  burned-trees    ;; how many have burned so far
  fire-spread-rate ;; Rate of spread of the fire
  fire-spread-rate-grass
  fire-spread-rate-wind
  fire-spread-rate-theta
  ellipseLTW
  ellipseEccentricity
  thetaAngle ;; variable value
  fire-spread-rate-N
  fire-spread-rate-NW
  fire-spread-rate-NE
  fire-spread-rate-S
  fire-spread-rate-SE
  fire-spread-rate-SW
  fire-spread-rate-W
  fire-spread-rate-E
  fire-danger-index
  fire-danger-index-grass
  fuel-moisture-content
  drought-factor
  varY
  fuelWeightPerPatch
  initial-houses
  burned-houses
  treeColor
  grassColor
  clearColor
  fuelWeightPerPatchGrass
  name
  temperatures
  precipitations
  humidities
  winds
  elevation slope aspect
]
;;100m2
;;casas de 2 ou 3 ou 4
;;explorar com o número de linhas limpas.
;;Embers fligh with the wind
;;habitação e custo de limpeza.
;;clean ainda têm combustivel
;; 4000m2 area limpa
breed [fires fire]    ;; bright red turtles -- the leading edge of the fire
breed [embers ember]  ;; turtles gradually fading from red to near black

turtles-own [spreadNW spreadNorth spreadNE spreadEast spreadSE spreadSouth spreadSW spreadWest]
patches-own [fuel landscape]
to setup
  clear-all
  set treeColor green - 1
  set grassColor green
  set clearColor green + 2
  set fuelWeightPerPatchGrass 28 ;;kg/100m2 0.2802 kg/m2 source https://journals.uair.arizona.edu/index.php/jrm/article/viewFile/4316/3927
  set-default-shape turtles "square"
  ;; make some green trees
  ask patches with [(random-float 100) < density]
    [ set pcolor treeColor ]
  if drawHabitation [
    foreach [20 25 30 35 40] [
      x -> foreach [20 25 30 35] [
        y -> ask patches with [ pxcor = x AND pycor = y ] [
          set pcolor yellow
          set landscape "house"
          ask neighbors [
            set pcolor clearColor
            set fuel clearFuel
          ]
        ]
      ]
    ]
    foreach [23 28 33 38 43] [
      x -> foreach [22 27 32] [
        y -> ask patches with [ pxcor = x AND pycor = y ] [
          set pcolor yellow
          set landscape "house"
          ask neighbors [
            set pcolor clearColor
            set fuel clearFuel
          ]
        ]
      ]
    ]
  ]
  set fuelWeightPerPatch fuelWeight * 10 ;; Convert to kg/100m2
  ask patches with [ pcolor = treeColor ] [ set fuel fuelWeightPerPatch ]
  ask patches with [ pcolor < treeColor AND pcolor != yellow] [
    set pcolor grassColor
    set landscape "grass"
    set fuel fuelWeightPerPatchGrass
  ]
;; set tree counts
  set initial-trees count patches with [pcolor = treeColor]
  set initial-houses count patches with [landscape = "house"]
  set burned-trees 0
  set burned-houses 0
  ask patches with [pxcor  = xcoord AND pycor = ycoord][
    ignite
    ask neighbors4 [ignite]
  ]

  calculate

  if exportImages [
    set-current-directory user-directory
  ]

  file-close-all
  file-open ConfigurationFile
  set temperatures file-read
  set precipitations file-read
  set humidities file-read
  set winds file-read
  print temperatures
  print precipitations
  print humidities
  print winds
  file-close-all

  ; elevations
  set elevation gis:load-dataset "data/local-elevation.asc"
  gis:set-world-envelope gis:envelope-of elevation
  let horizontal-gradient gis:convolve elevation 3 3 [ 1 1 1 0 0 0 -1 -1 -1 ] 1 1
  let vertical-gradient gis:convolve elevation 3 3 [ 1 0 -1 1 0 -1 1 0 -1 ] 1 1
  set slope gis:create-raster gis:width-of elevation gis:height-of elevation gis:envelope-of elevation
  set aspect gis:create-raster gis:width-of elevation gis:height-of elevation gis:envelope-of elevation
  let x 0
  repeat (gis:width-of slope)
  [ let y 0
    repeat (gis:height-of slope)
    [ let gx gis:raster-value horizontal-gradient x y
      let gy gis:raster-value vertical-gradient x y
      if ((gx <= 0) or (gx >= 0)) and ((gy <= 0) or (gy >= 0))
      [ let s sqrt ((gx * gx) + (gy * gy))
        gis:set-raster-value slope x y s
        ifelse (gx != 0) or (gy != 0)
        [ gis:set-raster-value aspect x y atan gy gx ]
        [ gis:set-raster-value aspect x y 0 ] ]
      set y y + 1 ]
    set x x + 1 ]

  print gis:raster-value slope 2 2
  print gis:raster-value elevation 1 0



  reset-ticks
end

to-report calculateWindSpread [angle] ;converted to m/s
  let aux (1 - ellipseEccentricity) / (1 - ellipseEccentricity * cos ( WindDirection - angle  ))
  let forestSpread (fire-spread-rate * ( aux )) * (10 / 36)
  let grassSpread (fire-spread-rate-grass * ( aux )) * (10 / 36)
  report list ( forestSpread ) ( grassSpread )
end

to go
  ; update temperature
  if ((ticks / 60) + 1) < (length temperatures) [
    let prevTemp item (floor (ticks / 60)) temperatures
    let nextTemp item (floor (ticks / 60) + 1) temperatures
    set AirTemperature prevTemp + (nextTemp - prevTemp) * (ticks mod 60 / 60)
  ]

  ; update precipitation
  if ((ticks / 60) + 1) < (length precipitations) [
    let prevPrec item (floor (ticks / 60)) precipitations
    let nextPrec item (floor (ticks / 60) + 1) precipitations
    set Precipitation prevPrec + (nextPrec - prevPrec) * (ticks mod 60 / 60)
  ]

  ; update humidity
  if ((ticks / 60) + 1) < (length humidities) [
    let prevHum item (floor (ticks / 60)) humidities
    let nextHum item (floor (ticks / 60) + 1) humidities
    set Humidity prevHum + (nextHum - prevHum) * (ticks mod 60 / 60)
  ]

  ; update wind
  if ((ticks / 60) + 1) < (length winds) [
    let prevWind item (floor (ticks / 60)) winds
    let nextWind item (floor (ticks / 60) + 1) winds
    set WindSpeed item 0 prevWind + (item 0 nextWind - item 0 prevWind) * (ticks mod 60 / 60)
    set WindDirection item 1 prevWind + (item 1 nextWind - item 1 prevWind) * (ticks mod 60 / 60)
  ]

  calculate

  if not any? turtles  ;; either fires or embers
    [ stop ]
  ask fires
  [ spread ]
  ask fires ;; checks if fire has spreaded outside of its area
  [
    if spreadNorth > 5 [ ask patches at-points [[0 1]]  [ if pcolor != black  [ignite] ] ]
    if spreadSouth > 5 [ ask patches at-points [[0 -1]]  [ if pcolor != black  [ignite] ] ]
    if spreadWest > 5 [ ask patches at-points [[-1 0]]  [ if pcolor != black  [ignite] ] ]
    if spreadEast > 5 [ ask patches at-points [[1 0]]  [ if pcolor != black  [ignite] ] ]
    if spreadNW > 5 [ ask patches at-points [[-1 1]]  [ if pcolor != black   [ignite] ] ]
    if spreadNE > 5 [ ask patches at-points [[1 1]]  [ if pcolor != black [ignite] ] ]
    if spreadSW > 5 [ ask patches at-points [[-1 -1]]  [ if pcolor != black  [ignite] ] ]
    if spreadSE > 5 [ ask patches at-points [[1 -1]]  [ if pcolor != black [ignite] ] ]
    ask patch-at 0 0 [
      set fuel fuel - 0.12 ;; decrement the fuel available at the patch. Measurements of fuel burn rate, emissions and thermal efficiency from a domestic two-stage wood-fired hydronic heater
    ]
    let ftemp [fuel] of patch-at 0 0
    ifelse landscape = "grass"
    [set color 10 + ( 5 * ( ftemp / fuelWeightPerPatchGrass ) )]
    [set color 10 + ( 5 * ( ftemp / fuelWeightPerPatch ) )];; Fade color
    if ftemp < 1 [ die ] ;; kill turtle when the fuel weight is bellow 1
  ]
  ;ask fires [
  ;  [ ask neighbors4 with [pcolor = green]
  ;      [ ignite ]
  ;    set breed embers ]
  fade-embers

  if exportImages [
    if ticks mod 60 = 0 [
      write-current-state ticks / 60
    ]
  ]

  ifelse ticks < ticklimit
  [tick]
  [stop]
end

;; creates the fire turtles
to ignite  ;; patch procedure
  sprout-fires 1
    [ set color red ]
  if pcolor = treeColor [set burned-trees burned-trees + 1]
  if pcolor = yellow [set burned-houses burned-houses + 1]
  set pcolor black

end

;; achieve fading color effect for the fire as it burns
to fade-embers
  ask embers
    [ set color color - 0.3  ;; make red darker
      if color < red - 3.5     ;; are we almost at black?
        [ set pcolor color
          die ] ]
end


to spread
  ifelse landscape = "grass"[
    set spreadNorth spreadNorth + last fire-spread-rate-N
    set spreadSouth spreadSouth + last fire-spread-rate-S
    set spreadEast spreadEast + last fire-spread-rate-E
    set spreadWest spreadWest + last fire-spread-rate-W
    set spreadNE spreadNE + last fire-spread-rate-NE
    set spreadSE spreadSE + last fire-spread-rate-SE
    set spreadNW spreadNW + last fire-spread-rate-NW
    set spreadSW spreadSW + last fire-spread-rate-SW
  ][
    set spreadNorth spreadNorth + first fire-spread-rate-N
    set spreadSouth spreadSouth + first fire-spread-rate-S
    set spreadEast spreadEast + first fire-spread-rate-E
    set spreadWest spreadWest + first fire-spread-rate-W
    set spreadNE spreadNE + first fire-spread-rate-NE
    set spreadSE spreadSE + first fire-spread-rate-SE
    set spreadNW spreadNW + first fire-spread-rate-NW
    set spreadSW spreadSW + first fire-spread-rate-SW
  ]
end

to calculate
    ;; Calculating Fuel Moisture Content
  set fuel-moisture-content ( ( ( 97.7 + 4.06 * Humidity  ) / ( AirTemperature + 6.0 ) ) - ( 0.00854 * Humidity   ) + ( 3000 / DegreeCuring  ) - ( 30 ) )

  ;; Calculating varY (for Forest terrain)
  ifelse Precipitation <= 2
  [set varY 0]
  [ifelse DaysSinceRain >= 1
    [set varY ((Precipitation - 2) / DaysSinceRain)]
    [set varY ((Precipitation - 2) / 0.8)]]

  ;; Calculating the Drought Factor (for Forest terrain)
  set drought-factor max (list (10.5 * (1 - e ^ (-(KeetchByramDroughIndex + 30) / 40)) * ((varY + 42) / (varY ^ (2) + 3 * varY + 42))) 10)

  ;; Calculating Fire Danger Index
  ;; Area = grassland
  ifelse fuel-moisture-content < 18
    ;; fuel-moisture-content < 18
    [set fire-danger-index-grass (3.35 * FuelWeight * (e ^ (-0.0987 * fuel-moisture-content + 0.0403 * WindSpeed)))]
    ;; 18 <= fuel-moisture-content < 30
    [ifelse fuel-moisture-content < 30
      [set fire-danger-index-grass (0.299 * FuelWeight * (e ^ ((-1.686 + 0.0403 * WindSpeed) * (30 * fuel-moisture-content))))]
      ;; fuel-moisture-content >= 30
      [set fire-danger-index-grass (2.0 * FuelWeight * e ^ (-23.6 + 5.01 * ln (DegreeCuring) + 0.0281 * AirTemperature - 0.226 * sqrt (Humidity) + 0.633 * sqrt (WindSpeed)))]]
  ;; Area = forest
  set fire-danger-index (1.25 * drought-factor * e ^ (((AirTemperature -  ( Humidity / 100) ) / (20.0)) + 0.0234 * WindSpeed))

  ;; Calculating Fire Spread Rate
  set fire-spread-rate-grass (0.13 * fire-danger-index)
  set fire-spread-rate (0.0012 * fire-danger-index * fuelWeight)

  ;;Calculating fire spread in the presence of wind
  ;set ellipseLTW  ( 0.936 * e ^ (50.5 * WindSpeed) ) + ( 0.461 * e ^ (-30.5 * WindSpeed) ) - 0.397
  ;set ellipseEccentricity  sqrt ( 1 - (1 / ( ellipseLTW ^ 2 )) )

  ;set ellipseLTW  ( 0.936 * 1.7 ^ (50.5 * WindSpeed) ) + ( 0.461 * e ^ (-30.5 * WindSpeed) ) - 0.397
  set ellipseLTW  ( 0.936 * e ^ (0.2566 * WindSpeed) ) + ( 0.461 * e ^ (-0.1548 * WindSpeed) ) - 0.397
  set ellipseEccentricity  sqrt ( 1 - (1 / ( ellipseLTW ^ 2 )) )
  set thetaAngle 20 ; RANDOM VALUE FOR TESTING
  set fire-spread-rate-theta fire-spread-rate * ( (1 - ellipseEccentricity) / (1 - ellipseEccentricity * cos thetaAngle) )

  set fire-spread-rate-N calculateWindSpread 0
  set fire-spread-rate-NE calculateWindSpread 45
  set fire-spread-rate-NW calculateWindSpread -45
  set fire-spread-rate-S calculateWindSpread 180
  set fire-spread-rate-SE calculateWindSpread 135
  set fire-spread-rate-SW calculateWindSpread -135
  set fire-spread-rate-W calculateWindSpread -90
  set fire-spread-rate-E calculateWindSpread 90
end

to write-current-state [hour]
  export-view (word hour ".png")
  ;file-open (word hour)
  ;ask patches
  ;[ file-write pcolor ]
  ;[ file-write extract-rgb pcolor ]
  ;file-close-all
end



; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
200
10
710
521
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-125
125
-125
125
1
1
1
Minutes
30.0

BUTTON
12
10
82
46
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
92
10
161
46
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

MONITOR
12
70
125
115
Percent Burned
(burned-trees / initial-trees)\n* 100
1
1
11

MONITOR
12
130
125
175
FuelMoisture Content
fuel-moisture-content
5
1
11

MONITOR
12
190
125
235
varY
varY
5
1
11

MONITOR
12
250
125
295
DroughtFactor
drought-factor
5
1
11

MONITOR
12
310
125
355
FireDanger Index
fire-danger-index
5
1
11

MONITOR
12
370
125
415
FireSpread Rate
fire-spread-rate
5
1
11

SLIDER
760
10
950
43
density
density
0.0
99.0
70.0
1.0
1
%
HORIZONTAL

SLIDER
760
55
950
88
DegreeCuring
DegreeCuring
0
100
51.0
1
1
%
HORIZONTAL

SLIDER
760
100
950
133
Precipitation
Precipitation
0
200
0.0
1
1
mm
HORIZONTAL

SLIDER
760
145
950
178
DaysSinceRain
DaysSinceRain
0
5
4.0
1
1
days
HORIZONTAL

SLIDER
760
190
950
223
KeetchByramDroughIndex
KeetchByramDroughIndex
0
200
40.0
1
1
mm
HORIZONTAL

SLIDER
760
235
950
268
AirTemperature
AirTemperature
-10
40
22.70300000000003
1
1
ºC
HORIZONTAL

SLIDER
760
280
950
313
WindSpeed
WindSpeed
0
50
1.91
1
1
m/s
HORIZONTAL

SLIDER
760
325
950
358
WindDirection
WindDirection
-179
180
-82.49799999999999
1
1
º from North
HORIZONTAL

SLIDER
760
370
950
403
Humidity
Humidity
0
100
68.0
1
1
%
HORIZONTAL

SLIDER
760
415
950
448
FuelWeight
FuelWeight
0
100
7.0
1
1
tonnes/ha
HORIZONTAL

MONITOR
62
464
133
509
ellipseLTW
ellipseEccentricity
17
1
11

INPUTBOX
977
43
1032
103
xcoord
70.0
1
0
Number

INPUTBOX
1043
43
1095
103
ycoord
0.0
1
0
Number

MONITOR
977
281
1118
326
DamagesHabitation
(burned-houses / initial-houses) * 100
2
1
11

PLOT
857
525
1057
675
Active Fires
Minutes
100m2
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count turtles"

INPUTBOX
759
457
827
517
tickLimit
3500.0
1
0
Number

PLOT
1063
525
1263
675
Burn percentage
Minutes
%
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (burned-trees / initial-trees) * 100"

SLIDER
975
123
1147
156
clearFuel
clearFuel
0
14
7.0
1
1
kg/m2
HORIZONTAL

SWITCH
975
178
1141
211
drawHabitation
drawHabitation
1
1
-1000

SWITCH
978
227
1111
260
exportImages
exportImages
1
1
-1000

PLOT
435
526
635
676
Temperature
Minutes
ºC
0.0
40.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot AirTemperature"

INPUTBOX
854
461
1105
521
ConfigurationFile
configs/Tondela_PT_2018-06-26 21_00_00
1
0
String

PLOT
221
526
421
676
Wind Speed
Minutes
m/s
0.0
10.0
0.0
7.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot WindSpeed"

PLOT
646
525
846
675
Humidity
Minutes
%
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot Humidity"

PLOT
16
526
216
676
Damaged Habitations
Minutes
%
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (burned-houses / initial-houses) * 100"

@#$#@#$#@
## WHAT IS IT?

This project simulates the spread of a fire through a forest.  It shows that the fire's chance of reaching the right edge of the forest depends critically on the density of trees. This is an example of a common feature of complex systems, the presence of a non-linear threshold or critical parameter.

## HOW IT WORKS

The fire starts on the left edge of the forest, and spreads to neighboring trees. The fire spreads in four directions: north, east, south, and west.

The model assumes there is no wind.  So, the fire must have trees along its path in order to advance.  That is, the fire cannot skip over an unwooded area (patch), so such a patch blocks the fire's motion in that direction.

## HOW TO USE IT

Click the SETUP button to set up the trees (green) and fire (red on the left-hand side).

Click the GO button to start the simulation.

The DENSITY slider controls the density of trees in the forest. (Note: Changes in the DENSITY slider do not take effect until the next SETUP.)

## THINGS TO NOTICE

When you run the model, how much of the forest burns. If you run it again with the same settings, do the same trees burn? How similar is the burn from run to run?

Each turtle that represents a piece of the fire is born and then dies without ever moving. If the fire is made of turtles but no turtles are moving, what does it mean to say that the fire moves? This is an example of different levels in a system: at the level of the individual turtles, there is no motion, but at the level of the turtles collectively over time, the fire moves.

## THINGS TO TRY

Set the density of trees to 55%. At this setting, there is virtually no chance that the fire will reach the right edge of the forest. Set the density of trees to 70%. At this setting, it is almost certain that the fire will reach the right edge. There is a sharp transition around 59% density. At 59% density, the fire has a 50/50 chance of reaching the right edge.

Try setting up and running a BehaviorSpace experiment (see Tools menu) to analyze the percent burned at different tree density levels. Plot the burn-percentage against the density. What kind of curve do you get?

Try changing the size of the lattice (`max-pxcor` and `max-pycor` in the Model Settings). Does it change the burn behavior of the fire?

## EXTENDING THE MODEL

What if the fire could spread in eight directions (including diagonals)? To do that, use `neighbors` instead of `neighbors4`. How would that change the fire's chances of reaching the right edge? In this model, what "critical density" of trees is needed for the fire to propagate?

Add wind to the model so that the fire can "jump" greater distances in certain directions.

Add the ability to plant trees where you want them. What configurations of trees allow the fire to cross the forest? Which don't? Why is over 59% density likely to result in a tree configuration that works? Why does the likelihood of such a configuration increase so rapidly at the 59% density?

## NETLOGO FEATURES

Unburned trees are represented by green patches; burning trees are represented by turtles.  Two breeds of turtles are used, "fires" and "embers".  When a tree catches fire, a new fire turtle is created; a fire turns into an ember on the next turn.  Notice how the program gradually darkens the color of embers to achieve the visual effect of burning out.

The `neighbors4` primitive is used to spread the fire.

You could also write the model without turtles by just having the patches spread the fire, and doing it that way makes the code a little simpler.   Written that way, the model would run much slower, since all of the patches would always be active.  By using turtles, it's much easier to restrict the model's activity to just the area around the leading edge of the fire.

See the "CA 1D Rule 30" and "CA 1D Rule 30 Turtle" for an example of a model written both with and without turtles.

## RELATED MODELS

* Percolation
* Rumor Mill

## CREDITS AND REFERENCES

https://en.wikipedia.org/wiki/Forest-fire_model

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Fire model.  http://ccl.northwestern.edu/netlogo/models/Fire.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1997 2001 MIT -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
set density 60.0
setup
repeat 180 [ go ]
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
