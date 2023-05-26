# Lineblocs Helm Chart

This projects contains helm charts needed to deploy Lineblocs services.

## Description

This project provides a Helm chart for deploying Lineblocs services onto a Kubernetes cluster. Helm is a package manager
for Kubernetes that makes it easy to define, install, and manage applications as Helm charts.

## Table of Contents

- [Compatibility](#compatibility)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)

## Compatibility

| K8s version | is compatible |
|-------------|---------------|
| 1.27        | yes           |
| 1.26        | yes           |
| 1.25        | yes           |
| 1.24        | yes           |
| 1.23        | yes           |
| 1.22        | no            |
 
## Installation

To install the Helm chart, follow these steps:

1. Make sure you have Helm installed on your local machine and have configured it to connect to your Kubernetes cluster.

2. Clone this repository to your local machine.

   ```bash
   git clone https://github.com/Lineblocs/helm-chart.git
   ```

3. Change into the cloned directory.

   ```bash
   cd helm-chart
   ```

4. Go in `web` or `voip` charts folder.

5. Customize the chart's values in the `values.yaml` file according to your requirements.

6. Deploy the chart to your Kubernetes cluster using the following Helm command:

   ```bash
   helm install [release-name] .
   ```

   Replace `[release-name]` with the desired name for your release.

For more detailed instructions on installing and managing Helm charts, please refer to the [Helm documentation](https://helm.sh/docs/).

## Usage

**Lineblocs web and voip specific documentation if needed**

## Configuration

Web and voip charts are top level entity which contains subcharts of each service deployed. In the `charts` folder of web
and voip, there are all the services deployed. Each one uses `libs` charts (located at the root of this project) as base.

Here is the content of web chart folder :
```
├── Chart.lock # contains precise information about what version of dependencies have been used
├── charts # contains every subcharts
│ ├── app
│ │ ├── Chart.yaml
│ │ ├── .helmignore
│ │ └── templates
│ │     └── include.yaml # include defined template in libs
│ ├── com
│ │ ├── Chart.yaml
│ │ ├── .helmignore
│ │ └── templates
│ │     └── include.yaml
│ ├── editor
│ │ ├── Chart.yaml
│ │ ├── .helmignore
│ │ └── templates
│ │     └── include.yaml
│ ├── internals
│ │ ├── Chart.yaml
│ │ ├── .helmignore
│ │ └── templates
│ │     └── include.yaml
│ ├── libs -> ../../libs # simlink to libs chart
│ ├── phpmyadmin
│ │ ├── Chart.yaml
│ │ ├── .helmignore
│ │ └── templates
│ │     └── include.yaml
│ ├── routeeditor
│ │ ├── Chart.yaml
│ │ ├── .helmignore
│ │ └── templates
│ │     └── include.yaml
│ └── tsbindings
│     ├── Chart.yaml
│     ├── .helmignore
│     └── templates
│         └── include.yaml
├── Chart.yaml # generic information about this chart and dependencies
├── .helmignore
├── templates
│ ├── _helpers.tpl # some defined templates to help 
│ ├── ingress-demo.yaml
│ ├── init-db-configmap.yaml
│ └── NOTES.txt # displayed information when installing the chart
└── values.yaml # default values
```

Here is an example for com service in web chart:
```yaml
  containers:
    - name: site
      image: lineblocs/site:master
      imagePullPolicy: Always
      ports:
        - containerPort: 8080
      livenessProbe:
        httpGet:
          path: /healthz
          port: 8080
          httpHeaders:
            - name: X-Healthz
              value: health
        initialDelaySeconds: 3
        periodSeconds: 3
      resources:
        requests:
          cpu: "64m"
          memory: "32Mi"
        limits:
          cpu: "4096m"
          memory: "16384Mi"
  domain: com.
  envs:
    secrets:
      - db-secret
    configs:
      DEPLOYMENT_DOMAIN: lineblocs-test.com
      DB_OPENSIPS_DATABASE: CONFIGURED_OPENSIPS_DATABASE
  service:
    ports:
      - port: 80
        targetPort: 8080
```

In web chart, you would write : 
```yaml
com:
  # config written above
```

For more detailed information on the available configuration options, please refer to the `values.yaml` file inside
web and voip charts.

If you need to declare variation for a specific cloud provider, you can create a new values file (`values-gcp.yaml` for example).
It will inherit `values.yaml` so you will be able to only override what you want.

### Adding a new service

If you wish to add a new service to one of the charts, you can go in the `charts` folder and create a new subchart.
Normally, you can copy another subchart like `app` or `com` for `web` chart and modify chart name in `Chart.yaml`.
Then, reference it in `values.yaml`, like the others, so it has default values !
