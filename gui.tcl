#!/usr/bin/env wish -f

set CANVAS_WIDTH 80
set CANVAS_HEIGHT 80
set ZOOM 8
set PARALLEL_OFFSPRING 8
set STARTING_STROKE_COUNT 3
canvas .big -width [expr $CANVAS_WIDTH*$ZOOM] -height [expr $CANVAS_HEIGHT*$ZOOM]
frame .offspring -background blue

pack configure  .big .offspring -side left -anchor n

for {set i 0} {$i < $PARALLEL_OFFSPRING} {incr i} {
    canvas .offspring.c$i -width $CANVAS_WIDTH -height $CANVAS_HEIGHT -background white
    pack configure .offspring.c$i -side top -anchor w -ipady 1
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
    set delta [expr 20 - floor(rand() * 41)]
    set which [lindex {start_x start_y end_x end_y} [expr int(floor(rand() * 4))]]
    puts "Modifying $which"
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
	set delta [expr 20 - floor(rand() * 41)]
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
	set delta [expr 20-floor(rand()*41)]
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

proc mutate {drawing} {
    set drawing_length [llength $drawing]
    set task_random [expr rand()]
    set where [expr int(floor(rand() * $drawing_length))]
    if {$task_random < 0.125} {
	puts "$task_random Adding a line"
	lappend drawing [random_line]
    } elseif {$task_random < 0.25} {
	puts "$task_random Adding an arc"
	lappend drawing [random_arc]
    } elseif {($task_random < 0.5) && ($drawing_length > 1)} {
	puts "$task_random Removing an element"
	set drawing [lreplace $drawing $where $where]
    } else {
	puts "$task_random Changing element $where"
	set what [lindex $drawing $where]
	if {[string compare [lindex $what 0] line] == 0} {
	    set replacement [mutate_line $what]
	} else {
	    set replacement [mutate_arc $what]
	}
	set drawing [lreplace $drawing $where $where $replacement]
    }
}


proc draw_drawing_on_canvas {canvas drawing} {
    foreach etch $drawing {
	puts $etch
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
	.offspring.c$i delete all
    }
}
		   

set CURRENT_DRAWING [random_drawing]

proc make_children {} {
    global NEXT_GENERATION
    global PARALLEL_OFFSPRING
    global CURRENT_DRAWING
    for {set i 0} {$i < $PARALLEL_OFFSPRING} {incr i} {
	set NEXT_GENERATION($i) [mutate $CURRENT_DRAWING]
	draw_drawing_on_canvas .offspring.c$i $NEXT_GENERATION($i)
    }
}


proc next_generation {} {
    global CURRENT_DRAWING
    clear_drawing
    set CURRENT_DRAWING 
    draw_drawing $CURRENT_DRAWING
}



draw_drawing $CURRENT_DRAWING
make_children



#button .b -text "Mutate" -command next_generation
#pack .b

