#!/bin/bash

source /home/pi/Utils/_include.sh

PROGNAME=$0

usage() {
    cat << EOF >&2
Usage: $PROGNAME [-a] [-d] [-r] [-f <dir_1> [<dir_2>] .. [<dir_n>]]

Scans files and folders within the folders passed via the -f option.
The passed folders are meant to contain media such as movies and TV 
series.

By default (i.e. when no option is specified) it will only display
the following information on:
 > Count and size of files and directories that are potentially
   undesirable:
  >> not a media type
  >> media but samples or ads
  >> unfinished torrents parts
  >> empty directories
 > Count and size of files and directories that show wrong ownership
   or persmission:
  >> Files within the first level of passed directory. The repair
     option would wrapped them up into their own directory
  >> Files not owned bi... TODO FINISH ME!
  
-f <dir_1> <dir_2>... : space seprated list of directories to process
                   -a : displays the full path of each found result
                   -d : deletes each found result
		   -r : repairs permissions and folders structures:
                        - Set all target files and dirs recursively to
                          owner 'pi' and group 'users'
                        - Set all target dirs to 755
                        - Set all target files to 644
                        - Move all files that are
                        -- having an extension 
                        -- located directly at the 1st level of the
                           target dirs
                          into their own folder, i.e. a folder named
                          as the file without its extension

EOF
    exit 1
}

DIRS=$ALL_MEDIA

while getopts f:radht? o; do
    case $o in
	(a) ALL=1;;
	(d) DELETE=1;;
	(f) DIRS=$OPTARG;;
	(r) REPAIR=1;;
	(t) TEST=1;; #just for testing purpose
	(h|?|*) usage;;
	esac
done

echo -e "Processing dirs: $DIRS\n"

if [ ! -z "$TEST" ] && [ "$TEST" -eq 1 ]
then
    echo "Testing some stuff..."
    findNonMediaFiles $DIRS
    exit
fi


function processFindFunction() {
    FUNCTION_NAME=$1
    EXTRA_TXT=$2
    DELETE_FLAG=$3
    resultsSize=0;
    resultsCount=0;

    # Show found files count
    echoWithSingleUnderline "Looking for $EXTRA_TXT"
    
    # Process each line found depending on our options
    $FUNCTION_NAME $DIRS |
	{ # We group the code in brackets to ensure our variables survive outside of the while loop
	    while read -r line ; do
		# Store its size
		resultsSize=$((`du -bs "$line" | awk '{print $1}'` + resultsSize))
		# Count it
		((resultsCount++))
		# Display search result if needed
		if [ ! -z "$ALL" ] && [ "$ALL" -eq 1 ]
		then
		    du -sh "$line"
		fi
		# Delete search result if needed
		if [ ! -z "$DELETE" ] && [ "$DELETE" -eq 1 ] && [ ! -z "$DELETE_FLAG" ] && [ "$DELETE_FLAG" -eq 1 ]
		then
		    rm -vrf "$line"
		fi	
	    done
	    
	    echoWithSingleUnderline "Found $resultsCount $EXTRA_TXT (`echo $resultsSize | numfmt --to=iec` total)"
	    echo -ne "$STR_NEW_LINE"
	}
}

echoWithDoubleUnderline "The following results can be cleaned up with the -d option"
echo -ne "$STR_NEW_LINE"

processFindFunction "findTextFiles" "text files" 1
processFindFunction "findVideoSamples" "video samples" 1
processFindFunction "findAds" "video ads" 1
processFindFunction "findTorrentParts" "torrents parts" 1
processFindFunction "findMacOSFiles" "MacOS FS files" 1
processFindFunction "findEmptyDirs" "empty directories" 1

echoWithDoubleUnderline "The following results can be fixed with the -r option"
echo -ne "$STR_NEW_LINE"

processFindFunction "findFilesInDirs" "files not wrapped in dirs" 0
processFindFunction "findFilesWithWrongOwnership" "files with wrong ownership (should be $MEDIA_USER:$MEDIA_GROUP)" 0
processFindFunction "findDirsWithWrongOwnership" "dirs with wrong ownership (should be $MEDIA_USER:$MEDIA_GROUP)" 0
processFindFunction "findFilesWithWrongPermissions" "files with wrong permissions (should be $MEDIA_FILE_PERM)" 0
processFindFunction "findDirsWithWrongPermissions" "dirs with wrong permissions (should be $MEDIA_DIR_PERM)" 0

if [ ! -z "$REPAIR" ] && [ "$REPAIR" -eq 1 ]
then
    echoWithSingleUnderline "Repairing file permissions and folder structure..."
    fixPermissions $DIRS
    wrapFilesInDirs $DIRS
    echoWithSingleUnderline "...done reparing."
fi

