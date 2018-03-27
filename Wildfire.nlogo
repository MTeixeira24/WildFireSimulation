;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Fire in the forest model written by Byron Roland, George Kampis and Istvan Karsai, 2011-2016
;; The result of this model has been published in Ecological Complexity 28 (2016): 12-23.
;;Please cite this Netlogo model as:
;;Roland, B., Kampis, G. and Karsai, I (2016): Fire in the forest. Netlogo v. 5.3.1 simulation.
;;http://ccl.northwestern.edu/netlogo/models/community/Fire%in%the%forest
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



globals[i m seed]   ;;Variables used as counters for the year and the excel file number extension
breed[animals animal]
breed[fires fire]
breed[trees tree]
breed[animalcorpses animalcorpse]    ;;Used to count the number of dead animals
breed[treecorpses treecorpse]        ;;Count the dead trees
breed[firecorpses firecorpse]        ;;Count the dead fires

to Setup                             ;;Initializes the program.
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set seed random 10000
  random-seed seed
  create-animals NumberofAnimals[
    set color brown                        ;;Initializes the starting number of
    set shape "sheep 2"                       ;;organisms and their shape and color
    setxy random-xcor random-ycor]
  create-trees NumberofTrees[
    set color green
    set shape "tree"
    setxy random-xcor random-ycor]
  create-fires FireStrength [
    set color red
    set shape "fire"
    setxy random-xcor random-ycor]
  update-plot
end

to Go                            ;;Coninuous loop that updates the deathplot
  ifelse i >= YearsPerSetup         ;;and asks the organisms to do specific
  [stop]                            ;;things defined below this method
  [update-deathplot              ;;Continues until variable i has been incremented
   ask animals[                     ;;to a value greater than the parameter YearsPerSetup
     move-animal]
   ask fires[
     kill-trees
     kill-animals]
   update-plot
   tick
   end-year]
end

to update-deathplot
  set-current-plot "Dead Populations"                           ;;Updates the plot of dead animals and trees.
  set-current-plot-pen "Burned Animals"
  plot count animalcorpses
  set-current-plot-pen "Burned Trees"
  plot count treecorpses
end

to move-animal
    repeat AnimalMovementSpeed[
    ifelse any? fires in-radius 1                               ;;Look for fires, if there are any
    [die]                                                          ;;within 1 block then die.
    [rt random 360 fd 1]]                                       ;;Animals move randomly as many times as AnimalMovementSpeed
end

to  kill-trees
  let kill one-of trees in-radius 1
  ifelse kill != nobody                                                             ;;If theres a tree in the fires path, kill
    [face kill ask kill [set breed treecorpses hide-turtle] fd 1                       ;;it and hatch 1 more fire.
      hatch 1 [rt random 360 fd 1]]
    [set breed firecorpses hide-turtle]                                             ;;Otherwise die
end

to kill-animals
  repeat (count animals in-radius 1)                                                 ;;Kills all animals in radius 1
  [let kill one-of animals in-radius 1
    if kill != nobody                                                                ;;If theres a animal in the fires path, kill
      [face kill ask kill [set breed animalcorpses hide-turtle] fd 1]]                  ;;it and then check for trees
end

to update-plot
  set-current-plot "Populations"                                        ;;Updates the animal, tree, fire population graph.
  set-current-plot-pen "animals"                                           ;;this is done every tick so as to keep a coninuous
  plot count animals                                                       ;;look and feel in the graph
  set-current-plot-pen "trees"
  plot count trees
  set-current-plot-pen "fires"
  plot count fires
end

