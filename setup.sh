## execute this script with bash (i.e., /bin/bash setup.sh)

## install jdk and maven
echo "Basladi" >> /local/mertlogs

sudo apt update
sudo apt-get --yes install openjdk-8-jdk
sudo apt --yes install maven

## install docker and docker-compose
sudo apt --yes install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
apt-cache policy docker-ce
sudo apt --yes install docker-ce
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo docker-compose --version

echo "Docker done" >> /local/mertlogs

### create extrafs
## stop docker to update work dir
sudo systemctl stop docker.service
sudo systemctl stop docker.socket

## bash users
for user in $(ls /users)
do
	sudo chsh $user --shell /bin/bash
done

echo "Checkpoint" >> /local/mertlogs

## create extrafs
sudo mkdir /mydata
sudo /usr/local/etc/emulab/mkextrafs.pl /mydata
sudo chmod ugo+rwx /mydata
SEARCH_STRING="ExecStart=/usr/bin/dockerd -H fd://"
REPLACE_STRING="ExecStart=/usr/bin/dockerd -g /mydata -H fd://"
sudo sed -i "s#$SEARCH_STRING#$REPLACE_STRING#" /lib/systemd/system/docker.service
sudo rsync -aqxP /var/lib/docker/ /mydata
sudo systemctl daemon-reload
sudo systemctl start docker
ps aux | grep -i docker | grep -v grep >> /local/mertlogs
echo "Check above for directory on where docker works" >> /local/mertlogs


cd /local
git clone https://github.com/mtoslalibu/astraea-scripts.git

## fork repo of java client
cd /local
git clone https://github.com/mtoslalibu/jaeger-client-java.git    
##git checkout tags/v0.30.6
##git checkout -b v0.30.6-astraea
## ext.developmentVersion = getProperty('developmentVersion','0.30.6')
## add -SNAPSHOT
cd jaeger-client-java
git checkout --track origin/v0.30.6-astraea
git submodule init
git submodule update
sudo ./gradlew clean install
cd ..

echo "Checkpoint jaeger-client-java" >> /local/mertlogs

## servlet mert’s version
git clone https://github.com/mtoslalibu/java-web-servlet-filter.git
cd java-web-servlet-filter
git checkout --track origin/v0.1.1-astraea
sudo ./mvnw clean install -Dlicense.skip=true -Dcheckstyle.skip -DskipTests=true
cd ..

echo "Checkpoint java-web-servlet-filter" >> /local/mertlogs

## java spring web mert’s version
git clone https://github.com/mtoslalibu/java-spring-web.git
cd java-spring-web
git checkout --track origin/v-0.3.4-astraea
sudo ./mvnw clean install -Dlicense.skip=true -Dcheckstyle.skip -DskipTests=true
cd ..

echo "Checkpoint java-spring-web.git" >> /local/mertlogs


## git clone fork repo of java spring jaeger
git clone https://github.com/mtoslalibu/java-spring-jaeger.git
cd java-spring-jaeger
##git checkout tags/release-0.2.2 ## (change client java version to SNAPSHOT)
git checkout --track origin/v0.2.2-astraea
sudo ./mvnw clean install -Dlicense.skip=true -Dcheckstyle.skip -DskipTests=true
cd ..

echo "Checkpoint java spring jaeger" >> /local/mertlogs

## go trainticket + switch to jaeger branch + then change java-jaeger-spring version to snapshot
##git checkout jaeger
git clone https://github.com/mtoslalibu/train-ticket.git
cd train-ticket
git checkout --track origin/astraea
## change version under ts-common to snapshot
sudo mvn clean package -Dmaven.test.skip=true
#sudo docker-compose build
#sudo docker-compose up
## create span states file to populate in memory astraea data structure
cd ..
mkdir -p /local/astraea-spans
sudo chmod ugo+rwx /local/astraea-spans
cp /local/astraea-scripts/astraea-span-allenabled /local/astraea-spans/states


#echo "Everything is installed and built now. go ahead and create external fs (mydata)"
echo "After that please go back to train ticket - and docker-compose build then docker-compose up" >> /local/mertlogs

## send email
mail -s "TrainTicket instance finished setting up!" $(geni-get slice_email)
