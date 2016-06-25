#!/bin/tclsh

load tclrega.so

set ADDON_NAME "presencebymac"

set host "127.0.0.1"
set people ""
set presence_id ""
set module ""
set ccu ""
set PATH "/etc/config/addons/${ADDON_NAME}"
set FILENAME "${PATH}/${ADDON_NAME}.conf"

source ${PATH}/functions.tcl

proc loadConfigFile { } {
        global FILENAME host people presence_id module ccu

        set content(HOST) $host
        set content(PEOPLE) $people
        set content(PRESENCE_ID) $presence_id
        set content(MODULE) $module
        set content(CCU) $ccu
        catch { array set content [loadFile $FILENAME] }

        set host $content(HOST)
        set people $content(PEOPLE)
        set presence_id $content(PRESENCE_ID)
        set module $content(MODULE)
        set ccu $content(CCU)

        debug 1 "Host: $host"
        debug 1 "People: $people"
        debug 1 "ID: $presence_id"
        debug 1 "Module: $module"
        debug 1 "CCU: $ccu"
}

proc main { } {
        global PATH host people presence_id module ccu

        loadConfigFile

        if {$host == "127.0.0.1" || $people == "" || $presence_id == "" || $module == "" || $ccu == ""} {
                error "Config not complete"
        }

        source ${PATH}/modules/${module}.tcl

        if {![file exists /tmp/presence.state]} {
                exec touch /tmp/presence.state
                exec echo 1 > /tmp/presence.state
        }

        set prev [exec cat /tmp/presence.state]

        debug 1 "Prev: $prev"

        set macs [getMacs]

        debug 1 "Macs: $macs"

        set home 0

        foreach {name mac} $people {
                if {[string match *[string toupper $mac]* [string toupper $macs]]} {
                        set home 1
                        debug 1 "$name with $mac is home"
                }
        }

        set rega_cmd "Write(dom.GetObject(${presence_id}).Value());"

        array set result [rega_script $rega_cmd]

        debug 1 "Anwesenheit in CCU: $result(STDOUT)"

        if {"$result(STDOUT)" == "true" && !$home && !$prev} {
                set rega_cmd "dom.GetObject(${presence_id}).State(false);"
                rega_script $rega_cmd
        } elseif {"$result(STDOUT)" == "false" && $home} {
                set rega_cmd "dom.GetObject(${presence_id}).State(true);"
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
