proc getMacs { } {
        global PATH host
        set sophos [exec ssh -oStrictHostKeyChecking=no -i ${PATH}/modules/sophos/id_rsa root@${host} /usr/local/bin/confd-client.plx get_wireless_status 2>/dev/null]

        regsub -all {\n} $sophos "" sophos
        regsub -all {[ ]{2,}} $sophos " " sophos

        debug 2 "Sophos: $sophos"

        set macs ""

        for {set x 0} {$x>=0} {incr x} {
                if {[info exists indices]} {
                        unset indices
                }
                regexp -nocase -indices {'ap' => '[a-z0-9]+', 'connected_time_sec' => [0-9]+, 'connected_time_str' => '[0-9:]+', 'hwaddr' => '(([0-9A-F]{1,2}:){5}[0-9A-F]{1,2})',} $sophos indices
                if {[info exists indices]} {
                        regexp -nocase {'ap' => '[a-z0-9]+', 'connected_time_sec' => [0-9]+, 'connected_time_str' => '[0-9:]+', 'hwaddr' => '(([0-9A-F]{1,2}:){5}[0-9A-F]{1,2})',} $sophos -> mac
                        append macs "$mac\n"
                        set pos [lindex $indices 1]
                        set sophos [string range $sophos $pos end]
                } else {
                        break
                }
        }

        return $macs
}
