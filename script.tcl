#!/bin/tclsh
proc read_design {fname} {
    set result {}
    set fp [open $fname r]
    set data [read $fp]
    close $fp
    foreach line [split $data "\n"] {
        if {[string trim $line] eq ""} continue
        lappend result [split $line " "]
    }
    return $result
}

proc get_cells {pattern} {
    global design
    set result {}
    foreach cell $design {
        if {[string match $pattern [lindex $cell 0]]} {
            lappend result $cell
        }
    }
    return $result
}

proc report_worst {n} {
    global design
    set rows {}
    foreach cell $design {
        lassign $cell name type fanout delay
        set arrival [expr {$delay * (1 + 0.05 * $fanout)}]
        lappend rows [list $arrival $name $type]
    }
    set rows [lsort -real -decreasing -index 0 $rows]
    puts [format "%-14s %-8s %10s" cell type arrival_ps]
    foreach row [lrange $rows 0 [expr {$n - 1}]] {
        puts [format "%-14s %-8s %10.1f" [lindex $row 1] [lindex $row 2] [lindex $row 0]]
    }
}

proc find_violators {threshold} {
    global design
    set result {}
    foreach cell $design {
        lassign $cell name type fanout delay
        set arrival [expr {$delay * (1 + 0.05 * $fanout)}]
        if {$arrival > $threshold} {
            lappend result [list $arrival $name]
        }
    }
    return $result
}

set fp [open "cells.txt" w]
puts $fp "u_alu core 4 82"
puts $fp "u_decoder core 2 45"
puts $fp "u_regfile macro 8 120"
puts $fp "u_mux4 core 3 61"
puts $fp "u_fifo_ctrl ctrl 5 95"
puts $fp "u_uart core 2 30"
close $fp
set fname "cells.txt"
set ::design [read_design $fname]
puts "cells loaded: [llength $::design]"
puts "matches for u_*: [get_cells u_*]"
report_worst 5
puts "violators over 100ps: [find_violators 100]"
