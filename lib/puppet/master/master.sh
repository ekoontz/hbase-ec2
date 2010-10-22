# create the tars that are referenced in ../manifests/site.pp, ../hadoop.sh, and ../fileserver.conf
mkdir -p /tmp/puppetfiles
tar  --exclude=".git*" -cvzf /tmp/puppetfiles/hadoop-common.tar.gz hadoop-common
tar  --exclude=".git*" -cvzf /tmp/puppetfiles/hbase.tar.gz hbase
tar -cvfz /tmp/puppetfiles/m2.tar.gz .m2

tar -c --exclude=".git*" -z -f /tmp/puppetfiles/jre.tar.gz jre*
cp ../hadoop.sh /tmp/puppetfiles
