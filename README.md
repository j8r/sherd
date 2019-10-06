# Sherd

[![Build Status](https://cloud.drone.io/api/badges/j8r/sherd/status.svg)](https://cloud.drone.io/j8r/sherd)
[![Gitter](https://img.shields.io/badge/chat-on_gitter-red.svg?style=flat-square)](https://gitter.im/crystal-sherd/community)
[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

Crystal package manager, designed to be fast.

Experimental replacement to [shards](https://github.com/crystal-lang/shards)

The main purpose is to have faster dependencies resolution and download.

## Features

- Fast, and light in memory,  dependencies resolution 
- Concurrent download of packages
- Compatible with `shard.yml` and `shard.lock`

Several features arestill lacking compared to `shards`.

## Usage

Install locked dependencies:

`sherd install`

Build the first target:

`sherd build`

## Configuration

The configuration file is `sherd.ini` and the lock file is `sherd.lock`,
but `shards.yml` and `shards.lock` can still be used.

### Dependencies

By default, dependencies will be cloned in Git/SSH, then HTTPS, if nothing is specified in the URI.

`tag/` and `heads/` match the syntax of `git show`. The only exception is `commit:`, which is the commit hash revision.

`master` will be taken if nothing is specified.

```ini
[dependencies]
first = github.com/user/first >=4.0.3 || <4.4.0
dep = github.com/user/dep1 tags/prerelease
somelib = gitlab.com/user/somelib heads/dev
otherlib = bitbucket.com/user/otherlib commit:1a400f9c6440fbrcb093066f54959eg9fbde5659
```

## License

Copyright (c) 2019 Julien Reichardt - ISC License
