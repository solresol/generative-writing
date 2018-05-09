#!/usr/bin/env wish8.5

set CANVAS_WIDTH 80
set CANVAS_HEIGHT 80
set ZOOM 8
set PARALLEL_OFFSPRING 8
set MAX_USELESS_OFFSPRING 20
set USELESS_OFFSPRING_DESPERATION_COUNT 200
set STARTING_STROKE_COUNT 5
set TEMP_DIRECTORY ./tmp
set SUCCESS_DIRECTORY ./best
set USELESS_OFFSPRING 0
set NUMBER_OF_GENERATIONS 0
set LAST_CONFIDENCE 0
set LOOKS_LIKE ""
file mkdir $TEMP_DIRECTORY


#button .makechildren -text "Next generation" -command make_children
#button .startafresh -text "Start afresh" -command start_afresh
frame .statusvars
label .statusvars.l1 -text "Failed offspring count:"
label .statusvars.v1 -textvariable USELESS_OFFSPRING
label .statusvars.l2 -text "Confidence:"
label .statusvars.v2 -textvariable LAST_CONFIDENCE
label .statusvars.l3 -text "Looks like:"
label .statusvars.v3 -textvariable LOOKS_LIKE

#pack configure .makechildren .startafresh .statusvars -side top -fill x
pack configure .statusvars.l1 .statusvars.v1 .statusvars.l2 .statusvars.v2 .statusvars.l3 .statusvars.v3 -side left -ipady 5
wm title . "Generative Writing"
frame .history  -background yellow
pack configure .history -side bottom

proc canvasname {i} {
    return .offspring.frame$i.c
}

proc labelname {i} {
    return .offspring.frame$i.l
}

proc framename {i} {
    return .offspring.frame$i
}

proc textname {i} {
    return .offspring.frame$i.t
}

canvas .big -width [expr $CANVAS_WIDTH*$ZOOM] -height [expr $CANVAS_HEIGHT*$ZOOM]
frame .offspring

pack configure  .big .offspring -side left -anchor n

for {set i 0} {$i < $PARALLEL_OFFSPRING} {incr i} {
    frame [framename $i] -width [expr $CANVAS_WIDTH * 2 + 3] -background blue
    pack configure [framename $i] -side top -anchor w -ipady 1
    canvas [canvasname $i] -width $CANVAS_WIDTH -height $CANVAS_HEIGHT -background white
    label [labelname $i]  -background blue -width 10
    text [textname $i] -height 3
    pack configure [canvasname $i] [labelname $i] [textname $i] -side left -ipadx 1 -ipady 1
}

proc random_distance_delta {} {
    global USELESS_OFFSPRING
    global USELESS_OFFSPRING_DESPERATION_COUNT
    if {$USELESS_OFFSPRING > $USELESS_OFFSPRING_DESPERATION_COUNT} {
	return [expr 100 - int(rand() * 201)]
    }
    return [expr 20 - int(rand() * 41)]
}

proc random_line {} {
    global CANVAS_WIDTH
    global CANVAS_HEIGHT
    set start_x [expr floor(rand() * $CANVAS_WIDTH)]
    set start_y [expr floor(rand() * $CANVAS_HEIGHT)]
    set end_x [expr floor(rand() * $CANVAS_WIDTH)]
    set end_y [expr floor(rand() * $CANVAS_HEIGHT)]
    return [list line $start_x $start_y $end_x $end_y]
}

proc random_arc {} {
    global CANVAS_WIDTH
    global CANVAS_HEIGHT
    set left [expr floor(rand() * $CANVAS_WIDTH)]
    set top [expr floor(rand() * $CANVAS_HEIGHT)]
    set right [expr floor(rand() * $CANVAS_WIDTH)]
    set bottom [expr floor(rand() * $CANVAS_HEIGHT)]
    if { $left > $right } {
	set a $left
	set left $right
	set right $a
    }
    if { $bottom > $top } {
	set a $bottom
	set bottom $top
	set top $a
    }
    set arc_start [expr floor(rand() * 360) + 1]
    set arc_range [expr floor(rand() * 360) + 1]
    return [list arc $left $top $right $bottom $arc_start $arc_range]
}


proc random_drawing {} {
    global CANVAS_WIDTH
    global CANVAS_HEIGHT
    global STARTING_STROKE_COUNT
    set strokes [expr 1+floor(rand() * $STARTING_STROKE_COUNT)]
    set answer {}
    for {set i 0} {$i < $STARTING_STROKE_COUNT} {incr i} {
	if { rand() > 0.5 } {
	    lappend answer [random_arc]
	} else {
	    lappend answer [random_line]
	}
    }
    return $answer
}

