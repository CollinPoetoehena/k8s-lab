# k8s-lab

A personal Kubernetes laboratory for hands-on experimentation with advanced K8s concepts and a reusable platform for bootstrapping infrastructure in other projects.

## Purpose

This repo serves two goals:

1. **Learning** — Deep-dive into advanced Kubernetes topics (networking, scheduling, operators, RBAC, GitOps, observability, etc.) through practical experimentation.
2. **Reusable platform** — A ready-to-use K8s environment that other personal projects can depend on. Instead of setting up infrastructure from scratch each time, a project can point at this lab and get a working cluster with batteries included.

## What this provides

- A reproducible local/remote K8s cluster setup
- Core platform components (ingress, cert management, storage, monitoring, etc.) pre-configured
- A foundation to build on for any project that needs a K8s target environment

## Usage in other projects

Other projects can reference this lab to get their infra ready, then deploy their workloads on top of it without worrying about cluster setup or platform tooling.

## TODO: further make the details later, such as design, etc., this can be in /docs folder and then referenced below in this README.md as TOC
TODO: for reflection add learning goals of learning K8s, more about networking, infrastructure, etc.
