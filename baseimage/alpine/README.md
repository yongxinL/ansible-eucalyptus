Docker container based on Alpine

This is a docker container including a working init process, crond and syslog, and managed by supervisord

The unix process ID 1 is the process to receive the SIGTERM signal when you execute a 

<code>docker stop <container ID></code>

if the container has the command <code>CMD ["bash"]</code> then bash process will get the SIGTERM signal and terminate. All other processes running on the system will just stop without the possibility to shutdown correctly.

### init.py script

In the containter there is a script that handles the init process an uses the supervisor system to start the daemons to run and also catch signals (SIGTERM) to shutdown all processes started by supervisord. This is a modified version of an init script made by Phusion. there are also two directories to run scripts before any daemon is started.

**Run script once /etc/runcone**

All exectable in this directory is run at start, after completion the script is removed from the directory.

**Run script every start /etc/runalways**

All executable in this directory is run at every start of the container, ie, at docker run and docker start

**Permanent output to docker log when starting container**

Each time the container is started the content of the file /tmp/startup.log is displayed so if you started scripts generated vital information to be shown please add that information to that file. this information can be retrieved anytime by executing <code>docker logs <container ID></code>

**New commands autostarted by supervisord**

To add other processes to run automaticly, add a file ending with .conf in /etc/supervisor.d/

### Output information to docker logs

The console output is owned by the init process so any output from commands won't show in the docker log. To send a text from any command, either at startup during run, append the output to the file /var/log/startup.log, e.g. output from script to log

    /usr/local/bin/script >> /var/log/startlog.log

and check the log by command

    docker logs <container ID>
