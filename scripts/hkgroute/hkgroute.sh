#!/bin/bash -e
set -o pipefail

CUR_DIR=$(pwd)
TMP_DIR=$(mktemp -d /tmp/hkgroute.XXXXXX)

SRC_URL_1="https://ftp.apnic.net/stats/apnic/delegated-apnic-latest"
DEST_FILE_1="dist/hkgroute/hkgroute.txt"
DEST_FILE_2="dist/hkgroute/hkgroute6.txt"

fetch_src() {
  cd $TMP_DIR

  curl -sSL $SRC_URL_1 -o apnic.txt

  cd $CUR_DIR
}

gen_list_v4() {
  cd $TMP_DIR

  # convert to cidr format
  cat apnic.txt | grep ipv4 | grep HK | awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' > apnic-v4.tmp

  # ipv4 cidr merge
  cat apnic-v4.tmp | $CUR_DIR/tools/ip-dedup/obj/ip-dedup -4 > hkgroute.txt

  cd $CUR_DIR
}

gen_list_v6() {
  cd $TMP_DIR

  # convert to cidr format
  cat apnic.txt | grep ipv6 | grep HK | awk -F\| '{ printf("%s/%d\n", $4, $5) }' > apnic-v6.tmp

  # ipv6 cidr merge
  cat apnic-v6.tmp | $CUR_DIR/tools/ip-dedup/obj/ip-dedup -6 > hkgroute6.txt

  cd $CUR_DIR
}

copy_dest() {
  install -D -m 644 $TMP_DIR/hkgroute.txt $DEST_FILE_1
  install -D -m 644 $TMP_DIR/hkgroute6.txt $DEST_FILE_2
}

clean_up() {
  rm -r $TMP_DIR
  echo "[$(basename $0 .sh)]: done."
}

fetch_src
gen_list_v4
gen_list_v6
copy_dest
clean_up
