# Exercise 1 : TiDB Cluster Installation

## Exercise Overview
In this exercise, we will walk through all installation steps to make sure that your workstation can successfully run TiDB clusters.  This workshop expects you to use 2 TiDB servers on port 4000 and 4001, 3 placement driver servers, 3 TiKV storages, and 1 TiFlash storage.

## Prerequisite
* Your workstation must run a linux-based operating system (MacOS or Linux).
* Your workstation must be installed with Git client or command line interface and be able to clone the workshop’s files.
* Your workstation must be installed with MySQL command line interface and be able to execute SQL commands.

## Instruction
1. Clone the workshop GitHub repository.
2. Review and understand how the installation scripts work.
3. Execute the installation scripts and make sure that all environments are working.
4. Understand how to terminate the running clusters and clean up the environments.


## Steps and Solutions
1. Clone the workshop’s repository from the GitHub website through the Git clone command. Please note that you should navigate to the directory you want to store the workshop materials using the `cd` command first.

```console
$ git clone https://github.com/charnon-cmkl/tidb-workshop-2023/
```

2. Navigate to the `scripts` folder under the directory where you cloned the workshop materials to see installation scripts.

```console
$ cd /tidb-workshop-2023/exercises/scripts/
```

3. Verify and review two scripts that we will use to install TiDB clusters, including the `playground-start.sh` and `playground-check.sh`.
You will see that the `playground-start.sh` script execute the TiUP utility to initiate a playground environment version 6.5.1, including 2 TiDB Servers (db), 3 Placement Driver Server (pd), 3 TiKV storages (kv), and 1 TiFlash storage.
**Note: You may see that the installation requires the TiUP utility, which we need to install it before executing the scripts.**

```console
$ cat playground-start.sh
#!/bin/bash
~/.tiup/bin/tiup playground v6.5.1 \
  --tag classroom \
  --db 2 \
  --pd 3 \
  --kv 3 \
  --tiflash 1
```

```console
$ cat playground-check.sh
#!/bin/bash
~/.tiup/bin/tiup playground display
```

4. Download and install TiUP utility, which we will use to prepare the TiDB cluster environment, by using the following `curl` command. Please note that it may take few minutes to download and install the TiUP utility depending on the network connection.

```console
$ curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
...
Shell profile:  /Users/username/.zshrc
Installed path: /Users/username/.tiup/bin/tiup
===============================================
Have a try:     tiup playground
===============================================
```

5. Once the TiUP utility is successfully installed, we can now run the scripts to initiate the TiDB playground environments by using the following commands.
```console
$ ./playground-start.sh
...
🎉 TiDB Playground Cluster is started, enjoy!

Connect TiDB:   mysql --comments --host 127.0.0.1 --port 4000 -u root
Connect TiDB:   mysql --comments --host 127.0.0.1 --port 4001 -u root
TiDB Dashboard: http://127.0.0.1:2379/dashboard
Grafana:        http://127.0.0.1:3000
```

6. After the playground environment is running, we can use the `playground-check.sh` script to see the status of each component in the cluster. You will see that the components we set in the `playground-start.sh` script are running as expected.

```console
$ ./playground-check.sh
tiup is checking updates for component playground ...
Starting component `playground`: /Users/chnpat/.tiup/components/playground/v1.12.5/tiup-playground display
Pid    Role     Uptime
---    ----     ------
84779  pd       6m29.762465959s
84780  pd       6m29.740466542s
84781  pd       6m29.71878706s
84782  tikv     6m29.694820736s
84783  tikv     6m29.654653997s
84784  tikv     6m29.593441667s
84785  tidb     6m29.531571964s
84786  tidb     6m29.449228042s
84813  tiflash  5m27.333084989s
```

7. Now we can connect to the TiDB server through port 4000 to execute MySQL command to manage database by using the `connect-4000.sh` script. Note that we can also check the detail in the `connect-4000.sh` script by using the `cat` command.

```console
$ ./connect-4000.sh
...
Reading history-file /Users/chnpat/.mysql_history
Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

tidb:4000> 
```

```console
$ cat connect-4000.sh

export MYSQL_PS1="tidb:4000> "

mysql -h 127.0.0.1 -P 4000 -u root --connect-timeout 1 --verbose
```

8. We can try to execute a `SELECT` SQL command to see the information regarding the database version as follows.

```SQL
SELECT TIDB_VERSION()\G
EXIT;
```

```console
--------------
SELECT TIDB_VERSION()
--------------

*************************** 1. row ***************************
TIDB_VERSION(): Release Version: v6.5.1
Edition: Community
Git Commit Hash: 4084b077d615f9dc0a41cf2e30bc6e1a02332df2
Git Branch: heads/refs/tags/v6.5.1
UTC Build Time: 2023-03-07 16:04:47
GoVersion: go1.19.5
Race Enabled: false
TiKV Min Version: 6.2.0-alpha
Check Table Before Drop: false
Store: tikv
1 row in set (0.00 sec)
```

9. (_Optional_) After the use of TiDB server clusters, we can terminate and clean it up to release the resources used. On the terminal screen that running the TiDB server cluster service (as you may see below), press `ctrl-c` to terminate the service.

```console
Connect TiDB:   mysql --comments --host 127.0.0.1 --port 4000 -u root
Connect TiDB:   mysql --comments --host 127.0.0.1 --port 4001 -u root
TiDB Dashboard: http://127.0.0.1:2379/dashboard
Grafana:        http://127.0.0.1:3000

...
tikv quit
Wait pd(84779) to quit...
```

10. (_Optional_) You may also clean up all the playground files that relate to our workshop by using the following command:

```console
$ ~/.tiup/bin/tiup clean classroom
Clean instance of `playground`, directory: /Users/username/.tiup/data/classroom
```
