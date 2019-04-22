#!/bin/sh
sh change-infra.sh MyBatis3
sed -i -e "s/macchinetta-web-blank-noorm-thymeleaf/macchinetta-web-blank-thymeleaf/g" pom.xml
sed -i -e "s/macchinetta-web-blank-noorm-thymeleaf/macchinetta-web-blank-thymeleaf/g" create-maven-archetype.sh
sed -i -e "s|Web Blank Project (No O/R Mapper)|Web Blank Project|g" pom.xml
sh create-maven-archetype.sh "$1" "$2"