# -*- tcl -*-
## (c) 2013 Andreas Kupries
# # ## ### ##### ######## ############# #####################

## The background for this package is the management of versioned
## "artifacts", where each artifact consists of a series of "changes",
## and versioning is controlled by the order of these changes in time.

## This package provides methods to parse ticket change artifacts [1]
## of the Fossil SCM [2] into in-memory change::container's (see
## companion package of the same name), and the reverse, generating the
## Fossil representation from a container.

# [1] http://www.fossil-scm.org/index.html/doc/trunk/www/fileformat.wiki#tktchng
# [2] http://www.fossil-scm.org


# # ## ### ##### ######## ############# #####################
## File Format Recap (Details at [1]).

# Card types. Shown in alphabetical order. Same order in the artifact.
#
## 1x D <timestamp>
## Nx J [-+]?<name> <data>    | lexicographic order by name and data.
## 1x K name
## 1x U user
## 1x Z md5-checksum
##

# text. The following escape sequences are applied to the text:
# A space (ASCII 0x20) is represented as "\s" (ASCII 0x5C, 0x73).
# A newline (ASCII 0x0a) is "\n" (ASCII 0x5C, x6E).
# A backslash (ASCII 0x5C) is represented as two backslashes "\\".
# Apart from space and newline, no other whitespace characters are
# allowed in the check-in comment. Nor are any unprintable characters
# allowed in the comment.

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require md5 2

namespace eval ::change::fossil {
    namespace export {[a-z]*}
    namespace ensemble create
}

# # ## ### ##### ######## ############# #####################
## API. Parsing. Fossil to Container.

proc ::change::fossil::parse {container text} {
    return -code error -errorcode {NOT YET IMPLEMENTED} not-yet-implemented
}

# # ## ### ##### ######## ############# #####################
## API. Generation. Container to Fossil.

proc ::change::fossil::format {container} {
    append content [D [$container when?]]
    foreach field [lsort [$container names]] {
	append content \
	    [J $field \
		 [$container type? $field] \
		 [$container get   $field]]
    }
    append content [K [$container id?]]
    append content [U [$container owner?]]
    Z $content
}

# # ## ### ##### ######## ############# #####################
## Helpers.

# J --
#
#	Makes a J (data field) card for Fossil.
#
# Parameters:

proc J {field type content} {
    return "J $type[Armour $field] [Armour $content]\n"
}

# K --
#
#	Makes a K (identifier) card for Fossil.
#
# Parameters:
#	id - artifact ID

proc K {id} {
    return "K $id\n"
}

# D --
#
#	Makes a D (timestamp) card for Fossil

proc ::change::fossil::D {date} {
    set card {D }
    append card [clock format $date -format %Y-%m-%dT%H:%M:%S -timezone :UTC] \n
    return $card
}

# Z --
#	Add a Z (checksum) card for Fossil

proc ::change::fossil::Z {content} {
    set zhash [string tolower [md5::md5 -hex $content]]
    append content "Z " $zhash \n
    return $content
}

# Armour --
#
#	Armours a string to include on a card in a Fossil (ticket change) artifact.
#
# Parameters:
#	string - String to armour
#
# Results:
#	Returns the string with whitespace characters and backslashes
#	replaced by backslash escapes.

proc ::change::fossil::Armour {string} {
    variable armour
    return [encoding convertto utf-8 [string map $armour $string]]
}

# # ## ### ##### ######## ############# #####################
## State and constants.

namespace eval ::change::fossil {
    variable armour [list { } \\s \n \\n \t \\t \r \\r]
}

# # ## ### ##### ######## ############# #####################
package provide change::fossil 0
return
