# Physical connectivity is captured once for the unchanged mapped netlist.
proc ee470_capture_connectivity {filename} {
    set fd [open $filename w]
    puts $fd "pin\tdirection\tnet_count\tnets"
    foreach_in_collection pin [get_pins -hierarchical *] {
        set nets [get_nets -quiet -of_objects $pin]
        set names {}
        foreach_in_collection net $nets {lappend names [get_object_name $net]}
        puts $fd "[get_object_name $pin]\t[get_attribute $pin direction]\t[sizeof_collection $nets]\t[join $names {;}]"
    }
    close $fd
}

# Activity is captured separately in each MCMM scenario, after propagation.
proc ee470_capture_activity {prefix} {
    redirect ${prefix}_net_activity.rpt {get_switching_activity -significant_digits 13 [get_nets -hierarchical *]}
    redirect ${prefix}_pin_activity.rpt {get_switching_activity -significant_digits 13 [get_pins -hierarchical *]}
    redirect ${prefix}_port_activity.rpt {get_switching_activity -significant_digits 13 [get_ports *]}
}
