# **common components**

## **Overview**

I use these components in my APIServer, two HttpServers and one TcpServer in a production environment, and of course all these servers are based on [OpenResty](https://github.com/openresty/openresty) or [lor](https://github.com/sumory/lor).

In order to reduce the duplication of work and facilitate the management of code, i integrated the common components in a single git repository which servers as a git submodule for all the servers mentioned above.

Because these components were coupled with my business layer code, so i had to decouple them and retest the decoupled components, and those tests were certainly not as good as that the online product went through, **so welcome to report me the issues and i will solve them as soon as possible**.

There are glance of these common components:

- [**app:**](https://github.com/tweyseo/Mirana/tree/master/app) more minimalist web framework that refer to [lor](https://github.com/sumory/lor).
- [**flowCtrl:**](https://github.com/tweyseo/Mirana/tree/master/flowCtrl) control the workflow of your code (parallel, parallelRace, parallelPro and so on).
- [**log:**](https://github.com/tweyseo/Mirana/tree/master/log) unify and standardize the log system.
- [**net:**](https://github.com/tweyseo/Mirana/tree/master/net) wrap a simple network communication (TCP, HTTP and so on).
- [**scheduler:**](https://github.com/tweyseo/Mirana/tree/master/scheduler) sidecar like, expected to be the unified scheduling layer for some common components (net, storage and so on).
- [**storage:**](https://github.com/tweyseo/Mirana/tree/master/storage) wrap a simple storage (redis, rediscluster and so on).
- [**toolkit:**](https://github.com/tweyseo/Mirana/tree/master/toolkit) common utils (auto require, dump table, json encode/decode an so on).
- [**wrapper:**](https://github.com/tweyseo/Mirana/tree/master/wrapper) wrapper for advanced features (tracer and so on).

> It's recommended to define your own public component directory structure like other components here (where both the **scheduler** and the **toolkit** are special).

## **Examples**

A simple [APIServer](https://github.com/tweyseo/Shredder) was served as an APIServer demo.

A simple [TCPServer](https://github.com/tweyseo/OgreMagi) was served as a TCPServer demo.

## **TODO**

1. more common components will be implemented later ([**app**](https://github.com/tweyseo/Mirana/tree/master/app) was in the plan).
2. performance optimization: follow [**performance guide**](http://wiki.luajit.org/Numerical-Computing-Performance-Guide) and avoid [**NYI**](http://wiki.luajit.org/NYI).

## **License**

[MIT](https://github.com/tweyseo/Mirana/blob/master/LICENSE)