to end-year
  if ticks > 11
      [ask animals[
        death-animal
        reproduce-animal]
      create-trees count trees * TreeBreedingPercent / 100[            ;;Create 10 percent of the current number
        set color green                                                   ;;of trees and hatch them randomly.
        set shape "tree"
        setxy random-xcor random-ycor
        if any? other trees-on patch-ahead 0 [die]]                    ;;If trees on the same patch, die.
      create-fires FireStrength [                                      ;;Create a given number of fires
        set color red                                                     ;;based of fire strength parameter
        set shape "fire"
        setxy random-xcor random-ycor]
      ask animalcorpses[                                               ;;kills all the corpses so as to reset
        die]                                                              ;;the number of dead "turtles" back to 0
      ask treecorpses[
        die]
      ask firecorpses[
        die]
      set i i + 1
      reset-ticks]
end

to death-animal
  if AnimalTreeDDDeath?                                                        ;;If animals can die from lack of trees
    [if not any? trees in-radius 1 [die]]                                      ;;If there are no trees within 1 block, die.
  ifelse count trees in-radius 1 < 5
    [if random 50 < AnimalDeathPercent [die]]                                  ;;If there are less than 5 trees within
    [if random 100 < AnimalDeathPercent [die]]                                    ;;1 block then animal death rate is doubled.
end

to reproduce-animal
  ifelse count trees in-radius 2 < AnimalTreeVariableBreeding                  ;;If there are 5 trees within two blocks
    [stop]                                                                        ;;of the animal, hatch 1 new animal.
    [ifelse count animals in-radius 2 > AnimalAnimalVariableBreeding           ;;If there are more than 5 animals around
      [stop]                                                                   ;   ;two blocks dont hatch 1.
      [hatch 1 [rt random 360 fd 1]]]
end

to basic-simulation                                     ;;Creates a basic simulation
  set AnimalTreeDDDeath? false                             ;;used to make life easier
  set NumberofAnimals 100                                  ;;by just having to press one button
  set NumberofTrees 500                                    ;;rather than trying to find the
  set YearsPerSetup 100                                    ;;right values for each parameter
  set AnimalTreeVariableBreeding 5                         ;;to create a stable ecosystem
  set AnimalAnimalVariableBreeding 5
  set TreeBreedingPercent 10
  set AnimalMovementSpeed 5
  set AnimalDeathPercent 10
  set FireStrength 0
end
@#$#@#$#@
GRAPHICS-WINDOW
681
23
1176
519
-1
-1
12.5122
1
10
1
1
1
0
1
1
1
-19
19
-19
19
0
0
1
Month
30.0

SLIDER
8
52
283
85
NumberofAnimals
NumberofAnimals
0
2000
100.0
10
1
NIL
HORIZONTAL

SLIDER
8
91
282
124
NumberofTrees
NumberofTrees
0
1000
500.0
10
1
NIL
HORIZONTAL

BUTTON
9
10
108
43
Setup
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
116
10
211
43
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
17
262
94
307
Animals
count animals
17
1
11

MONITOR
102
262
180
307
Trees
count trees
17
1
11

MONITOR
189
261
267
306
Fires
count fires
17
1
11

PLOT
12
331
291
571
Populations
Time(Months)
Populations
0.0
0.0
0.0
750.0
true
true
"" ""
PENS
"Animals" 1.0 0 -6459832 true "" ""
"Trees" 1.0 0 -10899396 true "" ""
"Fires" 1.0 0 -2674135 true "" ""

SLIDER
353
162
501
195
AnimalMovementSpeed
AnimalMovementSpeed
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
353
201
531
234
AnimalDeathPercent
AnimalDeathPercent
0
100
10.0
1
1
%
HORIZONTAL

SWITCH
351
69
523
102
AnimalTreeDDDeath?
AnimalTreeDDDeath?
1
1
-1000

SLIDER
8
130
126
163
YearsPerSetup
YearsPerSetup
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
352
275
556
308
AnimalTreeVariableBreeding
AnimalTreeVariableBreeding
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
352
238
558
271
AnimalAnimalVariableBreeding
AnimalAnimalVariableBreeding
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
351
110
516
143
TreeBreedingPercent
TreeBreedingPercent
0
100
10.0
5
1
%
HORIZONTAL

