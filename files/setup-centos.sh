#!/bin/bash

SCRIPT_DIR=$(dirname "$BASH_SOURCE")

. $SCRIPT_DIR/config

if [[ "$(id -u)" != "0" ]]; then
	echo "Need to be root"
	exit 1
fi
echo root OK

# add epel
rpm -Uvh http://mirror.datacenter.by/pub/fedoraproject.org/epel/6/x86_64/epel-release-6-8.noarch.rpm
if [[ "$?" != "0" ]];then
	echo failed to setup epel repository
	exit 1
fi

useradd -m -U -p $ALLEY_USER -G wheel $ALLEY_USER
if [[ "$?" != "0" ]]; then
    echo Failed to create $ALLEY_USER user
    exit 1
fi

# install deps
yum install -y gcc \
gcc-c++ \
wxGTK-devel \
libxslt \
openssl-devel \
ncurses-devel \
fop \
unixODBC-devel \
java-1.6.0-openjdk-devel \
emacs-nox.x86_64 \
git.x86_64 \
screen.x86_64 \
libuuid-devel \
tokyocabinet-devel \
net-snmp.x86_64 \
htop.x86_64 \
sysstat.x86_64 \
iotop.noarch
if [[ "$?" != "0" ]]; then
    echo Failed to install deps
    exit 1
fi

# create opt
mkdir -p $OPT_DIR
if [[ "$?" != "0" ]]; then
    echo Failed to create opt dir
    exit 1
fi

# setup erlang-otp
OTP_DIR=$OPT_DIR/otp-r15b03-1
mkdir $OTP_DIR
if [[ "$?" != "0" ]]; then
    echo Failed to create otp dir
    exit 1
fi

wget http://www.erlang.org/download/otp_src_R15B03-1.tar.gz -P /tmp
if [[ "$?" != "0" ]]; then
    echo Failed to download otp src
    exit 1
fi

tar -C /tmp -xzf /tmp/otp_src_R15B03-1.tar.gz
if [[ "$?" != "0" ]]; then
    echo Failed to unpack otp src
    exit 1
fi

cd /tmp/otp_src_R15B03/
if [[ "$?" != "0" ]]; then
    echo Failed to change dir to /tmp/otp_src_R15B03/
    exit 1
fi

cd /tmp/otp_src_R15B03/ && ./configure --prefix=$OTP_DIR && cd
if [[ "$?" != "0" ]]; then
    echo Failed to configure otp src
    exit 1
fi

make -C /tmp/otp_src_R15B03
if [[ "$?" != "0" ]]; then
    echo Failed to build otp scr
    exit 1
fi

make -C /tmp/otp_src_R15B03 install
if [[ "$?" != "0" ]]; then
    echo Failed to install otp
    exit 1
fi

rm -rf /tmp/otp_src_R15B03
if [[ "$?" != "0" ]]; then
    echo Failed to remove otp src
    exit 1
fi

ln -s $OTP_DIR /opt/otp
if [[ "$?" != "0" ]]; then
    echo Failed to ln otp
    exit 1
fi

echo -e '\nexport PATH=/opt/otp/bin/:$PATH' >> /etc/profile
if [[ "$?" != "0" ]]; then
    echo Failed to add otp path to profile
    exit 1
fi

export PATH=/opt/otp/bin/:$PATH
if [[ "$?" != "0" ]]; then
    echo Failed to add opt to current path
    exit 1
fi


# setup mongodb
wget http://fastdl.mongodb.org/linux/mongodb-linux-x86_64-2.4.5.tgz -P $OPT_DIR
if [[ "$?" != "0" ]]; then
    echo Failed to download mongodb
    exit 1
fi
tar -C $OPT_DIR -xzf /opt/mongodb-linux-x86_64-2.4.5.tgz
if [[ "$?" != "0" ]]; then
    echo Failed to unpack mongodb
    exit 1
fi
rm -f $OPT_DIR/mongodb-linux-x86_64-2.4.5.tgz
if [[ "$?" != "0" ]]; then
    echo Failed to rm mongodb tgz
    exit 1
fi
ln -s $OPT_DIR/mongodb-linux-x86_64-2.4.5 $OPT_DIR/mongodb
if [[ "$?" != "0" ]]; then
    echo Failed to ln mongodb
    exit 1
