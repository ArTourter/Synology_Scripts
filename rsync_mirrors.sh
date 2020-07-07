#!/bin/bash -l

set -e

TARGET=/volume1/web/mirrors
SLACKSRC=slackware.uk::slackware
SLACKREL=slackware.uk::people
TEXLIVESRC=distrib-coffee.ipsl.jussieu.fr::pub/mirrors/ctan/systems/texlive/tlnet

[ -f $TARGET/.syncing ] && exit 0

/bin/touch $TARGET/.syncing

RSYNC_OPTS="-avh --progress --stats"

[ ! -d "$TARGET" ] && /bin/mkdir -p $TARGET

sync_slackware () {
	VERSION=$1
	[ ! -d $TARGET/slackware ] && /bin/mkdir $TARGET/slackware
	/bin/rsync $RSYNC_OPTS --exclude='source/***' --delete $SLACKSRC/slackware64-$VERSION $TARGET/slackware/
}

sync_multilib () {
	VERSION=$1
	PATH=alien/multilib
	[ ! -d $TARGET/$PATH ] && /bin/mkdir -p $TARGET/people/$PATH
	/bin/rsync $RSYNC_OPTS --delete $SLACKREL/$PATH/$VERSION $TARGET/people/$PATH/
}

sync_ktown() {
	PATH=alien-kde/current/latest
	[ ! -d $TARGET/$PATH ] && /bin/mkdir -p $TARGET/people/$PATH
	/bin/rsync $RSYNC_OPTS --delete $SLACKREL/$PATH/x86_64 $TARGET/people/$PATH/
}

sync_texlive () {
	[ ! -d $TARGET/texlive ] && /bin/mkdir $TARGET/texlive
	/bin/rsync $RSYNC_OPTS --delete $TEXLIVESRC $TARGET/texlive/
}

echo "syncing slackware64 current ..."
sync_slackware current

echo "syncing multilib current ..."
sync_multilib current

echo "syncing slackware64 14.2 ..."
sync_slackware 14.2

echo "syncing multilib 14.2 ..."
sync_multilib 14.2

echo "syncing ktown ..."
sync_ktown

echo "syncing TeXLive"
sync_texlive

/bin/rm $TARGET/.syncing
