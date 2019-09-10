# Multus default route manipulation from within the POD 

This script was created to bypass the Multus limitation where default routes cannot be defined during Network CRD creation
Ideally this script can me mounted using a configMap with an Init Container. For testing purpose , you can run this script once the POD is created and depending on your privlege level



Example: 

### Storing a configuration as a Custom Resource

```
cat <<EOF | kubectl create -f -
apiVersion: "http://k8s.cni.cncf.io/v1"
kind: NetworkAttachmentDefinition
metadata:
  name: route-auto
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

Step 2:

Create a configMap using the multus-default-route.sh

kubectl create configmap wrapper --from-file=multus-default-route.sh

Step 3:
Create POD with an InitContainer which will mount you configMap and run your bash script 

```
cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  name: samplepod-9
  annotations:
    k8s.v1.cni.cncf.io/networks:  vudm-http2
spec:
  nodeName: worker-1.oc-test.cch-nam.nsn-rdnet.net
  initContainers:
  - name: samplepod
    command: ["/tmp/multus-default-route.sh"]
    volumeMounts:
    - name: wrapper
      mountPath: /tmp
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



