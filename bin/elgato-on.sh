#!/bin/bash
host=$1

if [ -z "${host}" ] ; then
	echo provide a light hostname or ip address
	exit 1
fi

curl --location --request PUT "http://${host}:9123/elgato/lights" \
--header 'Content-Type: application/json' \
--data-raw '{"lights":[{"brightness":100,"temperature":255,"on":1}],"numberOfLights":1}'
