#!/bin/sh
set -e

DEPLOY=$1
REPOSITORY=$2
ORM=$3

if [ -z ${ORM} ]; then
  ORM="NoORM"
fi

KEYWORD="REMOVE THIS LINE IF YOU USE ${ORM}"
TARGET="src pom.xml"

# start create tmp directory
rm -rf ./tmp
mkdir tmp
cp -r pom.xml tmp
cp -r src tmp

# artifactId
if [ "${ORM}" != "NoORM" ]; then
  ARTIFACT_ID=macchinetta-web-blank-thymeleaf
else
  ARTIFACT_ID=macchinetta-web-blank-${ORM,,}-thymeleaf
fi
echo create ${ARTIFACT_ID}

# copy infra
if [ "${ORM}" != "NoORM" ]; then
  cp -r infra/${ORM,,}/META-INF/* tmp/src/main/resources/META-INF
  cp -r infra/common/database tmp/src/main/resources
  cp -r infra/common/META-INF tmp/src/main/resources
  cp -r infra/${ORM,,}/xxxxxx tmp/src/main/resources
fi

pushd tmp

if [ "${ORM}" != "NoORM" ]; then
  # remove comment out
  sed -i -e "/${KEYWORD}/d" `grep -rIl "${ORM}" ${TARGET}`

  # sed pom.xml
  sed -i -e "s/<artifactId>macchinetta-web-blank-noorm-thymeleaf/<artifactId>${ARTIFACT_ID}/g" pom.xml
  sed -i -e "s|Web Blank Project (No O/R Mapper)|Web Blank Project|g" pom.xml
else
  # delete database info if JPA or Mybatis3 is not used. (NoORM)
  sed -i -e '/Begin Database/,/End Database/d' pom.xml
  sed -i -e '/postgresql.version/d' pom.xml
  sed -i -e '/ojdbc.version/d' pom.xml
fi

# rename "projectName" in filename to replace by ${artifactId}
mv src/main/resources/META-INF/spring/projectName-domain.xml src/main/resources/META-INF/spring/__artifactId__-domain.xml
mv src/main/resources/META-INF/spring/projectName-infra.xml src/main/resources/META-INF/spring/__artifactId__-infra.xml
mv src/main/resources/META-INF/spring/projectName-codelist.xml src/main/resources/META-INF/spring/__artifactId__-codelist.xml

# if Mybatis3 is used
if [ -e src/main/resources/META-INF/spring/projectName-env.xml ];then
  mv src/main/resources/META-INF/spring/projectName-env.xml src/main/resources/META-INF/spring/__artifactId__-env.xml
fi
if [ -e src/main/resources/META-INF/spring/projectName-infra.properties ];then
  mv src/main/resources/META-INF/spring/projectName-infra.properties src/main/resources/META-INF/spring/__artifactId__-infra.properties
fi

if [ -d src/main/resources/xxxxxx ];then
  echo "rename to __packageInPathFormat__"
  mkdir -p src/main/resources/__packageInPathFormat__
  mv src/main/resources/xxxxxx/yyyyyy/zzzzzz/domain src/main/resources/__packageInPathFormat__/
  rm -rf src/main/resources/xxxxxx
fi

sed -i -e "s/com\.github\.macchinetta\.blank/xxxxxx.yyyyyy.zzzzzz/g" pom.xml
sed -i -e "s/<artifactId>${ARTIFACT_ID}/<artifactId>projectName/g" pom.xml

if [ "${REPOSITORY}" = "central" ]; then
  PROFILE="-P central"
fi

mvn archetype:create-from-project ${PROFILE}

pushd target/generated-sources/archetype

sed -i -e "s/xxxxxx\.yyyyyy\.zzzzzz/com.github.macchinetta.blank/g" pom.xml
sed -i -e "s/<artifactId>projectName/<artifactId>${ARTIFACT_ID}/g" pom.xml

if [ "${REPOSITORY}" = "central" ]; then
  # add plugins to deploy to Maven Central Repository
  LF=$(printf '\\\012_')
  LF=${LF%_}
  
  REPLACEMENT_TAG="    <plugins>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}      <plugin>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <groupId>org.sonatype.plugins<\/groupId>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <artifactId>nexus-staging-maven-plugin<\/artifactId>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <version>1.6.8<\/version>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <extensions>true<\/extensions>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <configuration>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}          <serverId>ossrh<\/serverId>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}          <nexusUrl>https:\/\/oss.sonatype.org\/<\/nexusUrl>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}          <autoReleaseAfterClose>true<\/autoReleaseAfterClose>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <\/configuration>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}      <\/plugin>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}      <plugin>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <groupId>org.apache.maven.plugins<\/groupId>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <artifactId>maven-gpg-plugin<\/artifactId>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <version>3.0.1<\/version>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <executions>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}          <execution>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}            <id>sign-artifacts<\/id>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}            <phase>verify<\/phase>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}            <goals>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}              <goal>sign<\/goal>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}            <\/goals>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}            <configuration>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}              <gpgArguments>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}                <arg>--pinentry-mode<\/arg>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}                <arg>loopback<\/arg>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}              <\/gpgArguments>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}            <\/configuration>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}          <\/execution>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}        <\/executions>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}      <\/plugin>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}    <\/plugins>${LF}"
  REPLACEMENT_TAG="${REPLACEMENT_TAG}  <\/build>"
  
  sed -i -e "s/  <\/build>/${REPLACEMENT_TAG}/" pom.xml
fi

if [ "${DEPLOY}" = "deploy" ]; then
  mvn deploy
else
  mvn install
fi

popd
popd
