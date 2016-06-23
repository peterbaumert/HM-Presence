#!/bin/tclsh

load tclrega.so

set MODULESLOC "/etc/config/addons/presence/modules"
set FILENAME "/etc/config/addons/presence/presence.conf"

set host 127.0.0.1
set people ""
set presence_id ""
set module ""

set args(command) "INV"
set args(host) $host
set args(people) $people
set args(presence_id) $presence_id
set args(module) $module

proc parseQuery { } {
        global args env

        if [info exists env(CONTENT_LENGTH)] {
                set forminput [read stdin $env(CONTENT_LENGTH)]
        } elseif [info exists env(QUERY_STRING)] {
                set forminput $env(QUERY_STRING)
        } else {
                return
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
        global FILENAME host people presence_id module

        set content(HOST) $host
        set content(PEOPLE) $people
        set content(PRESENCE_ID) $presence_id
        set content(MODULE) $module
        catch { array set content [loadFile $FILENAME] }

        set host $content(HOST)
        set people $content(PEOPLE)
        set presence_id $content(PRESENCE_ID)
        set module $content(MODULE)
}

proc saveConfigFile { } {
        global FILENAME args

        array set content {}
        set content(HOST) $args(host)
        set content(PEOPLE) $args(people)
        set content(PRESENCE_ID) $args(presence_id)
        set content(MODULE) $args(module)

        set fd [open $FILENAME w]
        puts $fd [array get content]
        close $fd
}

proc getModules { } {
        global module modules MODULESLOC
        set tmp [exec ls ${MODULESLOC}]
        set modules ""
        foreach {mod} $tmp {
                set selected ""
                if {![regexp -nocase {.*\.tcl} $mod]} {
                        continue
                }
                regsub -all {\.tcl} $mod "" mod
                if {$mod == $module} {
                        set selected "selected"
                }
                append modules "<option value=\"${mod}\" ${selected}>[string totitle ${mod}]</option>"
        }
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

parseQuery
if { $args(command) == "save" } {
        saveConfigFile
}

loadConfigFile
getSysVarList
getModules

set content [loadFile index.template.html]
regsub -all {<%host%>} $content $host content
regsub -all {<%people%>} $content $people content
regsub -all {<%presence_id%>} $content $presence_id content
regsub -all {<%sysvars%>} $content $res(STDOUT) content
regsub -all {<%modules%>} $content $modules content

puts $content
