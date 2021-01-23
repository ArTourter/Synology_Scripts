#!/bin/bash -l

set -eE

TARGET=/volume1/web/mirrors
SLACKSRC=rsync.osuosl.org::slackware
SLACK_MULTI_SRV=slackware.nl
SLACK_MULTI_PATH=mirrors/people/alien/multilib
SLACK_MULTI_LPATH=people/alien/multilib
SLACK_KTOWN_SRV=slackware.nl
SLACK_KTOWN_PATH=mirrors/alien-kde
SLACK_KTOWN_LPATH=people/alien-kde
TEXLIVE_SRV=rsync.cs.uu.nl
TEXLIVE_PATH=CTAN/systems/texlive/tlnet

[ -f $TARGET/.syncing ] && exit 0

/bin/touch $TARGET/.syncing

RSYNC_OPTS="-avh --progress --stats --timeout=60"

[ ! -d "$TARGET" ] && /bin/mkdir -p $TARGET

on_exit () {
	echo "This script has exited in error"
	[ -f $TARGET/.syncing ] && /bin/rm -f $TARGET/.syncing
}

trap on_exit ERR

sync_slackware () {
	VERSION=$1
	[ ! -d $TARGET/slackware ] && /bin/mkdir $TARGET/slackware
	/bin/rsync $RSYNC_OPTS --exclude='source/***' --delete $SLACKSRC/slackware64-$VERSION $TARGET/slackware/
}

sync_multilib () {
	VERSION=$1
	[ ! -d $TARGET/$SLACK_MULTI_LPATH ] && /bin/mkdir -p $TARGET/$SLACK_MULTI_LPATH
	/bin/rsync \
		$RSYNC_OPTS --delete \
		--include="$VERSION/***" \
		--include='[A-Z]*' \
		--exclude='*' \
		$SLACK_MULTI_SRV::$SLACK_MULTI_PATH/ $TARGET/$SLACK_MULTI_LPATH/
}

sync_ktown() {
	VERSION=${1:-"current"}
	[ ! -d $TARGET/$SLACK_KTOWN_LPATH ] && /bin/mkdir -p $TARGET/$SLACK_KTOWN_LPATH
	/bin/rsync \
		$RSYNC_OPTS --delete \
		--include='[A-Z]*' \
		--include="$VERSION/"{,'latest','5/'{,'x86_64***'}} \
		--exclude='*' \
		$SLACK_KTOWN_SRV::$SLACK_KTOWN_PATH/ $TARGET/$SLACK_KTOWN_LPATH/
}

sync_texlive () {
	[ ! -d $TARGET/texlive ] && /bin/mkdir $TARGET/texlive
	/bin/rsync \
		$RSYNC_OPTS --delete \
		$TEXLIVE_SRV::$TEXLIVE_PATH $TARGET/texlive/
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
