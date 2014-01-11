#!/bin/bash

# Start the postgres server
/postgres.sh &

# Start Atlassian in the forground
su - "$STASHUSR" -c "export STASH_HOME=$STASH_HOME ; /opt/atlassian/atlassian-stash-$AppVer/bin/start-stash.sh -fg"