proc mutate_line {line} {
    set start_x [lindex $line 1]
    set start_y [lindex $line 2]
    set end_x [lindex $line 3]
    set end_y [lindex $line 4]
    set delta [random_distance_delta]
    set which [lindex {start_x start_y end_x end_y} [expr int(floor(rand() * 4))]]
    #puts "Modifying $which"
    upvar 0 $which modified
    set modified [expr $modified + $delta]
    if {$start_x < 0} { set start_x 0 }
    if {$start_y < 0} { set start_y 0 }
    if {$end_x < 0} { set end_x 0 }
    if {$end_y < 0} { set end_y 0 }
    global CANVAS_HEIGHT
    global CANVAS_WIDTH
    if {$start_x >= $CANVAS_WIDTH} { set start_x [expr $CANVAS_WIDTH - 1] }
    if {$end_x >= $CANVAS_WIDTH} { set end_x [expr $CANVAS_WIDTH - 1] }
    if {$start_y >= $CANVAS_HEIGHT} { set start_y [expr $CANVAS_HEIGHT - 1] }
    if {$end_y >= $CANVAS_HEIGHT} { set end_y [expr $CANVAS_HEIGHT - 1] }
    return [list line $start_x $start_y $end_x $end_y]
}

proc mutate_arc {arc} {
    set left [lindex $arc 1]
    set top [lindex $arc 2]
    set right [lindex $arc 3]
    set bottom [lindex $arc 4]
    set arc_start [lindex $arc 5]
    set arc_range [lindex $arc 6]
    if { rand() > 0.5 } {
	# mutate bounding box
	set delta [random_distance_delta]
	set which [lindex {left top right bottom} [expr int(floor(rand() * 4))]]
	upvar 0 $which modified
	set modified [expr $modified + $delta]
	if {$left < 0} { set left 0 }
	if {$top < 0} { set top 0 }
	if {$right < 0} { set right 0 }
	if {$bottom < 0} { set bottom 0 }
	global CANVAS_HEIGHT
	global CANVAS_WIDTH
	if {$left >= $CANVAS_WIDTH} { set left [expr $CANVAS_WIDTH - 1] }
	if {$right >= $CANVAS_WIDTH} { set right [expr $CANVAS_WIDTH - 1] }
	if {$top >= $CANVAS_HEIGHT} { set top [expr $CANVAS_HEIGHT - 1] }
	if {$bottom >= $CANVAS_HEIGHT} { set bottom [expr $CANVAS_HEIGHT - 1] }
	if { $left > $right } {
	    set a $left
	    set left $right
	    set right $a
	}
	if { $bottom > $top } {
	    set a $bottom
	    set bottom $top
	    set top $a
	}
    } else {
	set delta [random_distance_delta]
	if {rand() < 0.5} {
	    set arc_start [expr $arc_start + $delta]
	} else {
	    set arc_range [expr $arc_range + $delta]
	}
	if {$arc_start < 1} { set arc_start 1 }
	if {$arc_range < 1} { set arc_range 1 }
	if {$arc_start > 360} { set arc_start 360 }
	if {$arc_range < 360} { set arc_range 360 }
    }
    return [list arc $left $top $right $bottom $arc_start $arc_range]
}

proc mutate {drawing {mutation_count 1}} {
    set drawing_length [llength $drawing]
    set task_random [expr rand()]
    set where [expr int(floor(rand() * $drawing_length))]
    if {$task_random < 0.125} {
	#puts "$task_random Adding a line"
	lappend drawing [random_line]
    } elseif {$task_random < 0.25} {
	#puts "$task_random Adding an arc"
	lappend drawing [random_arc]
    } elseif {($task_random < 0.5) && ($drawing_length > 1)} {
	#puts "$task_random Removing an element"
	set drawing [lreplace $drawing $where $where]
    } else {
	#puts "$task_random Changing element $where"
	set what [lindex $drawing $where]
	if {[string compare [lindex $what 0] line] == 0} {
	    set replacement [mutate_line $what]
	} else {
	    set replacement [mutate_arc $what]
	}
	set drawing [lreplace $drawing $where $where $replacement]
    }
    return $drawing
}


proc draw_drawing_on_canvas {canvas drawing} {
    foreach etch $drawing {
	#puts $etch
	switch [lindex $etch 0] {
	    line {
		$canvas create line [lindex $etch 1] [lindex $etch 2] [lindex $etch 3] [lindex $etch 4]
	    }
	    arc {
		$canvas create arc [lindex $etch 1] [lindex $etch 2] [lindex $etch 3] [lindex $etch 4] -start [lindex $etch 5] -extent [lindex $etch 6] -style arc
	    }
	}
    }
}

proc draw_drawing {drawing} {
    draw_drawing_on_canvas .big $drawing
    global ZOOM
    .big scale all 0 0 $ZOOM $ZOOM
}


proc clear_drawing {} {
    .big delete all
    global PARALLEL_OFFSPRING
    for {set i 0} {$i < $PARALLEL_OFFSPRING} {incr i} {
	[canvasname $i] delete all
    }
}


