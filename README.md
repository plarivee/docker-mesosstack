# Docker MesosStack

Based on mesos-mini, this adds 
- consul
- marathon-consul
- fabio ( to deploy )
 and other debuggin java tools


example of json in deployment_json


hard coded ports to make apps/docker available in the DiD

# Build image
```
docker build -t mesosstack ./Dockerfile
```
# To start
```
docker run -d  --rm --privileged -p 8500:8500 -p 5050:5050 -p 5051:5051 -p 8080:8080 -p 30000-30200:30000-30200 --name mesos mesosstack
``` 


# Services

## Mesos
http://localhost:5050

## Marathon
http://localhost:8080

## Consul
http://localhost:8500

## Deployed Apps
ports 30000 to 30200

```
MESOS_RESOURCES="ports(*):[30000-30200]"
``
