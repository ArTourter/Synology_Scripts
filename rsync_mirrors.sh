#!/bin/bash -l

set -e

TARGET=/volume1/web/mirrors
SLACKSRC=slackware.uk::slackware
SLACK_MULTI_SRV=slackware.uk
SLACK_MULTI_PATH=people/alien/multilib
SLACK_KTOWN_SRV=slackware.uk
SLACK_KTOWN_PATH=people/alien-kde
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
	[ ! -d $TARGET/$SLACK_MULTI_PATH ] && /bin/mkdir -p $TARGET/$SLACK_MULTI_PATH
	/bin/rsync \
		$RSYNC_OPTS --delete \
		--include="$VERSION/***" \
		--include='[A-Z]*' \
		--exclude='*' \
		$SLACK_MULTI_SRV::$SLACK_MULTI_PATH/ $TARGET/$SLACK_MULTI_PATH/
}

sync_ktown() {
	VERSION=${1:-"current"}
	[ ! -d $TARGET/$SLACK_KTOWN_PATH ] && /bin/mkdir -p $TARGET/$SLACK_KTOWN_PATH
	/bin/rsync \
		$RSYNC_OPTS --delete \
		--include='[A-Z]*' \
		--include="$VERSION/"{,'latest','5/'{,'x86_64***'}} \
		--exclude='*' \
		$SLACK_KTOWN_SRV::$SLACK_KTOWN_PATH/ $TARGET/$SLACK_KTOWN_PATH/
}

sync_texlive () {
	[ ! -d $TARGET/texlive ] && /bin/mkdir $TARGET/texlive
	/bin/rsync \
		$RSYNC_OPTS --delete \
		$TEXLIVESRC $TARGET/texlive/
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