fi
echo -e '\nexport PATH=/opt/mongodb/bin:$PATH' >> /etc/profile
if [[ "$?" != "0" ]]; then
    echo Failed to add mongodb path to profile
    exit 1
fi

# setup rabbitmq
wget http://www.rabbitmq.com/releases/rabbitmq-server/v3.1.3/rabbitmq-server-generic-unix-3.1.3.tar.gz -P /opt
if [[ "$?" != "0" ]]; then
    echo Failed to download rabbitmq
    exit 1
fi
tar -C /opt/ -xzf /opt/rabbitmq-server-generic-unix-3.1.3.tar.gz
if [[ "$?" != "0" ]]; then
    echo Failed to unpack rabbitmq
    exit 1
fi
rm -f /opt/rabbitmq-server-generic-unix-3.1.3.tar.gz
if [[ "$?" != "0" ]]; then
    echo Failed to rm rabbitmq tar
    exit 1
fi
ln -s /opt/rabbitmq_server-3.1.3 /opt/rabbitmq
if [[ "$?" != "0" ]]; then
    echo Failed to ln rabbitmq
    exit 1
fi
echo -e '\nexport PATH=/opt/rabbitmq/sbin:$PATH' >> /etc/profile
if [[ "$?" != "0" ]]; then
    echo Failed to add rabbitmq path to profile
    exit 1
fi
cp /tmp/rabbitmq-env.conf /opt/rabbitmq/etc/rabbitmq/
if [[ "$?" != "0" ]]; then
    echo Failed to copy rabbitmq config
    exit 1
fi


# setup user_default
mkdir /tmp/user_default && git clone https://github.com/ten0s/user_default.git /tmp/user_default
if [[ "$?" != "0" ]]; then
    echo Failed to fetch user_default
    exit 1
fi
mkdir /opt/ebin
if [[ "$?" != "0" ]]; then
    echo Failed to mkdir /opt/ebin
    exit 1
fi
erlc -o /opt/ebin /tmp/user_default/user_default.erl
if [[ "$?" != "0" ]]; then
    echo Failed to compile user_default
    exit 1
fi
mkdir /opt/bin
if [[ "$?" != "0" ]]; then
    echo Failed to mkdir /opt/bin
    exit 1
fi
echo -e '#!/bin/bash\n' >> /opt/bin/add_user_default
if [[ "$?" != "0" ]]; then
    echo Failed to create add_user_default
    exit 1
fi
echo 'echo -e "{module, user_default} = code:load_abs(\"/opt/ebin/user_default\")." >> $HOME/.erlang' >> /opt/bin/add_user_default
if [[ "$?" != "0" ]]; then
    echo Failed to create add_user_default
    exit 1
fi
chmod +x /opt/bin/add_user_default
if [[ "$?" != "0" ]]; then
    echo Failed to chmod add_user_default
    exit 1
fi
echo -e '\nexport PATH=/opt/bin:$PATH' >> /etc/profile
if [[ "$?" != "0" ]]; then
    echo Failed to add /opt/bin path to profile
    exit 1
fi
echo -e "{module, user_default} = code:load_abs(\"/opt/ebin/user_default\")." >> /home/$ALLEY_USER/.erlang
if [[ "$?" != "0" ]]; then
    echo Failed to add user_default for $ALLEY_USER user
    exit 1
fi
chown $ALLEY_USER:$ALLEY_USER /home/$ALLEY_USER/.erlang
if [[ "$?" != "0" ]]; then
    echo Failed to chown to $ALLEY_USER user for .erlang file
    exit 1
fi
/opt/bin/add_user_default
if [[ "$?" != "0" ]]; then
    echo Failed to run add_user_default for root user
    exit 1
fi


#mount storages
mkdir -p $VAR_DIR $DB1_DIR $DB2_DIR
if [[ "$?" != "0" ]]; then
    echo Failed to mount var db1 db2
    exit 1
fi


#create necessary folders
mkdir -p $KELLY_VAR_DIR $JUST_VAR_DIR $FUNNEL_VAR_DIR $RABBIT_VAR_DIR
if [[ "$?" != "0" ]]; then
    echo Failed to mkdir -p $KELLY_VAR_DIR $JUST_VAR_DIR $FUNNEL_VAR_DIR $RABBIT_VAR_DIR
    exit 1
