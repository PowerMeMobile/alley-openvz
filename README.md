This set of bash scripts is able to automaticaly setup and make smoke test
of OpenAlley system.
It is based on openvz.

### Configuration ###
You can edit files/config to configure nameserver, instance id, git branches to test and etc.

### Launching ###

``` shell
git clone https://github.com/AntonSizov/alley-openvz.git

# copy dsa key, to be able to fetch funnel and billy
cp rawshan_id_dsa alley-openvz/files
cd alley-openvz

# create alley openvz template with mongo, rabbit and all env
create-alley-env-box
mv centos-6-x86_64.alley-env.tar.gz /vz/template/cache/

#start test
./test-alley
```

You can trace process with the following command:
``` shell
tail -f /vz/private/101/tmp/alley-test.log
```

- On test success, VM will be destroyed and log will be saved in alley-openvz root dir.
- On test error, VM leave run and you can explore it using commands below.

Useful commands:

- vzctl stop 101 #stop VM
- vzctl enter 101 #enter VM with openvz
- vzctl destroy 101 #destroy VM
- vzlist -a # list all existing VM
- ssh -i files/id_dsa 192.168.0.1 # ssh to VM
- cd /vz/private/101 # VM root dir

## OpenVZ

### Installation and basic operations ###
- http://wiki.openvz.org/Quick_installation
- http://wiki.openvz.org/Basic_operations_in_OpenVZ_environment

### Enable forwarding on host srv ###
To enable forwarding on host srv, run following command in linux shell with root:

``` shell
# iptables -F FORWARD
# iptables -t nat -A POSTROUTING -s 192.168.0.0/24 -o eth0 -j SNAT --to-source $HOST_IP
# iptables-save > /etc/sysconfig/iptables
```

Be aware to insert proper interface name (eth0, eth1 and etc)

### Create custom template
- http://ru.ispdoc.com/index.php/Создание_дисковых_шаблонов
