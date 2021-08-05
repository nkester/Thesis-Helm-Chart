# Thesis-Charts

How to guide to Helm Charts.

https://helm.sh/docs/topics/charts/  

# Deploying the Chart  

The following commands are required to deploy the chart. This assumes that you have a yaml manifest that describes the persistent volumm (pv) and persistent volume claim (pvc) resources.  

Create the pv resources. These are not namespaced.
`$ kubectl apply --namespace analytics -f ./persistentStorage/Rancher/pv-ebs.yaml `  

Create the pvc resources. These ARE namespaced. Also, we have specified the pv each pvc should bind to in the yaml using the `volumnName` attribute.  
`$ kubectl apply --namespace analytics -f ./persistentStorage/Rancher/pvc-ebs.yaml`  

Once these are created, apply the helm chart. The `values.yaml` file in this directory should specify the pvc each resource should mount to. This deployment uses static, rather than dynamic, provisioning.  
`$ helm install analytic-environment ./analyticEnvironment --namespace analytics`

## Create a simple apache http server  

This is based on the bitnami apache helm chart. 

Static html resources are served from `/opt/bitnami/apache2/htdocs/`

Run the helm chart with the following command:  

`helm install <name> bitnami/apache --namespace <namespace>`

for instance:

`helm install analytic-httpserver bitnami/apache --namespace analytics  `

## Copy local files to a pod  

This is useful when moving files into another pod. A use case for this is setting up an apache http server and moving static html files there to host.
`kubectl cp /tmp/foo <some-namespace>/<some-pod>:/tmp/bar`

# Parameters in the values.yaml  

`statefulset.enabled`: Currently set to false. **To be built out**  

`deploymentStrategy`: Uncomment and change as needed **Not currently implemented**  