PLOT
330
332
620
571
Dead Populations
Time(Months)
Dead Populations
0.0
0.0
0.0
150.0
true
true
"" ""
PENS
"Burned Animals" 1.0 0 -16777216 true "" ""
"Burned Trees" 1.0 0 -955883 true "" ""

MONITOR
16
209
88
254
Year
i
17
1
11

BUTTON
137
130
255
163
Basic Simulation
basic-simulation
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
317
10
467
28
Fire
12
0.0
1

TEXTBOX
314
52
464
70
Trees
12
0.0
1

TEXTBOX
312
144
462
162
Animals
12
0.0
1

TEXTBOX
562
278
676
318
Animal breeding variable based on number of trees present.
11
0.0
1

TEXTBOX
563
233
673
273
Animal breeding variable based on number of animals around.
11
0.0
1

TEXTBOX
537
66
669
114
Are the animals dependent on the trees to survive?
11
0.0
1

SLIDER
352
15
524
48
FireStrength
FireStrength
0
20
2.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the dynamics of an animal/tree/fire ecosystem with random fires.
The result of this model has been published in Ecological Complexity 28 (2016): 12-23.

Abstract:

Our model considers a new element in forest fire modeling, namely the dynamics of a forest animal, intimately linked to the trees. We show that animals and trees react differently to different types of fire. A high probability of fire initiation results in several small fires, which do not allow for a large fuel accumulation and thus the destruction of many trees by fire, but is found to be generally devastating to the animal population at the same time. On the other hand, a low fire initiation probability allows for the accumulation of higher quantities of fuel, which in turn results in larger fires, more devastating to the trees than to the animals. Thus, we suggest that optimal fire management should take into account the relation between fire initiation and its different effects on animals and trees. Further, wildfires are often considered as prime examples for power-law-like frequency distributions, yet there is no agreement on the mechanisms responsible for the observed patterns. Our model suggests that instead of a single unified distribution, a superposition of at least two different distributions can be detected and this suggests multiform mechanisms acting on different scales. None of the discovered distributions are compatible with a power-law hypothesis.

Please cite this Netlogo model as:
Roland, B., Kampis, G. and Karsai, I (2016): Fire in the forest. Netlogo v. 5.3.1 simulation.
http://ccl.northwestern.edu/netlogo/models/community/Fire%in%the%forest

## HOW IT WORKS

The model has three hierarchical levels: entities, interactions, and environment, with the first two being modeled explicitly and the environment being modeled implicitly.
Populations are characterized by the census of each organism type at the end of a given year. The number of burned trees and animals are counted every year.
The model is spatially explicit. Trees are immobile, while animals and fires can move, following explicit rules. The state of the agents is tracked through time and defined by the location of each individual and each interaction between individuals and the environment. The population's dynamics and individual behaviors emerge from the interactions at the individual (agent) level. All sensing and interaction are strictly local to the agents. Individuals "know" (access) their own current activity status (i.e., this status is explicitly represented in a state variable) and they can check (i.e., sense) the existence and the status of other agents in the neighborhood.


Things to Know
********************
The unit of time is  1 tick = 1 month (12 months is a year).

Animals can breed, whereby one individual becomes 2 individuals:
  - There must be enough trees around (AnimalTreeVariableBreeding).
  - There must NOT be more than a certain number of other animals around (AnimalAnimalVariableBreeding).

Animals die by:
  - Old age (AnimalDeathPercent).
  - Tree Density dependent death rate (AnimalTreeDDDeath).
  - Fire burns.

Trees produce seeds:
  - Some percent of the total current population (TreeBreedingPercent).
  - A tree only develops if the seend falls into a tree-less spot.

Trees die by:
  - Fire burn.

Fires are initiated:
  - Random location.
  - FireStrength describes the maximum number of fire initiation point/year.
  - If there is a tree in the adjacent neighborhood, the fire can spread to that neighborhood.

Fires kill:
  -Trees.
  -Animals.

Fires die if:
  -There are no more live trees to burn in the adjacent neighborhood.

