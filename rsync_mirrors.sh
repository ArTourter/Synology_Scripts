#!/bin/bash -l

#set -eE

TARGET=/volume1/web/mirrors

SLACKSRC=rsync.osuosl.org::slackware
SLACK_MULTI_SRV=slackware.nl
SLACK_MULTI_PATH=mirrors/people/alien/multilib
SLACK_MULTI_LPATH=people/alien/multilib
SLACK_KTOWN_SRV=slackware.nl
SLACK_KTOWN_PATH=mirrors/alien-kde
SLACK_KTOWN_LPATH=people/alien-kde
#TEXLIVE_SRV=rsync.cs.uu.nl
#TEXLIVE_SRV=texlive.info
#TEXLIVE_PATH=CTAN/systems/texlive/tlnet
TEXLIVE_SRV=distrib-coffee.ipsl.jussieu.fr
TEXLIVE_PATH=ctan/systems/texlive/tlnet
MACTEX_PATH=ctan/systems/mac/mactex
TLPRETEST_SRV=texlive.info
TLPRETEST_PATH=tlpretest

SLACKVERS=(current 15.0 14.2)
PRETEST=0
MACTEX=0
KTOWN=0

[ -f $TARGET/.syncing ] && exit 0

/bin/touch $TARGET/.syncing

RSYNC_OPTS="-Pavh --stats --timeout=60 --partial-dir=.rsync-partial"

[ ! -d "$TARGET" ] && /bin/mkdir -p $TARGET

on_exit () {
  echo "This script has exited in error"
  [ -f $TARGET/.syncing ] && /bin/rm -f $TARGET/.syncing
}

trap on_exit ERR

sync_slackware () {
  VERSION=$1
  [ ! -d $TARGET/slackware ] && /bin/mkdir $TARGET/slackware
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --exclude='source/***' --delete \
      $SLACKSRC/slackware64-$VERSION $TARGET/slackware/
    RC=$?
  done
}

sync_multilib () {
  VERSION=$1
  [ ! -d $TARGET/$SLACK_MULTI_LPATH ] && /bin/mkdir -p $TARGET/$SLACK_MULTI_LPATH
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete \
      --include="$VERSION/***" \
      --include='[A-Z]*' \
      --exclude='*' \
      $SLACK_MULTI_SRV::$SLACK_MULTI_PATH/ $TARGET/$SLACK_MULTI_LPATH/
    RC=$?
  done
}

sync_ktown() {
  VERSION=${1:-"current"}
  [ ! -d $TARGET/$SLACK_KTOWN_LPATH ] && /bin/mkdir -p $TARGET/$SLACK_KTOWN_LPATH
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete \
      --include='[A-Z]*' \
      --include="$VERSION/"{,'latest','5/'{,'x86_64***'}} \
      --exclude='*' \
      $SLACK_KTOWN_SRV::$SLACK_KTOWN_PATH/ $TARGET/$SLACK_KTOWN_LPATH/
    RC=$?
  done
}

sync_slackpkgplus() {
  #[ ! -d $TARGET/] && /bin/mkdir -p $TARGET/$SLACK_KTOWN_LPATH
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete \
      $SLACK_KTOWN_SRV::mirrors/slackpkgplus* $TARGET/
    RC=$?
  done
}

sync_alien_sbrepos () {
  VERSION=$1
  [ ! -d $TARGET/people/alien/sbrepos ] && /bin/mkdir -p $TARGET/people/alien/sbrepos
  [ ! -d $TARGET/people/alien/restricted_sbrepos ] && /bin/mkdir -p $TARGET/people/alien/restricted_sbrepos
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete \
      --include='/[A-Z]*' \
      --include='current/'{,'x86_64/'{,'*.*'.'libreoffice/***','chromium/***'}}
      --exclude='*' \
      $SLACK_MULTI_SRV::people/alien/sbrepos/ $TARGET/people/alien/sbrepos/
    RC=$?
  done
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete \
      --include='/[A-Z]*' \
      --include='current/'{,'x86_64/'{,'*.*','vlc/***','handbrake/***'}}
      --exclude='*' \
      $SLACK_MULTI_SRV::people/alien/restricted_sbrepos/ $TARGET/people/alien/restricted_sbrepos/
    RC=$?
  done
}

sync_texlive () {
  [ ! -d $TARGET/texlive ] && /bin/mkdir $TARGET/texlive
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete \
      $TEXLIVE_SRV::$TEXLIVE_PATH $TARGET/texlive/
    RC=$?
  done
}

sync_mactex () {
  [ ! -d $TARGET/texlive ] && /bin/mkdir $TARGET/texlive
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete \
      $TEXLIVE_SRV::$MACTEX_PATH $TARGET/texlive/
    RC=$?
  done
}

sync_tlpretest () {
  [ ! -d $TARGET/texlive/tlpretest ] && /bin/mkdir $TARGET/texlive/tlpretest
  RC=1
  while (( RC != 0 )); do
    /bin/rsync \
      $RSYNC_OPTS --delete --exclude="mactex*" \
      $TLPRETEST_SRV::$TLPRETEST_PATH $TARGET/texlive/tlpretest/
    RC=$?
  done
}

for ver in ${SLACKVERS[@]}; do
  echo "syncing slackware64 $ver ..."
  sync_slackware $ver
  echo ""
done

for ver in ${SLACKVERS[@]}; do
  echo "syncing multilib $ver ..."
  sync_multilib $ver
  echo ""
done

echo "syncing slackpkgplus ..."
sync_slackpkgplus
echo ""

if (( $KTOWN )); then
  echo "syncing ktown ..."
  sync_ktown
  echo ""
fi

echo "syncing TeXLive"
sync_texlive
echo ""

if (( $MACTEX )); then
  echo "syncing MacTeX"
  sync_mactex
  echo ""
fi

if (( $PRETEST )); then
  echo "syncing TeXLive Pretest"
  sync_tlpretest
  echo ""
fi

/bin/rm $TARGET/.syncing

# vim: ts=2 sw=2 et
