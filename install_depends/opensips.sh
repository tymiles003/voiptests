#!/bin/sh

set -e

BASEDIR="${BASEDIR:-$(dirname -- "${0}")/..}"
BASEDIR="$(readlink -f -- ${BASEDIR})"

. ${BASEDIR}/functions

if [ -e "${BUILDDIR}/dist" ]
then
  rm -rf "${BUILDDIR}/dist"
fi
mkdir "${BUILDDIR}/dist"
cd "${BUILDDIR}/dist"

if [ "${MM_TYPE}" = "opensips" ]
then
  git clone -b "${MM_BRANCH}" git://github.com/OpenSIPS/opensips.git
  perl -pi -e 's|-O[3-9]|-O0 -g3|' ${BUILDDIR}/dist/opensips/Makefile.defs
fi
git clone git://github.com/sippy/b2bua.git
git clone git://github.com/sippy/rtpproxy.git
if [ "${MM_TYPE}" = "kamailio" ]
then
  git clone -b "${MM_BRANCH}" git://git.sip-router.org/kamailio kamailio
  perl -pi -e 's|-O[3-9]|-O0 -g3|' ${BUILDDIR}/dist/kamailio/Makefile.defs
fi

##bash
if [ "${MM_TYPE}" = "opensips" ]
then
  ${MAKE_CMD} -C "${BUILDDIR}/dist/opensips" CC_NAME=gcc CC="${CC}" all modules
fi
if [ "${MM_TYPE}" = "kamailio" ]
then
  ${MAKE_CMD} -C "${BUILDDIR}/dist/kamailio" CC_NAME=gcc CC="${CC}" all modules
fi
cd rtpproxy
./configure
${MAKE_CMD} all
( cat ${BASEDIR}/install_depends/b2bua_radius.py.fix; \
  grep -v '^from sippy.Rtp_proxy_client import Rtp_proxy_client' ${BASEDIR}/dist/b2bua/sippy/b2bua_radius.py ) | \
  sed "s|%%SIPPY_ROOT%%|${BASEDIR}/dist/b2bua|" > ${BASEDIR}/dist/b2bua/sippy/b2bua_test.py
chmod 755 ${BASEDIR}/dist/b2bua/sippy/b2bua_test.py
