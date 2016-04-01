#!/usr/bin/env bash
# set -x
set -e
set -o pipefail

# clear 
printf "============================================\n"
printf "Easy Alpine Chorus v0.1 BETA for OSX\n"
printf "Runs Alpine Chorus in an easy way via Docker images.\n\n"

test_already_installed() {
	if [ -d ~/alpine-chorus-docker ] ; then
	  	already_installed=true
	else
		already_installed=false
	fi
}

test_already_installed
if [ $already_installed = false ] ; then
	printf "First time run on this system!  Setting up ...\n"

	test_docker_toolbox_installed() {
	    if hash docker-machine 2>/dev/null; then
	        docker_installed=true
	    else
	        docker_installed=false
	    fi
	}

	test_docker_toolbox_installed
	if [ $docker_installed = false ] ; then
		printf "\nDocker Toolbox is not detected on your system.\n"
		printf "Should we help you to install it? (y/N): "
		read install_docker

		if [ $install_docker = "y" ] ; then
			printf "Downloading Docker Toolbox ...\n"
			mkdir -p ~/install_docker
			# curl -L https://github.com/docker/toolbox/releases/download/v1.10.3/DockerToolbox-1.10.3.pkg > ~/install_docker/DockerToolbox-1.10.3.pkg
			printf "\nDownloaded succesfully.  Now, we have to run the installer.\n\n"
			printf "WHEN YOU HIT RETURN, THE FOLDER CONTAINING THE INSTALLER WILL OPEN!\n"
			printf "Double-click it and follow the prompts."
			printf "\n\nHIT RETURN TO INSTALL DOCKER TOOLBOX"
			read start_installation
			open ~/install_docker
			printf "\nOnce you have installed Docker Toolbox, HIT RETURN TO CONTINUE ..."
			read continue_with_installation

			printf "\nCreating docker-machine ..."
			docker-machine rm -f default
			docker-machine create --driver virtualbox --virtualbox-cpu-count 2 --virtualbox-memory "4096" --virtualbox-disk-size "50000" default
		else
			printf "Attempting to continue without docker toolbox ...\n"
		fi
	fi

	test_brew_installed() {
	    if hash brew 2>/dev/null; then
	        brew_installed=true
	    else
	        brew_installed=false
	    fi
	}

	test_brew_installed
	if [ $brew_installed = false ] ; then
		printf "Homebrew (OSX package manager) is not detected on your system.\n"
		printf "Should we try to automatically install it? (y/N): "
		read install_homebrew

		if [ $install_homebrew = "y" ] ; then
			printf "Installing homebrew ...\n"
			/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
		else
			printf "Attempting to continue without homebrew ...\n"
		fi
	fi

	printf "Installing docker-machine-nfs via homebrew ...\n"
	brew install git docker-machine-nfs
	# https://github.com/adlogix/docker-machine-nfs/pull/25
	docker-machine-nfs default --nfs-config="-alldirs -maproot=0"

	printf "Downloading docker-compose configuration information ...\n"
	git clone https://github.com/kevinmtrowbridge/alpine-chorus-docker.git ~/alpine-chorus-docker
fi

eval "$(docker-machine env)"

if [ ! -e ~/.docker/config.json ]; then
	printf "In order to download Alpine, you need a hub.docker.com account.  Please ask Kevin to create "
    printf "one for you.  Login now with your credentials.  This is only necessary once per machine "
    printf "as the credentials are cached.\n"
	docker login
fi

printf "Starting Alpine Chorus instance, please be patient ...\n"

cd ~/alpine-chorus-docker

if [ ! -e ./data ]; then
	printf "Setting up data directory ..."
	./setup_volumes.sh
fi

sigquit()
{
	echo "signal QUIT received"
}

sigint()
{
	echo "Stopping ..."
	docker-compose stop
	exit 0
}

trap 'sigquit' QUIT
trap 'sigint'  INT
trap ':'       HUP      # ignore the specified signals

docker-compose up -d --force-recreate

printf "\n\n CONTROL-C TO STOP \n\n"

docker-compose logs | while read LOGLINE
do
	echo "${LOGLINE}"
	[[ "${LOGLINE}" == *"WEBrick::HTTPServer#start"* ]] \
		&& open http://`docker-machine ip`:8080
		# && pkill -P $$ docker-compose
done
