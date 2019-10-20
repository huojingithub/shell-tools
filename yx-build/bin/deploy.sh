#!/bin/sh

proj=$1
host=$2

pom_path=`grep $proj ../conf/pom-path|cut -d' ' -f2`
dist_host=$host
host_pwd=`grep $host ../conf/hosts|cut -d' ' -f2`
dist_dir='/tmp/yx-jar'

echo $pom_path
echo $host_pwd

# cd ${pom_path}
echo `pwd`


echo "pull code ..."
git -C $pom_path stash && git -C $pom_path pull && git -C $pom_path stash pop
if [ $? -ne 0 ]; then
    exit -1
fi

echo "mvn clean install ..."
mvn clean --settings ../conf/settings.xml -f $pom_path
mvn install --settings ../conf/settings.xml -f $pom_path

echo "scp jar file ..."
if ! sshpass -p $host_pwd ssh $dist_host test -d ${dist_dir}/${proj}; then
    # 文件夹不存在，创建
    echo "${dist_dir}/${proj}文件夹不存在，自动创建"
    sshpass -p $host_pwd ssh $dist_host mkdir -p ${dist_dir}/${proj}
fi

if sshpass -p $host_pwd ssh $dist_host test -e ${dist_dir}/${proj}/*.jar; then
    # jar已经存在，重命名备份
    # mv ${dist_dir}/xxxx.jar ${dist_dir}/xxxx.jar.original	
    echo "jar已经存在，删除"
    rm -f ${dist_dir}/${proj}/*.jar
fi
sshpass -p $host_pwd scp ${pom_path}/target/*.jar ${dist_host}:${dist_dir}/${proj}

echo "done"
