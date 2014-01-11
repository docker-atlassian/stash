stash
=====

Atlassian Stash Trusted build repo for Docker.

When the container have started, go to the IPs port 7990 and choose the following options:
Database:
 Type: External
 hostname: localhost
 Port: 5432
 Name: stashdb
 Username: postgres
 Password: 

Database tuning:
 Change "config_pgtune" parameters in node.json. See https://github.com/hw-cookbooks/postgresql#config_pgtune