## HOW TO USE IT

1.) Initialize the number of animals, trees, and fires.
2.) Adjust the slider parameters (see below), or use the default settings.
3.) Press the SETUP button.
4.) Press the GO button to begin the simulation.
5.) Look at the main monitor to watch the ecosystem develop.
6.) Look at the POPULATIONS plot to watch the populations fluctuate over time.
7.) Look at the DEAD POPULATIONS plot to watch the number of animals and trees that die.

Parameters
***************
NumberofAnimals: The initial number of animals.
NumberofTrees: The initial number of trees.
YearsPerSetup: The number of years per setup run.
FireStrength: The maximum number of fires created each year.
AnimalTreeDDDeath: Density dependent death of animals based on the trees.
TreeBreedingPercent: The percentage of trees that breed every year.
AnimalMovementSpeed: The number of times a animal moves per month (1 tick).
AnimalDeathPercent: The percent of animals that will die each year due to old age.
AnimalAnimalVariableBreeding: Number of animals around an animal that limits its breeding (birth rate depend on animal density).
AnimalTreeVariableBreeding: The number of trees needed for an animal to breed.

## THINGS TO NOTICE

Small fire strength will produce a small number of devastating large fires. This is very detrimental to the trees.

Large fire strength produces many smaller and medium sized fires. This is more devastatiung to the animal populations than to the trees.

The distribution of fires DOES NOT follow a power law (see paper for detailed analysis).

## THINGS TO TRY

Try changing the TreeBreedingPercent and FireStrength parameters. Notice the significant changes in the population graph.

Try finding specific parameters to create a stable ecosystem between the three "breeds" such that none of them become extinct.

The fire strength parameter corresponds to the number of lightning that can initiate fires in the forest.

## EXTENDING THE MODEL

Add extra parameters such as estimating wind speed and direction as well as temperature and movement patterns of the animals, or add the possibility of the animals moving towards the trees rather than moving randomly looking for an appropriate breeding habitat.

## NETLOGO FEATURES

Note the use of breeds to model three different kinds of "turtles": animals, trees, and fires.

Note the use of "if random 100 < AnimalDeathPercent" to determine the percent of animals that die each year.

Also note the random fire strength to signify a random number of fires in a range between the user defined maximal amount and 0. This is much more realistic than a rigidly deterministic number of fires each year.

## RELATED MODELS

Look at "Wolf Sheep Predation" for another model of ecosystem dynamics involving three elements. Also see different forest fire models in the community page, but those mainly focus on 2 components only.

## CREDITS AND REFERENCES

Roland, Byron	roland@goldmail.etsu.edu ETSU BISC Johnson City TN USA
Kampis, George  kampis.george@gmail.com German Research Center for Artificial Intelligence (DFKI GmbH)
Karsai, Istvan	karsai@etsu.edu ETSU BISC Johnson City TN USA

Paper based on this program:

Karsai, I., Roland, B. and Kampis, G. 2016: The effect of fire on an abstract forest ecosystem: An agent based study. Ecological Complexity Volume 28, Pages 12–23. http://dx.doi.org/10.1016/j.ecocom.2016.09.001.
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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

sheep 2
false
0
Polygon -7500403 true true 209 183 194 198 179 198 164 183 164 174 149 183 89 183 74 168 59 198 44 198 29 185 43 151 28 121 44 91 59 80 89 80 164 95 194 80 254 65 269 80 284 125 269 140 239 125 224 153 209 168
Rectangle -7500403 true true 180 195 195 225
Rectangle -7500403 true true 45 195 60 225
Rectangle -16777216 true false 180 225 195 240
Rectangle -16777216 true false 45 225 60 240
Polygon -7500403 true true 245 60 250 72 240 78 225 63 230 51
Polygon -7500403 true true 25 72 40 80 42 98 22 91
Line -16777216 false 270 137 251 122
Line -16777216 false 266 90 254 90

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
NetLogo 6.0.3
@#$#@#$#@
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
