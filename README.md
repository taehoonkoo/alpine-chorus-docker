# Alpine Chorus docker-compose environment

Easily run Alpine Chorus using docker.  

* All logs inside the containers are output to STDOUT and available via `docker-compose logs`
* All filesystem state inside the containers is placed into the data directory which is created via the 
  `setup_volumes.sh` script. 


## Docker installation on OSX
 
1) Download & install: https://www.docker.com/products/docker-toolbox (the Kitematic GUI is the most recent)    
  
  Take note (not publically available yet): https://blog.docker.com/2016/03/docker-for-mac-windows-beta/
  
2) Create a larger than normal docker-machine (with 8gb of ram):

    docker-machine rm -f default
    docker-machine create --driver virtualbox --virtualbox-cpu-count 2 --virtualbox-memory "8192" --virtualbox-disk-size "50000" default

3) We need `docker-machine-nfs` to bugfix filesystem issues related to the data container: https://github.com/adlogix/docker-machine-nfs/pull/25
 
    brew install git docker-machine-nfs 
    docker-machine-nfs default --nfs-config="-alldirs -maproot=0"

$) **Run this each time you open bash to hook up the shell to the docker-machine instance:**

    eval "$(docker-machine env)"    
    

## Running:

    # login with http://hub.docker.com account to access private alpine image
    docker login
    
    docker-compose pull

    # create a copy of the persistent filesystems associated with the alpine and chorus docker images, on our local host
    ./setup_volumes.sh  
    
    # initialize the chorus postgres database    
    docker-compose run chorus rake db:create db:migrate db:seed
    
    # run the combined instance, daemonized
    docker-compose up -d
    
    # view the logs of the running instance
    docker-compose logs

    # ... watch Alpine & Chorus boot up -- wait till you see (from Chorus):
    `Mizuno 0.6.11 (Jetty 8.1.15.v20140411) listening on 0.0.0.0:3000`
        
    # ... then (in a new bash instance), run:
    open http://`docker-machine ip`:8080

    # stop the combined instance
    docker-compose stop
            

## Misc            

Run bash inside a running container:

    docker ps # find running container
    docker exec -it <name of container> bash
    
    
## TODO, Notes, & Gotchas

* If you move your comptuter from one network to another (like, go home from work, etc
), the docker-machine will have trouble connecting to the internet.  Fix this with a:

    docker-machine restart

* Once you have run the ./setup_volumes.sh script, do not move the 
alpine-chorus-docker folder to another location on your hard drive.  If you do this,
the volume mounting will break.  To fix this, delete and recreate your docker-machine.

* I find, on OSX with docker-machine, it's hard to get enough RAM to run all the Chorus services (indexer, workers, etc),
  so the `docker-compose.yml` currently overrides the `command` with one, to just start solr, and the webserver.  But, if
  this `command` line is removed, the default `CMD` of the Chorus Dockerfile is to run all the services.

* Note the script: alpine-chorus-docker-installer.sh -- this is an attempt to automate all the steps above, it could be the beginnings
  of an installer for this setup.  I think it's buggy right now, haven't had a chance to continue it.  Not necessary for the current stage.

* You can have any number of docker-compose.yml files, you do so like so: `docker-compose -f alpine_chorus_60.yml up`
  We can use this to allow users to easily switch between different setups. 


## Version information

```
$ docker version
Client:
 Version:      1.10.2
 API version:  1.22
 Go version:   go1.5.3
 Git commit:   c3959b1
 Built:        Mon Feb 22 22:37:33 2016
 OS/Arch:      darwin/amd64

Server:
 Version:      1.10.3
 API version:  1.22
 Go version:   go1.5.3
 Git commit:   20f81dd
 Built:        Thu Mar 10 21:49:11 2016
 OS/Arch:      linux/amd64

$ docker-compose version
docker-compose version 1.6.0, build d99cad6
docker-py version: 1.7.0
CPython version: 2.7.9
OpenSSL version: OpenSSL 1.0.1j 15 Oct 2014  
```