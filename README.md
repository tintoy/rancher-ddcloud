# Rancher on CloudControl

Uses the [Docker Machine driver for CloudControl](https://github.com/DimensionDataResearch/docker-machine-driver-ddcloud) from within Rancher to create nodes.

Since Cattle does not work with IPv6, the orchestrator will have to be Kubernetes for now.

This is a work in progress - I'd stay away from it until it's a bit more complete, if I were you.
