# -*- tcl -*-
## (c) 2013 Andreas Kupries
# # ## ### ##### ######## ############# #####################

## The background for this package is the management of versioned
## "artifacts", where each artifact consists of a series of "changes",
## and versioning is controlled by the order of these changes in time.

## This package provides a container class for the in-memory storage,
## manipulation, and query of a single change. It is modeled after the
## 'Ticket Change' manifests [1] of the Fossil SCM [2], and the
## companion package 'changes::fossil' actually provides method to
## convert between container instances and the fossil artifact format
## for [1]. With some caveats:
## (a) The packages do not enforce that change identifiers are exactly
##     40 hex characters.
## (b) The packages allow for the form of -fieldname to drop fields.
##     Use case: schema change mid-flight. This is not supported by
##     Fossil.

# [1] http://www.fossil-scm.org/index.html/doc/trunk/www/fileformat.wiki#tktchng
# [2]  http://www.fossil-scm.org

# # ## ### ##### ######## ############# #####################
## Requisites

package require Tcl 8.5
package require TclOO
package require md5 2

# # ## ### ##### ######## ############# #####################
## Implementation

oo::class create ::change::container {
    # # ## ### ##### ######## #############
    ## API. Lifecycle.

    # new collection for identified artifact
    constructor {identifier} {
	set midentifier  $identifier
	set myfieldvalue {}
	set myfieldtype  {}
	set myowner      $::tcl_platform(user)
	set mywhen       [clock secnds]
	return
    }

    # # ## ### ##### ######## #############
    ## API. Content declaration and manipulation

    # set owner and point-in-time for the collection.
    # defaults are tcl_platform(user) and [clock seconds]
    method owner {name} { set myowner $name }
    method when  {time} { set mywhen  $time }

    # register fields with the collection.

    # The 'type' values '=', '+', and '-' are modifiers specifying how
    # the field in this collection interacts with a field of the same
    # name in collections of the identified artifact coming before it
    # in time. i.e. they influence the versioning.
    # = : replace old value
    # + : append to old value
    # - : drop field

    method field {type fieldname} {
	if {$type ni {+ - =}} {
	    return -code error -errocode {CHANGE CONTAINER BAD TYPE} \
		"Bad field type \"$type\", expected one of +, -, or ="
	}
	dict set myfieldtype $fieldname $type
	if {$type eq "-"} {
	    dict unset myfieldtype $fieldname
	} elseif {![dict exists $myfieldvalue $fieldname]} {
	    dict set myfieldtype $fieldname {}
	}
	return
    }

    # add/query data to registered fields. available only to + and =
    # fields. append/set are _local_ modifiers/operations influencing
    # how existing field data in the collection is handled. This is
    # separate from the (=|+|-) type influencing how the stored
    # collection interacts with previous collections of the same
    # artifact.

    method lappend {fieldname text} {
	my HasValue
	dict lappend myfieldtype $fieldname $text
	return
    }

    method append  {fieldname text} {
	my HasValue
	dict append myfieldtype $fieldname $text
	return
    }

    method set {fieldname text} {
	my HasValue
	dict set myfieldtype $fieldname $text
	return
    }

    # Convenience method
    method set-date {fieldname epoch} {
	my set $fieldname [clock format $epoch -format %Y-%m-%dT%H:%M:%S -timezone :UTC]
    }

    # # ## ### ##### ######## #############
    ## Content introspection.

    method id?    {} { return $myidentifier }
    method owner? {} { return $myowner }
    method when?  {} { return $mywhen }

    method names {} { dict keys $myfieldtype }

    method exists {fieldname} { dict exists $mfieldtype $fieldname }
    method type?  {fieldname} { dict get $mfieldtype $fieldname }

    method get {fieldname} {
	my HasValue
	dict get $mfieldvalue $fieldname
    }

    # # ## ### ##### ######## #############

    method HasValue {fieldname} {
	if {[dict get $myfieldtype] ne "-"} return
	return -code error -errocode {CHANGE CONTAINER INVALID WRITE} \
	    "Access denied to field of type \"-\""
    }

    # # ## ### ##### ######## #############
    ##

    variable myowner mywhen myfieldvalue myfieldtype myidentifier

    ##
    # # ## ### ##### ######## #############
}


# # ## ### ##### ######## ############# #####################
package provide change::container 0
return