`rstudio`: Specify information about the rstudio pod's deployment. Includes:  
  `podName`: Change as needed  
  `imageRepository`: Defaults to the rocker docker hub image. **Need to test with custom image**
  `imageTag`: Specific image tag to use (don't include in the `imageRepository` value.
  `imagePullPolicy`: Change as needed **Not tested**
  `env`: These are the two required for the rocker/rstudio image. **Need to change impentation of tese values in the deployment template to allow various number of environmental variable key-value pairs.**  
    `firstEnvName`: Required by the rocker image. Don't change. **Username is rstudio**  
	`firstEnvValue`: Change as needed.
	`secondEnvName`: Don't change.  
	`secondEnvValue`: Options "TRUE" or "FALSE"  
  `resources`: Provide resources as required. **Need to test and build out options**  
  `service`: These should not change but need to include in the output what the actual address and port are.  
`imagePullSecrets`: Not used right now **To be built out**  
`nameOverride`: Change as needed.  
`fullnameOverride`: Change as needed.
`serviceAccount`: **Need to test if this is needed and what it provides**  
  `create`: true/false  
  `annotations`: **To be built out**  
  `name`: **To be built out**  
`podAnnotations`: **To be built out, waht is this for?**  
`podSecurityContext`: **To be built out**  
`securityContext`: **To be built out**  
`ingress`: Not sure what this does for us. **To be built out**  
  `enabled`: true/false  
  `annotations`: Not sure  
  `hosts`: Not sure 
  `tls`: Not sure  
`autoscaling`: Rules to determine autoscaling. Not sure about loadbalancing and applicability for this. **To be built out**  
  `enabled`: true/false  
  `minReplicas`: 1  
  `maxReplicas`: 100  
  `targetCPUUtilizationPercentage`: 80  
`nodeSelector`: **To be built out**  
`tolerations`: **To be built out**  
`affinity`: **To be built out**


# Deploy the helm chart 

Navigate to the root folder of this project. Execute the following command to install the chart:  

``

helm install rstudio ./firstChart/ --namespace default

``

# Postgres sub-chart  

## Deploy Postgres From Its Own Helm Repo  

Add the repo and install the chart  

```{bash}
# Add the repo 
helm repo add bitnami https://charts.bitnami.com/bitnami

# Install the chart
helm install my-postgresql bitnami/postgresql --version 10.2.1

# Return the auto-generated password
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default my-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
echo $POSTGRES_PASSWORD
```  

The notes (in stdout) will provide the host which will look something like: `my-postgresql.default.svc.cluster.local`. You can also use the clusterIP.  

The connection object elements are:  
```{bash}
host = '<from previous step>',
port = 5432,
user = 'postgres',
password = '<from previous step>' 
```

** The Ubuntu dependency required to connect to a PostgreSQL database is libpq-dev**  

## Postgres as a dependency  

Decide to include the postgres image by entering `true` for `.Values.postgresql.enabled`
Likewise, provide the databases' password in `.Values.postgresql.postgresqlPassword`

**Need to pass up the ability to determine if the database is persistent or not. 


# Persistent Storage

**This is temporary. The long term solution is to create stateful sets**

Create the persistent volume and persistent volume claim before deploying the rstudio helm chart. Do this by executing the two commands from within the `./persistentStorage` directory. Before doing this ensure you have created the proper pv and pvc resources in their corresponding manifestes.  

Note, if you want to use a specific namespace, create it first with `kubectl create ns <namespace>`  

This approach uses statically provisioned amazon web services (aws) elastic block storage (ebs) volumes mapped to persistent volume resources which are in turn mapped to persistent volume claim resources in kubernetes.  

The persistent volume yaml for one pv is below:  

```
apiVersion: v1
kind: PersistentVolume
metadata:
  name: analytics-ebs-rstudio-pv
spec:
  accessModes:
    - ReadWriteOnce
  awsElasticBlockStore: 
    fsType: ext4
    volumeID: vol-05b456b0b36e54b8e
  capacity: 
    storage: 10Gi
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""

```  

A persistent volume claim yaml for one pvc is below:  

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: analytics-ebs-rstudio-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: ""
  volumeName: "analytics-ebs-rstudio-pv"

```

At this point update the `values.yaml` with the volume and claim names under the `.Vales.rstudio.persistentStorage` and `.Values.postgresql.persistence.existingClaim` location.  

Now you can install the helm chart as normal. Ensure you install it into the same namespace as you previously applied the pv.yaml and pvc.yaml files.  

## old notes  
This approach uses `local` volumes because the current NVESD Cluster is not correctly provisioned to use `awsElasticBlockStore` volumes.  

See the reference [here](https://kubernetes.io/docs/concepts/storage/volumes/#local) for information about the approach from the kubernetes.io reference. In short, this is a more durable and portable solution than `hostPath`.  

Create a `Storage Class` for the `local` volume type based on the [kubernetes.io documentation](https://kubernetes.io/docs/concepts/storage/storage-classes/#local)  

**IMPORTANT:** When using the `local` volume type, the folder paths must exist. If they do not, the initContainer will not have anything to reference. To fix this, I have created another pv and pvc for the appropriate local drive directory (in this case /dev/sda1/) and mounted it to a basic ubuntu container. With this pod running, I ran `kubectl exec -it <pod name> -- bash` from my WSL2 to enter the pod and create the required directories. The initContainers for each service will change the file permissions as required.


# MongoDB  

## Install as its own chart 

[bitnami website](https://bitnami.com/stack/mongodb/helm) 

```{bash}
# on WSL
helm add repo bitnami https://charts.bitnami.com/bitnami

kubectl create ns mongo-test 

helm install test-mongo bitnami/mongodb --namespace mongo-test

```  

The stdout response will provide all of the required information to connect to the instance.

Access it from RStudio by installing the rstudio helm chart. Before installing mongolite with `install.package('mongolite')` you need to install the following Ubuntu libraries: libssl-dev, libsasl2-dev, and libz-dev. Remember to run `sudo apt update` before doing this to update the repository.  

In your WSL2 retrive the root password as instructed in the stdout by running the command that starts with `export MONGODB_ROOT_PASSWORD=..`  

Return the password with `echo $MONGODB_ROOT_PASSWORD`  

In RStudio connect to the mongoDB with the following command: 
`con <- mongolite::mongo(url = 'mongodb://<username>:<Root Password>@<DNS name>')`  

In my example the command was:
`con <- mongolite::mongo(url = 'mongodb://root:LfbsEuli94@test-mongo-mongodb.mongo-test.svc.cluster.local/')`

This produces an object with various methods associated with it. List all data in the connected database with:  
`con$find('{}')`  

MongoDB uses objects in a different way than how most R users are used to. This [Mongolite User Manual](https://jeroen.github.io/mongolite/index.html) may be helpful.  

Another great resource is the [MongoDB Manual](https://docs.mongodb.com/manual/introduction/)

# Jupyter Hub  

**DID NOT USE BECAUSE THE LOADBALANCING SERVICE HAD ISSUES. USE RSTUDIO TO RUN PYTHON CODE INSTEAD**

Use references here:

[Jupyter Hub Helm Charts|https://jupyterhub.github.io/helm-chart/] 

[How to deploy helm chart|https://zero-to-jupyterhub.readthedocs.io/en/latest/jupyterhub/installation.html]

Install Jupyter Hub with `helm install jhub jupyterhub/jupyterhub --values ./config.yaml` where the config.yaml file is configured according to the second reference. 

Once the chart deploys find the public-proxy service's port with: `kubectl get --namespace neil-ns -o jsonpath="{.spec.ports[0].nodePort}" services proxy-public`  
Get the cluster's external IP with: `kubectl get nodes --namespace neil-ns -o jsonpath="{.items[0].status.addresses[0].address}"`

Use these to log into the server.

