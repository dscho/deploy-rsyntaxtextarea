#!/bin/sh

die () {
	echo "$*" >&2
	exit 1
}

test $# = 1 ||
die "Usage: $0 <version>"

version="$1"

base=http://sourceforge.net/projects/rsyntaxtextarea/files/rsyntaxtextarea/
jar=$base/"$version"/rsyntaxtextarea_"$version".zip/download
source=$base/"$version"/rsyntaxtextarea_"$version"_Source.zip/download

rm -rf target src &&

mkdir -p src/main &&
mkdir -p src/test &&
mkdir -p target &&

curl -sL "$source" > target/rsyntaxtextarea-"$version"-source.zip &&
unzip -d src/ target/rsyntaxtextarea-"$version"-source.zip src/\* &&
mv src/src src/main/java &&
unzip target/rsyntaxtextarea-"$version"-source.zip test/\* &&
mv test src/test/java &&

mvn source:jar source:test-jar javadoc:jar &&

rm -rf src &&
curl -sL "$jar" > target/rsyntaxtextarea-"$version".zip &&
unzip -p target/rsyntaxtextarea-"$version".zip rsyntaxtextarea.jar \
	> target/rsyntaxtextarea-"$version".jar &&

echo "Ready to sign and deploy... please enter signer information" >&2

printf '\nemail: ' >&2
read keyname
printf '\npass phrase: ' >&2
stty -echo
read passphrase
stty echo

args="-Psonatype-oss-release gpg:sign-and-deploy-file -Dgpg.ascDirectory=target"
args="$args -Dgpg.keyname=$keyname -Dgpg.passphrase=$passphrase"
args="$args -DrepositoryId=imagej.thirdparty"
args="$args -Durl=dav:http://maven.imagej.net/content/repositories/thirdparty"

mvn $args -DpomFile=pom.xml -Dfile=target/rsyntaxtextarea-"$version".jar ||
die "Could not deploy main artifact!"

# Unfortunately, we cannot use -DpomFile=pom.xml -DgeneratePom=false because
# the -DgeneratePom=false setting is ignored in that case
args="$args -DgroupId=com.fifesoft -DartifactId=rsyntaxtextarea"
args="$args  -Dversion=$version -Dpackaging=jar -DgeneratePom=false"
mvn $args -Dclassifier=javadoc \
       -Dfile=target/rsyntaxtextarea-"$version"-javadoc.jar &&
mvn $args -Dclassifier=sources \
    -Dfile=target/rsyntaxtextarea-"$version"-sources.jar &&

echo "Deployed!" >&2
