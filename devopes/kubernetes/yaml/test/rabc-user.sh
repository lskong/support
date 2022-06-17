#!/bin/sh
cat > lucy-csr.json <<EOF
{
    "CN": "lucy",
    "hosts": [],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "Shanghai",
            "ST": "Shanghai"
        }
    ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca.config.json -profile=kubernetes lucy-csr.josn|cfssljson -bare lucy

kubectl config set-cluster kubectl \
  --certificate-authority=ca.pem \
  --embed-certs=true \
  --server=https://172.16.103.111:6433 \
  --kueconfig=mary-kubeconfig

  kubectl config set-credentials lucy \
    --client-key=mary-key.pem \
    --client-certificate=lucy.pem \
    --embed-certs=ture \
    --kubeconfig=lucy-kubeconfig

kubectl config set-context default \
  --cluster=kubernetes \
  --user=lucy \
  --kubeconfig=lucy-kubeconfig

kubectl config use-context default --kubeconfig=lucy-kubeconfig
