###
# Absolute path to the media and download folders

MEDIA_ROOT="/srv/dev-disk-by-label-MediaVault/"
CARGO_ROOT="/srv/dev-disk-by-label-CargoBay/Transmission/"

MOVIES_DIR_NAME="Movies"
SERIES_DIR_NAME="Series"
COMPLETE_DIR_NAME="complete"
INCOMPLETE_DIR_NAME="incomplete"

# Users authorized to handle the media files
MEDIA_USER="pi"
MEDIA_GROUP="users"

# Permissions for the users and group
MEDIA_FILE_PERM="644"
MEDIA_DIR_PERM="755"
CLEAR_STICKY_BIT="00"

#
###

MOVIES_LOC="$MEDIA_ROOT$MOVIES_DIR_NAME"
SERIES_LOC="$MEDIA_ROOT$SERIES_DIR_NAME"

COMPLETE_LOC="$CARGO_ROOT$COMPLETE_DIR_NAME"
INCOMPLETE_LOC="$CARGO_ROOT$INCOMPLETE_DIR_NAME"

ALL_MEDIA="$MOVIES_LOC $SERIES_LOC"

STR_NEW_LINE="\n"

function getSeparatorLine() {
    sep=""
    for (( i=1; i<=${#1}; i++ ))
    do
	sep+="$2"
    done
    echo "$sep"
}

function echoWithSingleUnderline() {
    echo $1
    echo `getSeparatorLine "$1" "-"`
}

function echoWithDoubleUnderline() {
    echo $1
    echo `getSeparatorLine "$1" "="`
}

# Displays a text spinner just after the string passed as argument,
# if any. Spins as long as the process invoked just before the
# function call runs.
function spin() {
    prevPID=$!
    spinner='-\|/'
    #spinner='⠁⠂⠄⡀⢀⠠⠐⠈'
    i=0
    while kill -0 $prevPID 2>/dev/null
    do
	i=$(( (i+1) %4 ))
	echo -ne "\r$1${spinner:$i:1}"
	sleep .1
    done   
}

# Find all the text files in our media folders
function findTextFiles() {    
    find "$@" -type f \( -iname "*.txt" -o -iname "*.doc" -o -iname "*.docx" -o -iname "*.nfo" \)
}

# Find samples videos in our media folders
function findVideoSamples() {
    find "$@" -type f \( -iname "*.avi" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.wmv" \) -iname "*sample*" -size -50M
}

# Find all the small torrents ads and preserve extras/bonus/featurettes/...
function findAds() {
    find "$@" -type f \( -iname "*.avi" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.bmp" \) -size -5M -not \( -ipath "*extra*" -o -ipath "*feature*" -o -ipath "*short*" -o -ipath "*bonus*" \)
}

# Find torrents tmp (*.part) files
function findTorrentParts() {
    find "$@" -type f -iname "*.part"
}

# Find MacOS FS files
function findMacOSFiles() {
    find "$@" -type f -iname ".DS_Store"
}

# find empty directories
function findEmptyDirs() {
    find "$@" -type d -empty
}

# - Make user "pi" owner of all Media dirs and make them all executables
# - Make all Media files:
# -- readable for all
# -- writeable for owner only
function fixPermissions() {
    sudo chown -cR pi:users "$@"
    sudo find "$@" -type d -exec chmod -c "$CLEAR_STICKY_BIT$MEDIA_DIR_PERM" {} \;
    sudo find "$@" -type f -exec chmod -c "$CLEAR_STICKY_BIT$MEDIA_FILE_PERM" {} \;
}

# Finds files contained directly within the passed directories
function findFilesInDirs() {
    find "$@" -maxdepth 1 -type f
}

# Wraps all the files within the 1st level of the passed directories
# into their own directory, at the same path level.
# Such files must have an extension otherwise they won't be moved.
function wrapFilesInDirs() {
    findFilesInDirs "$@" |
	{
	    while read -r line ; do
		soloPath=${line%/*}
		soloName=${line##*/}
		soloFolder=${soloName%.*}
		# Make sure we proceeed only if the file to move has an extension
		# and allow to create a dir with a different name
		if [ "$soloFolder" != "$soloName" ]
		then
		    mkdir -v "$soloPath/$soloFolder"
		    mv -v "$line" "$soloPath/$soloFolder/."
		fi
	    done
	}
}

function findFilesWithWrongOwnership() {
    find "$@" -type f -not -group "$MEDIA_GROUP" -o -not -user "$MEDIA_USER"
}

function findDirsWithWrongOwnership() {
    find "$@" -type d -not -group "$MEDIA_GROUP" -o -not -user "$MEDIA_USER"
}

function findFilesWithWrongPermissions() {
    find "$@" -type f -not -perm "$MEDIA_FILE_PERM"
}

function findDirsWithWrongPermissions() {
    find "$@" -type d -not -perm "$MEDIA_DIR_PERM"
}

function findNonMediaFiles() {
    find "$@" -type f -not \( -iname "*.avi" -o -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.m4v" -o -iname "*.srt" -o -iname "*.sub" -o -iname "*.xml" -o -iname "*.sfv" -o -iname "*.idx" \)
}

function findFilesByName() {
    find $ALL_MEDIA -iname "*$1*"
}
