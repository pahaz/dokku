WFLOW_VERSION = master

PLUGINHOOK_URL ?= https://s3.amazonaws.com/progrium-pluginhook/pluginhook_0.1.0_amd64.deb
STACK_URL ?= https://github.com/progrium/buildstep.git
PREBUILT_STACK_URL ?= https://github.com/progrium/buildstep/releases/download/2014-03-08/2014-03-08_429d4a9deb.tar.gz

WFLOW_NAME ?= wflow
WFLOW_USER ?= wflow
WFLOW_ROOT ?= /home/${WFLOW_USER}
WFLOW_PLUGINS ?= /var/lib/${WFLOW_NAME}/plugins
WFLOW_SHELL ?= /usr/local/bin/${WFLOW_NAME}

export PLUGIN_PATH := ${WFLOW_PLUGINS}

.PHONY: all install dependencies ssh_user pluginhook docker stack copyfiles install_plugins version count

all:
	# Type "make install" to install.

install: dependencies copyfiles install_plugins version

dependencies: ssh_user pluginhook docker stack

ssh_user:
	egrep -i "^${WFLOW_USER}" /etc/passwd || useradd --home-dir ${WFLOW_ROOT} --shell ${WFLOW_SHELL} ${WFLOW_USER}

pluginhook:
	wget -qO /tmp/pluginhook_0.1.0_amd64.deb ${PLUGINHOOK_URL}
	dpkg -i /tmp/pluginhook_0.1.0_amd64.deb

docker:
	# http://docs.docker.com/installation/ubuntulinux/
	curl -sSL https://get.docker.io/ubuntu/ | sudo sh
	# Warning: The docker group (or the group specified with the -G flag) is root-equivalent; see Docker Daemon Attack Surface details.
	egrep -i "^docker" /etc/group || groupadd docker
	usermod -aG docker ${WFLOW_USER}
	sleep 2 # give docker a moment i guess

stack:
ifdef BUILD_STACK
	@docker images | grep progrium/buildstep || (git clone ${STACK_URL} /tmp/buildstep && docker build -t progrium/buildstep /tmp/buildstep && rm -rf /tmp/buildstep)
else
	@docker images | grep progrium/buildstep || curl -L ${PREBUILT_STACK_URL} | gunzip -cd | docker import - progrium/buildstep
endif

copyfiles:
	cp ${WFLOW_NAME} ${WFLOW_SHELL}
	chmod +x ${WFLOW_SHELL}
	mkdir -p ${WFLOW_PLUGINS}
	cp -r plugins/* ${WFLOW_PLUGINS}
	chmod +x ${WFLOW_PLUGINS}

install_plugins: pluginhook docker
	@pluginhook install

version:
	git describe --tags > ${WFLOW_ROOT}/VERSION  2> /dev/null || echo '~${WFLOW_VERSION} ($(shell date -uIminutes))' > ${WFLOW_ROOT}/VERSION

count:
	@echo "Core lines:"
	@cat ${WFLOW_NAME} bootstrap.sh | wc -l
	@echo "Plugin lines:"
	@find plugins -type f | xargs cat | wc -l
	@echo "Test lines:"
	@find tests -type f | xargs cat | wc -l
