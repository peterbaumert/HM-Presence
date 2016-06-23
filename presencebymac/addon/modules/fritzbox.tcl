proc getMacs { } {
        global host

        set fb [exec wget -q -O - http://${host}/wlan/wlan_settings.lua]
        regsub -all {\n} $fb "" fb

        debug 2 "FB: $fb"

        set macs ""

        for {set x 0} {$x>=0} {incr x} {
                if {[info exists indices]} {
                        unset indices
                }
                regexp -line -indices {MAC-Adresse">(([0-9A-F]{1,2}:){5}[0-9A-F]{1,2})<\/td><td class="hint" datalabel="Datenrate">[0-9]} $fb indices
                if {[info exists indices]} {
                        regexp -line {MAC-Adresse">(([0-9A-F]{1,2}:){5}[0-9A-F]{1,2})<\/td><td class="hint" datalabel="Datenrate">[0-9]} $fb -> mac
                        append macs "$mac\n"
                        set pos [lindex $indices 1]
                        set fb [string range $fb $pos end]
                } else {
                        break
                }
        }

        return $macs
}
