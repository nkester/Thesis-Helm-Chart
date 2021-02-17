# Analytic Environment as a Service  

AEaaS is a basic configuration of analytic resources intended to give analysts and simulation operators the tools needed to store and interact with data and leverage industry standard tools from within a full function integrated development environment. 

## Demo Limitations  

This demonstration deployment leverages each type of specified analytic building blocks (IDE, analytic tool, and Database Management System). It does not, however, provide the functionality to choose from my implementations of those ABBs. For instance, MySQL and Neo4J are not options for the DBMS.

## Introduction  

This chart bootstraps a [MongoDB](https://github.com/bitnami/bitnami-docker-mongodb) and [PostgreSQL](https://github.com/bitnami/bitnami-docker-postgresql) helm chart developed by bitnami.  These are combined with a custom built helm chart built to deploy an RStudio IDE service. This is based on a container originally built by the [rocker group](https://hub.docker.com/r/rocker/rstudio) and extended by Neil Kester. 

