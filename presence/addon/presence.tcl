#!/bin/tclsh

load tclrega.so
source functions.tcl

set host "127.0.0.1"
set people ""
set presence_id ""
set FILENAME "/etc/config/addons/presence/presence.conf"

proc loadConfigFile { } {
        global FILENAME host people presence_id

        set content(HOST) $host
        set content(PEOPLE) $people
        set content(PRESENCE_ID) $presence_id
        catch { array set content [loadFile $FILENAME] }

        set host $content(HOST)
        set people $content(PEOPLE)
        set presence_id $content(PRESENCE_ID)

        debug 1 "Host: $host"
        debug 1 "People: $people"
        debug 1 "ID: $presence_id"
}

proc main { } {
        global host people presence_id

        loadConfigFile

        if {$host == "127.0.0.1" || $people == "" || $presence_id == ""} {
                error "Config not complete"
        }

        if {![file exists /tmp/presence.state]} {
                touch /tmp/presence.state
        }

        set prev [exec cat /tmp/presence.state]

        debug 1 "Prev: $prev"

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

        debug 1 "Macs: $macs"

        set home 0

        foreach {name mac} $people {
                if {[string match *$mac* $macs]} {
                        set home 1
                        debug 1 "$name with $mac is home"
                        break
                }
        }

        set rega_cmd "Write(dom.GetObject(${presence_id}).Value());"

        array set result [rega_script $rega_cmd]

        debug 1 "Anwesenheit in CCU: $result(STDOUT)"

        if {"$result(STDOUT)" == "true" && !$home && !$prev} {
                set rega_cmd "dom.GetObject(${presence_id}).Variable(false);"
                rega_script $rega_cmd
        } elseif {"$result(STDOUT)" == "false" && $home} {
                set rega_cmd "dom.GetObject(${presence_id}).Variable(true);"
                rega_script $rega_cmd
        }

        exec echo $home > /tmp/presence.state
}

#*******************************************************************************
# Einsprungpunkt
#*******************************************************************************

if { [catch { main } errorMessage] } then {
        debug 0 $errorMessage
        exit 1
}