proc make_children {} {
    global NEXT_GENERATION
    global PARALLEL_OFFSPRING
    global CURRENT_DRAWING
    global TEMP_DIRECTORY
    global USELESS_OFFSPRING
    set productive_offspring {}

    for {set i 0} {$i < $PARALLEL_OFFSPRING} {incr i} {
	[canvasname $i] delete all
	[framename $i] configure -background blue
	[labelname $i] configure -background blue
	[textname $i] delete 1.0 end
    }
    for {set i 0} {$i < $PARALLEL_OFFSPRING} {incr i} {
	set NEXT_GENERATION($i) [mutate $CURRENT_DRAWING]
	draw_drawing_on_canvas [canvasname $i] $NEXT_GENERATION($i)
	[labelname $i] configure -text "Working..."
	update
	[canvasname $i] postscript -file $TEMP_DIRECTORY/img$i.ps
	exec convert $TEMP_DIRECTORY/img$i.ps $TEMP_DIRECTORY/img$i.png
	set output [exec -ignorestderr tesseract $TEMP_DIRECTORY/img$i.png stdout --psm 10 hocr 2>> .tesseract.log | ./hocr2list.py 2>> .hocr2list.log ]
	puts "Output = $output"
	set output [lindex $output 0]
	if {[llength $output] == 0} {
	    incr USELESS_OFFSPRING
	    [framename $i] configure -background red
	    [labelname $i] configure -background red
	    [labelname $i] configure -text ""
	} else {
	    [framename $i] configure -background lightgreen
	    [labelname $i] configure -background lightgreen
	    set confidence [lindex $output 1]
	    set word_found [lindex $output 3]
	    [textname $i] insert end $word_found
	    [labelname $i] configure -text "$confidence%"
	    lappend productive_offspring $confidence $word_found $i
	    puts "$productive_offspring"
	}
    }
    return $productive_offspring
}




proc next_generation {} {
    global CURRENT_DRAWING
    clear_drawing
    draw_drawing $CURRENT_DRAWING
}


proc start_afresh {} {
    global CURRENT_DRAWING
    global USELESS_OFFSPRING
    set CURRENT_DRAWING [random_drawing]
    set USELESS_OFFSPRING 0
    draw_drawing $CURRENT_DRAWING
}

proc flash_frame {i} {
    for {set j 0} {$j < 3} {incr j} {
	[framename $i] configure -background yellow
	update
	after 250
	[framename $i] configure -background lightgreen
	update
	after 250
    }
    
}

proc cycle {} {
    global USELESS_OFFSPRING
    global PARALLEL_OFFSPRING
    global MAX_USELESS_OFFSPRING
    global NEXT_GENERATION
    global NUMBER_OF_GENERATIONS
    global LAST_CONFIDENCE
    global LOOKS_LIKE
    while {1} {
	set good_children [make_children]
	if {[llength $good_children] > 0} {
	    set most_confident 0
	    set best_drawing -1
	    set best_word ""
	    foreach {confidence word i} $good_children {
		if {$confidence > $most_confident} {
		    set best_drawing $i
		    set most_confident $confidence
		    set best_word $word
		}
	    }
	    if {$LAST_CONFIDENCE >= $most_confident} {
		continue
	    }
	    flash_frame $best_drawing
	    replace_main_drawing $NEXT_GENERATION($i)
	    set LAST_CONFIDENCE $most_confident
	    set LOOKS_LIKE $best_word 
	    set USELESS_OFFSPRING 0
	}
	if {$USELESS_OFFSPRING > $MAX_USELESS_OFFSPRING && $NUMBER_OF_GENERATIONS == 0} {
	    start_afresh
	}
	update
	puts "Pathetic..."
    }
}

proc replace_main_drawing {drawing} {
    global CURRENT_DRAWING
    global NUMBER_OF_GENERATIONS
    global CANVAS_WIDTH
    global CANVAS_HEIGHT
    global LAST_CONFIDENCE
    frame .history.f$NUMBER_OF_GENERATIONS
    canvas .history.f$NUMBER_OF_GENERATIONS.c -width $CANVAS_WIDTH -height $CANVAS_HEIGHT
    label .history.f$NUMBER_OF_GENERATIONS.g -text "$LAST_CONFIDENCE%"
    pack .history.f$NUMBER_OF_GENERATIONS -side left -ipadx 2 -ipady 2
    pack .history.f$NUMBER_OF_GENERATIONS.c .history.f$NUMBER_OF_GENERATIONS.g -side top -ipadx 2 -ipady 2
    draw_drawing_on_canvas .history.f$NUMBER_OF_GENERATIONS.c $CURRENT_DRAWING
    set CURRENT_DRAWING $drawing
    draw_drawing $drawing
    incr NUMBER_OF_GENERATIONS
}


start_afresh
cycle