fi

cd /mnt/var
if [[ "$?" != "0" ]]; then
    echo Failed to chdir to /mnt/var
    exit 1
fi
# mkdir -p kelly/data kelly/log/sasl
# if [[ "$?" != "0" ]]; then
#     echo Failed to mkdir kelly
#     exit 1
# fi
# mkdir -p funnel/data/mnesia funnel/data/snmp funnel/data/tokyo funnel/log/sasl funnel/log/smpp
# if [[ "$?" != "0" ]]; then
#     echo Failed to mkdir funnel
#     exit 1
# fi
# mkdir -p just/data/mnesia just/data/snmp just/log/sasl just/log/smpp
# if [[ "$?" != "0" ]]; then
#     echo Failed to mkdir just
#     exit 1
# fi
mkdir -p mongodb/arbiter/data mongodb/arbiter/log mongodb/db1/log mongodb/db2/log
if [[ "$?" != "0" ]]; then
    echo Failed to mkdir mongodb
    exit 1
fi
# mkdir -p rabbitmq/var
# if [[ "$?" != "0" ]]; then
#     echo Failed to mkdir rabbitmq
#     exit 1
# fi
cd

mkdir -p /mnt/db1/data /mnt/db2/data
if [[ "$?" != "0" ]]; then
    echo Failed to mkdir dbx/data
    exit 1
fi

# setup smppload
mkdir /tmp/smppload && git clone https://github.com/PowerMeMobile/smppload.git /tmp/smppload
if [[ "$?" != "0" ]]; then
    echo Failed to fetch smppload
    exit 1
fi
make -C /tmp/smppload escriptize
if [[ "$?" != "0" ]]; then
    echo Failed to build smppload
    exit 1
fi
cp /tmp/smppload/smppload /opt/bin
if [[ "$?" != "0" ]]; then
    echo Failed to copy smppload to /opt/bin
    exit 1
fi

# setup SmppSim
tar -C /opt -xzf /tmp/SMPPSim.tar.gz
if [[ "$?" != "0" ]]; then
    echo Failed to unpack smppsim
    exit 1
fi
ln -s /opt/SMPPSim/startsmppsim.sh /opt/bin/startsmppsim
if [[ "$?" != "0" ]]; then
    echo Failed to ln smppsim
    exit 1
fi

# make SmppSim, mongodb, rabbitmq able to autostart
cp /tmp/start-alley-env /opt/bin
if [[ "$?" != "0" ]]; then
    echo Failed to copy start-alley-env to /opt/bin
    exit 1
fi
chmod +x /opt/bin/start-alley-env
if [[ "$?" != "0" ]]; then
    echo Failed to chmod start-alley-env
    exit 1
fi
echo -e "\nsu $ALLEY_USER -c "\''bash -c "source /etc/profile; /opt/bin/start-alley-env &> /home/'$ALLEY_USER'/start-alley-env.log"'\' >> /etc/rc.local
if [[ "$?" != "0" ]]; then
    echo Failed to add start rules to rc.local
    exit 1
fi

# setup filesystem permissions
chown $ALLEY_USER:$ALLEY_USER -R $VAR_DIR/*
if [[ "$?" != "0" ]]; then
    echo Failed to chown for var
    exit 1
fi
chown $ALLEY_USER:$ALLEY_USER -R $DB1_DIR/*
if [[ "$?" != "0" ]]; then
    echo Failed to chown for db1
    exit 1
fi
chown $ALLEY_USER:$ALLEY_USER -R $DB2_DIR/*
if [[ "$?" != "0" ]]; then
    echo Failed to chown for db2
    exit 1
fi

# setup limits
echo -e '\n*	hard		nofile	64000' >> /etc/security/limits.conf
if [[ "$?" != "0" ]]; then
    echo Failed to add nofile limits
    exit 1
fi
echo -e '\n*	hard		nproc	32000' >> /etc/security/limits.conf
if [[ "$?" != "0" ]]; then
    echo Failed to nproc limits
    exit 1
fi

rm -rf $TMP_DIR/*
if [[ "$?" != "0" ]]; then
    echo Failed to clear tmp dir
    exit 1
fi

exit 0
