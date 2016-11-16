#!/bin/bash

set -e


: ${SUBRION_DB_HOST:=mysql}
: ${SUBRION_DB_USER=${MYSQL_ENV_MYSQL_USER:-root}}
if [ "$SUBRION_DB_USER" = 'root' ]; then
	: ${SUBRION_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
fi
: ${SUBRION_DB_PASSWORD:=$MYSQL_ENV_MYSQL_PASSWORD}
: ${SUBRION_DB_NAME=${SUBRION_DB_NAME:-subrion}}


if [ -z "$SUBRION_DB_PASSWORD" ]; then
	echo >&2 'error: missing required SUBRION_DB_PASSWORD environment variable'
	echo >&2 '  Did you forget to -e SUBRION_DB_PASSWORD=... ?'
	echo >&2
	echo >&2 '  (Also of interest might be SUBRION_DB_USER and SUBRION_DB_NAME.)'
	exit 1
fi

if ! [ -e index.php ]; then
    echo >&2 "Subrion not found in $(pwd) - copying now..."
	if [ "$(ls -A)" ]; then
		echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
		( set -x; ls -A; sleep 10 )
	fi
	tar cf - --one-file-system -C /usr/src/subrion . | tar xf -

	echo >&2 "Complete! Subrion has been successfully copied to $(pwd)"
fi


TERM=dumb php -- "$SUBRION_DB_HOST" "$SUBRION_DB_USER" "$SUBRION_DB_PASSWORD" "$SUBRION_DB_NAME" <<'EOPHP'
<?php
// database might not exist, so let's try creating it (just to be safe)
$stderr = fopen('php://stderr', 'w');
list($host, $socket) = explode(':', $argv[1], 2);
$port = 0;
if (is_numeric($socket)) {
	$port = (int) $socket;
	$socket = null;
}
$maxTries = 10;
do {
	$mysql = new mysqli($host, $argv[2], $argv[3], '', $port, $socket);
	if ($mysql->connect_error) {
		fwrite($stderr, "\n" . 'MySQL Connection Error: (' . $mysql->connect_errno . ') ' . $mysql->connect_error . "\n");
		--$maxTries;
		if ($maxTries <= 0) {
			exit(1);
		}
		sleep(3);
	}
} while ($mysql->connect_error);
if (!$mysql->query('CREATE DATABASE IF NOT EXISTS `' . $mysql->real_escape_string($argv[4]) . '`')) {
	fwrite($stderr, "\n" . 'MySQL "CREATE DATABASE" Error: ' . $mysql->error . "\n");
	$mysql->close();
	exit(1);
}
$mysql->close();
EOPHP

exec "$@"
