# Multus default route manipulation from within the POD 
![Travis CI](https://travis-ci.org/redhat-nfvpe/telco-cni-networking.svg?branch=master)

This script was created to bypass the [Multus limitation](https://github.com/intel/multus-cni/issues/349) where default routes cannot be defined during Network CRD creation
Ideally this script can me mounted using a configMap with an Init Container. For testing purpose , you can run this script once the POD is created and depending on your privlege level




## Prerequisites
- Kubernetes installed and have configured a default network -- that is, a CNI plugin that's used for your pod-to-pod connectivity.
- Multus installed and configured. Refer to [multus](https://github.com/intel/multus-cni).
- Network Interfaces attached that will be used for Network CRD creation.
- If you plan to use ipvlan, make sure kernel is upgraded to [4.4](https://github.com/intel/multus-cni/issues/347)


## Example: 


### Clone repository 
```
git clone https://github.com/lam42/telco-cni-networking.git
cd telco-cni-networking.git/
```


### Storing a configuration as a Custom Resource

```
cat <<EOF | kubectl create -f -
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: multus-test
spec:
  config: '{
      "cniVersion": "0.3.0",
      "type": "ipvlan",
      "master": "eth1",
      "ipam": {
        "type": "host-local",
        "ranges": [
          [
            {
              "subnet": "10.46.90.224/27",
              "rangeStart": "10.46.90.248",
              "rangeEnd": "10.46.90.250",
              "gateway": "10.46.90.225"
            }
          ]
        ],
        "routes": [
          { "dst": "10.46.90.224/27", "gw": "10.46.90.225" }
        ]
      }
    }'
EOF
```



### Create a configMap using the [multus-default-route.sh](https://github.com/lam42/telco-cni-networking/blob/master/multus-default-route.sh) script

```
kubectl create configmap wrapper --from-file=multus-default-route.sh
```

### Create POD with an InitContainer which will mount you configMap and run your bash script 

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod-9
  annotations:
    k8s.v1.cni.cncf.io/networks:  multus-test
spec:
  initContainers:
  - name: samplepod
    command: ["/var/empty/multus-default-route.sh"]
    volumeMounts:
    - name: wrapper
      mountPath: /var/empty
    image: centos
    securityContext:
      privileged: true
  volumes:
  - name: wrapper
    configMap:
      name: wrapper
      defaultMode: 0744

  containers:
  - name: samplepod-2
    command: ["/bin/bash", "-c", "sleep 2000000000000"]
    image: centos
    securityContext:
      privileged: true
EOF
```


### Storing a configuration as a Custom Resource with SBR
```
cat <<EOF | kubectl create -f -
apiVersion: "k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: multus-template-2
spec:
  config: '{
    "cniVersion": "0.3.1",
    "name": "multus-template-2",
    "plugins": [
      {
        "type": "ipvlan",
        "master": "multus-1",
        "ipam": {
          "type": "host-local",
          "ranges": [
          [
            {
              "subnet": "192.168.104.0/24",
              "rangeStart": "192.168.104.20",
              "rangeEnd": "192.168.104.22",
              "gateway": "192.168.104.1"
            }
          ]
        ],
          "dns": {
            "nameservers" : ["10.46.82.129"]
          }
        }
      },
      {
        "type": "sbr"
      }
    ]
  }'
EOF
```

