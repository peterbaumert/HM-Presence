#!/bin/tclsh

load tclrega.so

set FILENAME "/etc/config/addons/presence/presence.conf"

set host 127.0.0.1
set people ""
set presence_id ""

set args(command) "INV"
set args(host) $host
set args(people) $people
set args(presence_id) $presence_id

proc parseQuery { } {
        global args env

        if [info exists env(CONTENT_LENGTH)] {
                set forminput [read stdin $env(CONTENT_LENGTH)]
        } else {
                set forminput $env(QUERY_STRING)
        }
        foreach {name value} [split $forminput =&] {
                regsub -all \\\+ $value " " value
                regsub -all -nocase {%([0-9a-f][0-9a-f])} $value \
                        {[format %c 0x\1]} value
                set args($name) [subst $value]
        }
}


proc loadFile { fileName } {
        set content ""
        set fd -1

        set fd [ open $fileName r]
        if { $fd > -1 } {
                set content [read $fd]
                close $fd
        }

        return $content
}

proc loadConfigFile { } {
        global FILENAME host people presence_id

        set content(HOST) $host
        set content(PEOPLE) $people
        set content(PRESENCE_ID) $presence_id
        catch { array set content [loadFile $FILENAME] }

        set host $content(HOST)
        set people $content(PEOPLE)
        set presence_id $content(PRESENCE_ID)
}

proc saveConfigFile { } {
        global FILENAME args

        array set content {}
        set content(HOST) $args(host)
        set content(PEOPLE) $args(people)
        set content(PRESENCE_ID) $args(presence_id)

        set fd [open $FILENAME w]
        puts $fd [array get content]
        close $fd
}

parseQuery
if { $args(command) == "save" } {
        saveConfigFile
}


proc getSysVarList { } {
        global res
        array set res [rega_script {
                string s_sysvar;
                object o_sysvar;
                foreach (s_sysvar, dom.GetObject (ID_SYSTEM_VARIABLES).EnumUsedIDs()) {
                        o_sysvar = dom.GetObject (s_sysvar);
                        WriteLine (o_sysvar.ID() # "\t" # o_sysvar.Name() # "\tSYSVAR\t" # o_sysvar.Value() # "\t");
                }
        }]
}



loadConfigFile
getSysVarList

set content [loadFile index.template.html]
regsub -all {<%host%>} $content $host content
regsub -all {<%people%>} $content $people content
regsub -all {<%presence_id%>} $content $presence_id content

regsub -all {<%sysvars%>} $content $res(STDOUT) content


puts $content
