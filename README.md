# Alpine Chorus docker-compose environment

Easily run an Alpine Chorus instance by using docker.  

* All logs inside the containers are output to STDOUT and available via `docker-compose logs`
* All filesystem state inside the containers is placed into the data directory which is created via the 
  `setup_volumes.sh` script. 


## Docker installation on OSX
 
1) Download & install: https://www.docker.com/products/docker-toolbox (the Kitematic GUI is the most recent)    
  
  Take note (not publically available yet): https://blog.docker.com/2016/03/docker-for-mac-windows-beta/
  
2) Create a larger than normal docker-machine:

    docker-machine rm -f default
    docker-machine create --driver virtualbox --virtualbox-cpu-count 2 --virtualbox-memory "4096" --virtualbox-disk-size "50000" default

3) We need `docker-machine-nfs` to bugfix filesystem issues related to the data container: https://github.com/adlogix/docker-machine-nfs/pull/25
 
    brew install git docker-machine-nfs 
    docker-machine-nfs default --nfs-config="-alldirs -maproot=0"
    

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
    
    # Wait till you see 
    
    # view the logs of the running instance
    docker-compose logs
        
    # stop the combined instance
    docker-compose stop
            

## Misc            

Run bash inside a running container:

    docker ps # find running container
    docker exec -it <name of container> bash
    
    
## TODO & Notes

* I find, on OSX with docker-machine, it's hard to get enough RAM to run all the Chorus services (indexer, workers, etc),
  so the `docker-compose.yml` currently overrides the `command` with one, to just start solr, and the webserver.  But, if
  this `command` line is removed, the default `CMD` of the Chorus Dockerfile is to run all the services.

* Note the script: alpine-chorus-docker-installer.sh -- this is an attempt to automate all the steps above, it could be the beginnings
  of an installer for this setup.

* You can have any number of docker-compose.yml files, you do so like so: `docker-compose -f alpine_chorus_60.yml up`
  We can use this to allow users to easily switch between different setups. 